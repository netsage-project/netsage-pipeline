#!/usr/bin/env python3
"""
check_communities.py — Enrich community JSON files with missing IPv4/IPv6
prefixes using RIPEstat, and flag existing entries that look stale.

Two modes:

1. Default mode (one ASN per org, varied ASNs across file):
   For each entry, queries RIPEstat's announced-prefixes API for the org's
   ASN and adds/flags prefixes as before.

2. Shared-ASN mode (--shared-asn, e.g. AARnet/AS7575 where every org_name
   shares the same ASN):
   The announced-prefixes endpoint can't tell which prefixes belong to which
   org under a shared ASN, so this mode instead uses the RIPE DB REST search
   (https://rest.db.ripe.net/search.json) to find inetnum/inet6num objects
   whose descr/netname/org fields fuzzy-match the entry's org_name, and adds
   any newly-discovered subnets for that org that aren't already covered by
   an existing prefix. Existing prefixes are NOT removed/flagged as stale in
   this mode, since the shared-ASN announced list can't validate per-org
   prefixes.

Output ordering: IPv4 addresses first, then IPv6 addresses, each block
sorted naturally.

Usage:
    python3 check_communities.py [--input FILE] [--output FILE] [--delay SECS]
    python3 check_communities.py --shared-asn [--input FILE] [--output FILE] [--delay SECS]

Options:
    --input      FILE    Input JSON file  (default: community-LEARN.json)
    --output     FILE    Output JSON file (omit to dry-run; no write occurs
                         unless --output is given)
    --delay      SECS    Seconds between API calls (default: 0.5)
    --shared-asn         All entries share one ASN; use per-org RIPE DB name
                         search instead of AS-level announced-prefixes
    --threshold  FLOAT   Fuzzy-match threshold (0-1) for org name matching
                         in --shared-asn mode (default: 0.8)

APIs used (no auth required):
    RIPEstat announced-prefixes:
        https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS{asn}
    RIPE DB REST search (shared-asn mode):
        https://rest.db.ripe.net/search.json?query-string={org}&type-filter=inetnum,inet6num
"""

from __future__ import annotations

import argparse
import difflib
import ipaddress
import json
import re
import socket
import sys
import time
import urllib.parse
import urllib.request
import urllib.error
from pathlib import Path


# ---------------------------------------------------------------------------
# RIPEstat / RIPE DB backends
# ---------------------------------------------------------------------------

def fetch_ripestat(asn: str, retries: int = 3, timeout: int = 40) -> list[str]:
    """Return list of all CIDR prefixes (v4 and v6) announced by *asn*.

    Retries up to *retries* times on timeout/transient errors, with a short
    backoff between attempts.
    """
    url = f"https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS{asn}"
    last_err = None
    for attempt in range(1, retries + 1):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "check_communities/1.0"})
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                data = json.load(resp)
            prefixes = []
            for p in data.get("data", {}).get("prefixes", []):
                cidr = p.get("prefix", "")
                if cidr:
                    prefixes.append(cidr)
            return prefixes
        except urllib.error.HTTPError as exc:
            last_err = f"HTTP {exc.code}"
            break
        except Exception as exc:
            last_err = str(exc)
            if attempt < retries:
                print(f"  [retry {attempt}/{retries - 1}] AS{asn}: {last_err}", file=sys.stderr)
                time.sleep(2 * attempt)
            continue

    print(f"  [WARN] RIPEstat error for AS{asn}: {last_err}", file=sys.stderr)
    return []


def inetnum_range_to_cidr(rng: str) -> str | None:
    """Convert a RIPE 'inetnum' range string ('a.b.c.d - e.f.g.h') to a CIDR,
    if it represents an exact power-of-two block. Returns None otherwise."""
    rng = rng.strip()
    if "-" not in rng:
        try:
            ipaddress.ip_network(rng, strict=False)
            return rng
        except ValueError:
            return None
    start_s, end_s = (p.strip() for p in rng.split("-", 1))
    try:
        start = ipaddress.ip_address(start_s)
        end = ipaddress.ip_address(end_s)
    except ValueError:
        return None
    try:
        nets = list(ipaddress.summarize_address_range(start, end))
    except Exception:
        return None
    if len(nets) == 1:
        return str(nets[0])
    return None


