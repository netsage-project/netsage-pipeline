#!/usr/bin/env python3
"""
check_communities.py — Enrich community JSON files with missing IPv4/IPv6
prefixes using RIPEstat, and flag existing entries that look stale.

For each entry in the JSON, queries RIPEstat's announced-prefixes API for
the org's ASN and:
  - adds any discovered prefixes (v4 or v6) that aren't already covered by
    an existing prefix (i.e. skips new prefixes that are subnets of one
    already present)
  - warns about any *existing* IPv4 prefixes in the file that the ASN does
    not currently appear to announce (possible stale/incorrect entries)

Output ordering: IPv4 addresses first, then IPv6 addresses, each block
sorted naturally.

Usage:
    python3 check_communities.py [--input FILE] [--output FILE] [--dry-run] [--delay SECS]

Options:
    --input   FILE    Input JSON file  (default: community-LEARN.json)
    --output  FILE    Output JSON file (default: overwrites input)
    --dry-run         Print what would change but don't write anything
    --delay   SECS    Seconds between API calls (default: 0.5)

API used (no auth required):
    RIPEstat: https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS{asn}
"""

from __future__ import annotations

import argparse
import ipaddress
import json
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path


# ---------------------------------------------------------------------------
# RIPEstat backend
# ---------------------------------------------------------------------------

def fetch_ripestat(asn: str) -> list[str]:
    """Return list of all CIDR prefixes (v4 and v6) announced by *asn*."""
    url = f"https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS{asn}"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "check_communities/1.0"})
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.load(resp)
    except urllib.error.HTTPError as exc:
        print(f"  [WARN] RIPEstat HTTP {exc.code} for AS{asn}", file=sys.stderr)
        return []
    except Exception as exc:
        print(f"  [WARN] RIPEstat error for AS{asn}: {exc}", file=sys.stderr)
        return []

    prefixes = []
    for p in data.get("data", {}).get("prefixes", []):
        cidr = p.get("prefix", "")
        if cidr:
            prefixes.append(cidr)
    return prefixes


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def parse_net(cidr: str):
    """Parse a CIDR string into an ip_network, or None if invalid."""
    try:
        return ipaddress.ip_network(cidr, strict=False)
    except ValueError:
        return None


def is_covered(candidate: str, existing_nets: list) -> bool:
    """
    Return True if *candidate* (a CIDR string) is the same as, or a subnet
    of, any network in *existing_nets* (a list of ip_network objects).
    """
    cand_net = parse_net(candidate)
    if cand_net is None:
        return False
    for net in existing_nets:
        if net.version != cand_net.version:
            continue
        if cand_net.subnet_of(net) or cand_net == net:
            return True
    return False


def reorder_addresses(addresses: list[str]) -> list[str]:
    """Return addresses with all IPv4 entries first, then IPv6, each sorted."""
    v4 = []
    v6 = []
    for addr in addresses:
        net = parse_net(addr)
        if net is None:
            (v6 if ":" in addr else v4).append(addr)
            continue
        (v6 if net.version == 6 else v4).append(addr)

    def sort_key(cidr: str):
        net = parse_net(cidr)
        if net is None:
            return (1, 999, b"")
        return (0, net.prefixlen, net.network_address.packed)

    v4.sort(key=sort_key)
    v6.sort(key=sort_key)
    return v4 + v6


# ---------------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------------