def fetch_ripedb_inetnums_by_org(org_handle: str, retries: int = 3, timeout: int = 40, debug: bool = False, db_source: str = "APNIC") -> list[dict]:
    """
    Query the whois-db REST search API for inetnum/inet6num objects whose
    'org:' attribute references *org_handle* (e.g. 'ORG-AB12-AP'). Returns a
    list of dicts: {"prefix": "1.2.3.0/24", "descr": "...", "netname": "...", "org": "..."}
    """
    host_map = {
        "APNIC": "rest.db.apnic.net",
        "RIPE": "rest.db.ripe.net",
        "ARIN": "rest.db.arin.net",
        "LACNIC": "rest.db.lacnic.net",
        "AFRINIC": "rest.db.afrinic.net",
    }
    host = host_map.get(db_source.upper(), "rest.db.apnic.net")

    params = urllib.parse.urlencode({
        "query-string": org_handle,
        "inverse-attribute": "org",
        "type-filter": "inetnum,inet6num",
        "source": db_source,
    })
    url = f"https://{host}/search.json?{params}"
    last_err = None
    for attempt in range(1, retries + 1):
        try:
            req = urllib.request.Request(
                url,
                headers={"User-Agent": "check_communities/1.0", "Accept": "application/json"},
            )
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                data = json.load(resp)
            if debug:
                print(f"\n  [DEBUG] inetnum search '{org_handle}' -> {url}", file=sys.stderr)
                print(json.dumps(data, indent=2)[:3000], file=sys.stderr)
            results = []
            objects = data.get("objects", {}).get("object", [])
            for obj in objects:
                obj_type = obj.get("type")
                if obj_type not in ("inetnum", "inet6num"):
                    continue
                attrs = obj.get("attributes", {}).get("attribute", [])
                attr_map: dict[str, list[str]] = {}
                for a in attrs:
                    attr_map.setdefault(a.get("name", ""), []).append(a.get("value", ""))

                if obj_type == "inetnum":
                    rng = attr_map.get("inetnum", [None])[0]
                    prefix = inetnum_range_to_cidr(rng) if rng else None
                else:
                    prefix = attr_map.get("inet6num", [None])[0]

                if not prefix:
                    continue

                results.append({
                    "prefix": prefix,
                    "descr": " ".join(attr_map.get("descr", [])),
                    "netname": " ".join(attr_map.get("netname", [])),
                    "org": " ".join(attr_map.get("org", [])),
                })
            return results
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                if debug:
                    print(f"\n  [DEBUG] inetnum search '{org_handle}' -> {url}: HTTP 404 (no matches)", file=sys.stderr)
                return []
            try:
                body = exc.read().decode("utf-8", "replace")[:300]
            except Exception:
                body = ""
            last_err = f"HTTP {exc.code} {body}"
            break
        except Exception as exc:
            last_err = str(exc)
            if attempt < retries:
                print(f"  [retry {attempt}/{retries - 1}] inetnum search '{org_handle}': {last_err}", file=sys.stderr)
                time.sleep(2 * attempt)
            continue

    if last_err:
        print(f"  [WARN] RIPE DB inetnum search error for '{org_handle}': {last_err}", file=sys.stderr)
    return []


WHOIS_HOSTS = {
    "APNIC": "whois.apnic.net",
    "RIPE": "whois.ripe.net",
    "ARIN": "rwhois.arin.net",
    "LACNIC": "whois.lacnic.net",
    "AFRINIC": "whois.afrinic.net",
    "JPNIC": "whois.nic.ad.jp",
}

# RIR sources that use the two-step org-handle -> inetnum model
_TWO_STEP_SOURCES = {"APNIC", "RIPE", "LACNIC", "AFRINIC"}


def _whois_query(host: str, query: str, timeout: int = 40, retries: int = 3) -> str:
    """Send a raw query to a WHOIS server on port 43 and return the full
    text response."""
    last_err = None
    for attempt in range(1, retries + 1):
        try:
            with socket.create_connection((host, 43), timeout=timeout) as sock:
                sock.sendall((query + "\r\n").encode("utf-8"))
                chunks = []
                while True:
                    chunk = sock.recv(8192)
                    if not chunk:
                        break
                    chunks.append(chunk)
            return b"".join(chunks).decode("utf-8", "replace")
        except Exception as exc:
            last_err = str(exc)
            if attempt < retries:
                time.sleep(2 * attempt)
            continue
    raise RuntimeError(last_err or "whois query failed")


def _check_whois_errors(text: str, host: str) -> None:
    """Print any notable error lines from a whois response to stderr.
    Raises SystemExit on rate-limit/access-denied errors."""
    for line in text.splitlines():
        if line.startswith("%ERROR") or "access denied" in line.lower() or "daily limit" in line.lower():
            msg = line.lstrip("%").strip()
            print(f"  [WARN] {host}: {msg}", file=sys.stderr)
            if "access denied" in line.lower() or "daily limit" in line.lower():
                sys.exit(f"\n[FATAL] {host} rate limit hit — try again later.")


def _parse_whois_objects(text: str) -> list[dict]:
    """Parse a raw WHOIS response into a list of objects, each a dict
    mapping attribute name -> list of values.
    Objects are separated by blank lines."""
    objects: list[dict] = []
    current: dict[str, list[str]] = {}
    for line in text.splitlines():
        if line.startswith("%") or line.startswith("#"):
            continue
        if not line.strip():
            if current:
                objects.append(current)
                current = {}
            continue
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        key = key.strip().lower()
        value = value.strip()
        current.setdefault(key, []).append(value)
    if current:
        objects.append(current)
    return objects



    """Parse a raw WHOIS response into a list of objects, each a dict
    mapping attribute name -> list of values, in the order encountered.
    Objects are separated by blank lines."""
    objects: list[dict] = []
    current: dict[str, list[str]] = {}
    for line in text.splitlines():
        if line.startswith("%") or line.startswith("#"):
            continue
        if not line.strip():
            if current:
                objects.append(current)
                current = {}
            continue
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        key = key.strip().lower()
        value = value.strip()
        current.setdefault(key, []).append(value)
    if current:
        objects.append(current)
    return objects


def fetch_whois_jpnic(query: str, retries: int = 3, timeout: int = 40, debug: bool = False) -> list[dict]:
    """
    JPNIC-specific whois search. JPNIC doesn't use organisation objects or
    org: back-references. Instead, searching by org name with /e (English)
    returns inetnum objects directly whose org-name/descr matches.
    Query format: '<org name>/e' for English results.
    Returns a list of dicts: {"prefix": ..., "descr": ..., "netname": ..., "org": ""}
    """
    host = WHOIS_HOSTS["JPNIC"]
    q = f"{query}/e"
    try:
        text = _whois_query(host, q, timeout=timeout, retries=retries)
    except RuntimeError as exc:
        print(f"  [WARN] JPNIC whois error for '{query}': {exc}", file=sys.stderr)
        return []

    if debug:
        print(f"\n  [DEBUG] JPNIC whois '{query}' (query: {q!r}):", file=sys.stderr)
        print(text[:3000], file=sys.stderr)

    _check_whois_errors(text, host)
    results = []
    for obj in _parse_whois_objects(text):
        prefix = None
        if "inetnum" in obj:
            prefix = inetnum_range_to_cidr(obj["inetnum"][0])
        elif "inet6num" in obj:
            prefix = obj["inet6num"][0]
        if not prefix:
            continue
        results.append({
            "prefix": prefix,
            "descr": " ".join(obj.get("descr", [])),
            "netname": " ".join(obj.get("netname", [])),
            "org": " ".join(obj.get("org-name", obj.get("org", []))),
        })
    return results