def enrich(records: list[dict], delay: float) -> dict:
    """
    Iterate over all records, query each unique ASN once, and:
      - add missing v4/v6 prefixes (skipping any covered by an existing one)
      - flag existing IPv4 prefixes not covered by anything RIPEstat reports
        for that ASN
    Returns a summary dict.
    """
    asn_to_prefixes: dict[str, list[str]] = {}
    unique_asns = sorted({r["asn"] for r in records}, key=lambda x: int(x))
    total = len(unique_asns)

    print(f"Querying {total} unique ASNs …\n")

    for idx, asn in enumerate(unique_asns, 1):
        print(f"  [{idx:>3}/{total}] AS{asn:<10}", end=" ", flush=True)
        found = fetch_ripestat(asn)
        asn_to_prefixes[asn] = found
        if found:
            v4_found = [p for p in found if ":" not in p]
            v6_found = [p for p in found if ":" in p]
            print(f"→ {len(v4_found)} IPv4, {len(v6_found)} IPv6 prefix(es)")
        else:
            print("→ no prefixes found")
        if idx < total:
            time.sleep(delay)

    added_count = 0
    skipped_covered = []   # (org_name, prefix, covering_prefix)
    changed_orgs: list[str] = []
    stale_v4 = []          # (org_name, asn, prefix)

    for record in records:
        asn = record["asn"]
        existing_addrs = record.get("addresses", [])
        existing_nets = [n for n in (parse_net(a) for a in existing_addrs) if n is not None]
        existing_set = set(existing_addrs)

        announced = asn_to_prefixes.get(asn, [])
        announced_nets = [n for n in (parse_net(p) for p in announced) if n is not None]

        # --- Flag stale existing IPv4 entries -----------------------------
        # An existing IPv4 prefix is "stale" if RIPEstat returned at least
        # one prefix for this ASN, but this prefix isn't covered by (or
        # equal to) any announced prefix.
        if announced_nets:
            for addr in existing_addrs:
                net = parse_net(addr)
                if net is None or net.version != 4:
                    continue
                if not is_covered(addr, announced_nets):
                    stale_v4.append((record["org_name"], asn, addr))

        # --- Add new prefixes (v4 + v6), broadest-first -------------------
        new_prefixes = []
        candidates = sorted(
            (p for p in announced if p not in existing_set),
            key=lambda p: (parse_net(p).prefixlen if parse_net(p) else 999)
        )
        for prefix in candidates:
            if is_covered(prefix, existing_nets):
                cand_net = parse_net(prefix)
                covering = next(
                    (str(n) for n in existing_nets
                     if n.version == cand_net.version
                     and (cand_net.subnet_of(n) or cand_net == n)),
                    "?"
                )
                skipped_covered.append((record["org_name"], prefix, covering))
                continue
            new_prefixes.append(prefix)
            cand_net = parse_net(prefix)
            if cand_net is not None:
                existing_nets.append(cand_net)

        if new_prefixes:
            combined = existing_addrs + new_prefixes
            record["addresses"] = reorder_addresses(combined)
            added_count += len(new_prefixes)
            changed_orgs.append(record["org_name"])
        elif existing_addrs:
            reordered = reorder_addresses(existing_addrs)
            if reordered != existing_addrs:
                record["addresses"] = reordered

    missing_named = [
        (asn, next((r["org_name"] for r in records if r["asn"] == asn), "?"))
        for asn in unique_asns
        if not asn_to_prefixes.get(asn)
    ]

    return {
        "asns_queried": total,
        "prefixes_added": added_count,
        "orgs_updated": len(changed_orgs),
        "updated_org_names": changed_orgs,
        "skipped_covered": skipped_covered,
        "stale_v4": stale_v4,
        "missing_asns": missing_named,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--input",   default="community-LEARN.json",
                        help="Input JSON file (default: community-LEARN.json)")
    parser.add_argument("--output",  default=None,
                        help="Output JSON file (default: overwrite input)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show what would change but don't write")
    parser.add_argument("--delay",   type=float, default=0.5,
                        help="Seconds between API requests (default: 0.5)")
    parser.add_argument("--verbose", action="store_true",
                        help="Print extra detail, e.g. skipped-covered prefixes")
    args = parser.parse_args()

    input_path  = Path(args.input)
    output_path = Path(args.output) if args.output else input_path

    if not input_path.exists():
        sys.exit(f"Input file not found: {input_path}")

    with input_path.open() as fh:
        records = json.load(fh)

    if not isinstance(records, list):
        sys.exit("Expected a JSON array at the top level.")

    print("Source : ripestat")
    print(f"Input  : {input_path}")
    print(f"Output : {output_path}  {'(dry-run — no write)' if args.dry_run else ''}")
    print(f"Delay  : {args.delay}s between requests\n")

    summary = enrich(records, args.delay)

    print("\n─── Summary ──────────────────────────────────────")
    print(f"  ASNs queried   : {summary['asns_queried']}")
    print(f"  Prefixes added : {summary['prefixes_added']}")
    print(f"  Orgs updated   : {summary['orgs_updated']}")
    if summary["updated_org_names"]:
        print("  Updated orgs:")
        for name in summary["updated_org_names"]:
            print(f"    • {name}")

    if args.verbose and summary["skipped_covered"]:
        print(f"\n  Skipped (already covered by an existing prefix): {len(summary['skipped_covered'])}")
        for org, prefix, covering in summary["skipped_covered"]:
            print(f"    • {org}: {prefix} ⊂ {covering}")

    if summary["stale_v4"]:
        print(f"\n  ⚠️  WARNING: existing IPv4 prefixes NOT announced by their ASN ({len(summary['stale_v4'])}):")
        for org, asn, prefix in summary["stale_v4"]:
            print(f"    • {org} (AS{asn}): {prefix}")

    print(f"\n  ASNs with NO announced prefixes ({len(summary['missing_asns'])}):")
    for asn, name in summary["missing_asns"]:
        print(f"    AS{asn:<10} {name}")

    if args.dry_run:
        print("\n[dry-run] No file written.")
        return

    tmp_path = output_path.with_suffix(".tmp")
    with tmp_path.open("w") as fh:
        json.dump(records, fh, indent=2)
        fh.write("\n")
    tmp_path.replace(output_path)
    print(f"\nWrote {output_path}")


if __name__ == "__main__":
    main()