def fetch_whois_org_handles(query: str, retries: int = 3, timeout: int = 40, debug: bool = False, db_source: str = "APNIC") -> list[dict]:
    """
    Use the WHOIS protocol's full-text/inverse search to find 'organisation'
    objects whose org-name matches *query*. Returns a list of dicts:
        {"key": <org handle>, "name": <org-name>}
    """
    host = WHOIS_HOSTS.get(db_source.upper(), WHOIS_HOSTS["APNIC"])
    # APNIC supports -T organisation for type-filtered full-text search.
    # RIPE and others: plain full-text query, then filter organisation objects
    # from parsed results (adding -T organisation on RIPE causes exact-key
    # matching only, missing most orgs).
    if db_source.upper() == "APNIC":
        q = f"-T organisation {query}"
    else:
        q = query
    try:
        text = _whois_query(host, q, timeout=timeout, retries=retries)
    except RuntimeError as exc:
        print(f"  [WARN] WHOIS org search error for '{query}': {exc}", file=sys.stderr)
        return []

    if debug:
        print(f"\n  [DEBUG] whois org search '{query}' ({host}, query: {q!r}):", file=sys.stderr)
        print(text[:3000], file=sys.stderr)

    _check_whois_errors(text, host)
    results = []
    for obj in _parse_whois_objects(text):
        if "organisation" not in obj:
            continue
        handle = obj["organisation"][0]
        name = " ".join(obj.get("org-name", []))
        if handle and name:
            results.append({"key": handle, "name": name})
    return results


def fetch_whois_inetnums_by_org(org_handle: str, retries: int = 3, timeout: int = 40, debug: bool = False, db_source: str = "APNIC") -> list[dict]:
    """
    Use the WHOIS protocol's inverse search to find inetnum/inet6num objects
    whose 'org:' attribute references *org_handle*. Returns a list of dicts:
        {"prefix": "1.2.3.0/24", "descr": "...", "netname": "...", "org": "..."}
    """
    host = WHOIS_HOSTS.get(db_source.upper(), WHOIS_HOSTS["APNIC"])
    q = f"-i org {org_handle}"
    try:
        text = _whois_query(host, q, timeout=timeout, retries=retries)
    except RuntimeError as exc:
        print(f"  [WARN] WHOIS inetnum search error for '{org_handle}': {exc}", file=sys.stderr)
        return []

    if debug:
        print(f"\n  [DEBUG] whois inetnum search '{org_handle}' ({host}, query: {q!r}):", file=sys.stderr)
        print(text[:3000], file=sys.stderr)

    _check_whois_errors(text, host)
    results = []
    for obj in _parse_whois_objects(text):
        prefix = None
        if "inetnum" in obj:
            prefix = inetnum_range_to_cidr(obj["inetnum"][0])
        elif "inet6num" in obj:
            prefix = obj["inet6num"][0]
        if not prefix:
            continue
        results.append({
            "prefix": prefix,
            "descr": " ".join(obj.get("descr", [])),
            "netname": " ".join(obj.get("netname", [])),
            "org": " ".join(obj.get("org", [])),
        })
    return results

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


def dedup_addresses(addresses: list[str]) -> list[str]:
    """Remove any prefix covered by a broader prefix in the same list,
    keeping only the most specific supernets (no redundant subnets)."""
    parsed = [(parse_net(a), a) for a in addresses]
    parsed = [(n, a) for n, a in parsed if n is not None]
    kept = []
    for net, addr in parsed:
        if any(
            other is not net
            and other.version == net.version
            and net != other
            and net.subnet_of(other)
            for other, _ in parsed
        ):
            continue
        kept.append(addr)
    return kept
def reorder_addresses(addresses: list[str]) -> list[str]:
    """Return addresses with all IPv4 entries first, then IPv6, each sorted,
    with any subnet that is covered by a broader prefix in the list removed."""
    addresses = dedup_addresses(addresses)
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




_NORMALIZE_RE = re.compile(r"[^a-z0-9]+")

_COMMON_SUFFIXES = (
    "limited", "ltd", "llc", "inc", "incorporated",
    "university", "of technology", "institute of technology",
    "the council of the", "the",
)


def normalize_org_name(name: str) -> str:
    """Lowercase, strip punctuation/whitespace, drop common trailing
    legal/org suffixes/prefixes for fuzzy comparison of org names."""
    name = name.lower()
    name = _NORMALIZE_RE.sub(" ", name).strip()
    for suffix in _COMMON_SUFFIXES:
        if name.endswith(suffix):
            name = name[: -len(suffix)].strip()
        if name.startswith(suffix + " "):
            name = name[len(suffix):].strip()
    return name


def org_name_similarity(a: str, b: str) -> float:
    """Fuzzy similarity ratio between two org names (0-1)."""
    na, nb = normalize_org_name(a), normalize_org_name(b)
    if not na or not nb:
        return 0.0
    if na == nb:
        return 1.0
    if na in nb or nb in na:
        return 0.9
    return difflib.SequenceMatcher(None, na, nb).ratio()


def best_match_score(org_name: str, candidate_fields: list[str]) -> float:
    """Return the best similarity score between org_name and any of the
    candidate text fields (descr, netname, org), checking each field as a
    whole and split into comma/slash-separated chunks."""
    best = 0.0
    for field in candidate_fields:
        if not field:
            continue
        chunks = re.split(r"[,/;]| - ", field)
        for chunk in [field] + chunks:
            score = org_name_similarity(org_name, chunk)
            if score > best:
                best = score
    return best


# ---------------------------------------------------------------------------
# Shared-ASN enrichment (per-org RIPE DB search)
# ---------------------------------------------------------------------------

def enrich_shared_asn(records: list[dict], delay: float, threshold: float, debug: bool = False, db_source: str = "APNIC") -> dict:
    """
    For files where every record shares one ASN (e.g. AARnet/AS7575), the
    AS-level announced-prefixes list can't be attributed to individual orgs.

    For each org_name:
      1. Use RIPEstat's searchcomplete API to find matching 'organisation'
         handles (e.g. ORG-ANU2-AP), fuzzy-matching the candidate org's
         display name against org_name.
      2. For each sufficiently-similar org handle, look up inetnum/inet6num
         objects in the RIPE DB whose 'org:' attribute references that
         handle.
      3. Add any newly-found prefixes not already covered by an existing
         prefix for that record.

    No prefixes are removed/flagged as stale in this mode.
    """
    added_count = 0
    changed_orgs: list[str] = []
    matched_detail = []   # (org_name, new_prefix, matched_org_display, score)
    skipped_covered = []  # (org_name, prefix, covering_prefix)
    no_match = []          # org_name with no matching org handle found

    total = len(records)
    print(f"Searching {db_source} whois for {total} org(s) …\n")

    for idx, record in enumerate(records, 1):
        org_name = record["org_name"]
        existing_addrs = record.get("addresses", [])
        existing_nets = [n for n in (parse_net(a) for a in existing_addrs) if n is not None]
        existing_set = set(existing_addrs)

        print(f"  [{idx:>3}/{total}] {org_name[:50]:<50}", end=" ", flush=True)

        new_prefixes = []

        if db_source.upper() == "JPNIC":
            # JPNIC: single-step — search returns inetnums directly by name
            results = fetch_whois_jpnic(org_name, debug=debug)
            for res in results:
                score = best_match_score(org_name, [res["descr"], res["netname"], res["org"]])
                if score < threshold:
                    continue
                prefix = res["prefix"]
                if prefix in existing_set:
                    continue
                net = parse_net(prefix)
                if net is None:
                    continue
                if is_covered(prefix, existing_nets):
                    cand_net = net
                    covering = next(
                        (str(n) for n in existing_nets
                         if n.version == cand_net.version
                         and (cand_net.subnet_of(n) or cand_net == n)),
                        "?"
                    )
                    skipped_covered.append((org_name, prefix, covering))
                    continue
                new_prefixes.append(prefix)
                existing_nets.append(net)
                existing_set.add(prefix)
                matched_detail.append((org_name, prefix, res["descr"] or res["netname"], score))
            if not results:
                no_match.append(org_name)
        else:
            # Two-step: org-handle lookup then inetnum reverse search
            org_candidates = fetch_whois_org_handles(org_name, debug=debug, db_source=db_source)
            matched_orgs = []
            for cand in org_candidates:
                score = org_name_similarity(org_name, cand["name"])
                if score >= threshold:
                    matched_orgs.append((cand["key"], cand["name"], score))

            if not matched_orgs:
                reordered = reorder_addresses(existing_addrs) if existing_addrs else existing_addrs
                if reordered != existing_addrs:
                    record["addresses"] = reordered
                print("→ no matching org found" if org_candidates else "→ no search results")
                no_match.append(org_name)
                if idx < total:
                    time.sleep(delay)
                continue

            for org_handle, org_display, score in matched_orgs:
                results = fetch_whois_inetnums_by_org(org_handle, debug=debug, db_source=db_source)
                for res in results:
                    prefix = res["prefix"]
                    if prefix in existing_set:
                        continue
                    net = parse_net(prefix)
                    if net is None:
                        continue
                    if is_covered(prefix, existing_nets):
                        cand_net = net
                        covering = next(
                            (str(n) for n in existing_nets
                             if n.version == cand_net.version
                             and (cand_net.subnet_of(n) or cand_net == n)),
                            "?"
                        )
                        skipped_covered.append((org_name, prefix, covering))
                        continue
                    new_prefixes.append(prefix)
                    existing_nets.append(net)
                    existing_set.add(prefix)
                    matched_detail.append((org_name, prefix, org_display, score))

        if new_prefixes:
            combined = existing_addrs + new_prefixes
            record["addresses"] = reorder_addresses(combined)
            added_count += len(new_prefixes)
            if org_name not in changed_orgs:
                changed_orgs.append(org_name)
            print(f"→ +{len(new_prefixes)} prefix(es)")
        else:
            reordered = reorder_addresses(existing_addrs) if existing_addrs else existing_addrs
            if reordered != existing_addrs:
                record["addresses"] = reordered
            print("→ no new prefixes")

        if idx < total:
            time.sleep(delay)

    return {
        "orgs_searched": total,
        "prefixes_added": added_count,
        "orgs_updated": len(changed_orgs),
        "updated_org_names": changed_orgs,
        "matched_detail": matched_detail,
        "skipped_covered": skipped_covered,
        "no_match": no_match,
        "records": records,
    }


# ---------------------------------------------------------------------------
# Default (per-ASN) enrichment
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

        removed_stale = False
        if announced_nets:
            kept_addrs = []
            for addr in existing_addrs:
                net = parse_net(addr)
                if net is not None and net.version == 4 and not is_covered(addr, announced_nets):
                    stale_v4.append((record["org_name"], asn, addr))
                    removed_stale = True
                    continue
                kept_addrs.append(addr)
            existing_addrs = kept_addrs
            existing_nets = [n for n in (parse_net(a) for a in existing_addrs) if n is not None]
            existing_set = set(existing_addrs)

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

        if new_prefixes or removed_stale:
            combined = existing_addrs + new_prefixes
            record["addresses"] = reorder_addresses(combined)
            added_count += len(new_prefixes)
            if record["org_name"] not in changed_orgs:
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

    missing_asn_set = {asn for asn, _ in missing_named}
    kept_records = [r for r in records if r["asn"] not in missing_asn_set]

    return {
        "asns_queried": total,
        "prefixes_added": added_count,
        "orgs_updated": len(changed_orgs),
        "updated_org_names": changed_orgs,
        "skipped_covered": skipped_covered,
        "stale_v4": stale_v4,
        "missing_asns": missing_named,
        "records": kept_records,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--input",   default="community-LEARN.json",
                        help="Input JSON file (default: community-LEARN.json)")
    parser.add_argument("--output",  default=None,
                        help="Output JSON file. If omitted, runs as a dry run "
                             "(no file written).")
    parser.add_argument("--delay",   type=float, default=0.5,
                        help="Seconds between API requests (default: 0.5)")
    parser.add_argument("--verbose", action="store_true",
                        help="Print extra detail, e.g. skipped-covered prefixes")
    parser.add_argument("--shared-asn", dest="shared_asn", action="store_true", default=None,
                        help="Force shared-ASN mode (per-org WHOIS name search) "
                             "instead of AS-level announced-prefixes. If omitted, "
                             "this is auto-detected: shared-ASN mode is used if "
                             "any ASN repeats across records, otherwise per-ASN "
                             "(ripestat) mode is used.")
    parser.add_argument("--no-shared-asn", dest="shared_asn", action="store_false",
                        help="Force per-ASN (ripestat) mode even if ASNs repeat.")
    parser.add_argument("--threshold", type=float, default=0.8,
                        help="Fuzzy org-name match threshold 0-1 for "
                             "shared-asn mode (default: 0.8)")
    parser.add_argument("--debug", action="store_true",
                        help="Print raw WHOIS/RIPEstat responses for debugging")
    parser.add_argument("--db-source", default=None,
                        help="RIR whois database to query in shared-asn mode: "
                             "APNIC, RIPE, ARIN, LACNIC, AFRINIC, JPNIC. "
                             "JPNIC uses a single-step name search (for Japanese "
                             "networks like SINET/AS2907). If omitted, defaults "
                             "to APNIC when shared-asn mode is used, or RIPE "
                             "when ASNs are all unique (per-ASN mode).")
    args = parser.parse_args()

    input_path  = Path(args.input)
    dry_run = args.output is None
    output_path = Path(args.output) if args.output else input_path

    if not input_path.exists():
        sys.exit(f"Input file not found: {input_path}")

    with input_path.open() as fh:
        records = json.load(fh)

    if not isinstance(records, list):
        sys.exit("Expected a JSON array at the top level.")

    asns = [r.get("asn") for r in records if "asn" in r]
    asns_all_unique = len(asns) == len(set(asns))

    if args.shared_asn is None:
        shared_asn = not asns_all_unique
    else:
        shared_asn = args.shared_asn

    if args.db_source is not None:
        db_source = args.db_source
    elif shared_asn:
        db_source = "APNIC"
    else:
        db_source = "RIPE"

    mode = "shared-asn (per-org WHOIS search)" if shared_asn else "ripestat (per-ASN)"
    print(f"Mode   : {mode}  (auto-detected: {'no' if args.shared_asn is not None else 'yes'})")
    print(f"Source : {db_source}")
    print(f"Input  : {input_path}")
    print(f"Output : {output_path}  {'(dry-run — no write)' if dry_run else ''}")
    print(f"Delay  : {args.delay}s between requests\n")

    if shared_asn:
        summary = enrich_shared_asn(records, args.delay, args.threshold, debug=args.debug, db_source=db_source)

        print("\n─── Summary ──────────────────────────────────────")
        print(f"  Orgs searched  : {summary['orgs_searched']}")
        print(f"  Prefixes added : {summary['prefixes_added']}")
        print(f"  Orgs updated   : {summary['orgs_updated']}")
        if summary["updated_org_names"]:
            print("  Updated orgs:")
            for name in summary["updated_org_names"]:
                print(f"    • {name}")

        if summary["matched_detail"]:
            print(f"\n  New prefixes found ({len(summary['matched_detail'])}):")
            for org, prefix, field, score in summary["matched_detail"]:
                field_short = (field[:60] + "…") if len(field) > 60 else field
                print(f"    • {org}: +{prefix}  (matched \"{field_short}\", score={score:.2f})")

        if args.verbose and summary["skipped_covered"]:
            print(f"\n  Skipped (already covered by an existing prefix): {len(summary['skipped_covered'])}")
            for org, prefix, covering in summary["skipped_covered"]:
                print(f"    • {org}: {prefix} ⊂ {covering}")

        if summary["no_match"]:
            print(f"\n  No matching organisation found in RIPE DB ({len(summary['no_match'])}):")
            for org in summary["no_match"]:
                print(f"    • {org}")

        if dry_run:
            print("\n[dry-run] No file written.")
            return

        tmp_path = output_path.with_suffix(".tmp")
        with tmp_path.open("w") as fh:
            json.dump(summary["records"], fh, indent=2)
            fh.write("\n")
        tmp_path.replace(output_path)
        print(f"\nWrote {output_path}")
        return

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
        print(f"\n  ⚠️  WARNING: existing IPv4 prefixes NOT announced by their ASN — removing ({len(summary['stale_v4'])}):")
        for org, asn, prefix in summary["stale_v4"]:
            print(f"    • {org} (AS{asn}): {prefix}")

    print(f"\n  ASNs with NO announced prefixes — removing entries ({len(summary['missing_asns'])}):")
    for asn, name in summary["missing_asns"]:
        print(f"    AS{asn:<10} {name}")

    if dry_run:
        print("\n[dry-run] No file written.")
        return

    tmp_path = output_path.with_suffix(".tmp")
    with tmp_path.open("w") as fh:
        json.dump(summary["records"], fh, indent=2)
        fh.write("\n")
    tmp_path.replace(output_path)
    print(f"\nWrote {output_path}")


if __name__ == "__main__":
    main()

