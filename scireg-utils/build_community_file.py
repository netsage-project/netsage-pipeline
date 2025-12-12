#!/usr/bin/env python3
"""
Build a community-*.json file from RIPEstat data and whois data.

This is useful for countries where most large universites use the same ASN.

Example:
    build_community_file.py --asn 7575 --community AARnet
    build_community_file.py --asn 2907 --community SINET

Note that this program works great for some ASN (eg: AARnet and SINET), but does not work
for most European ASNs, as they used the (now-defunct) IRR instead of whois for org_names.
Many other countries use a different AS for each universities (including the USA).

For now, the best way to generate community files for the EU NRENS is to upload PDFs
of web page captures from bgp.he.net

"""

import argparse
import json
import logging
import sys
import time
import ipaddress
from pathlib import Path
from typing import Dict, List, Set, Any, Optional

import requests

STAT_BASE = "https://stat.ripe.net/data"
SESSION = requests.Session()


def ripe_stat_request(
    dataset: str,
    resource: str,
    extra_params: Optional[Dict[str, Any]] = None,
    max_retries: int = 5,
    backoff_factor: float = 1.5,
    timeout: int = 15,
) -> Dict[str, Any]:
    """
    Perform a GET to RIPEstat with retries and logging.

    Retries on:
      - timeouts / connection errors
      - HTTP 429, 5xx

    Raises if all retries are exhausted.
    """
    url = f"{STAT_BASE}/{dataset}/data.json"
    params = {"resource": resource}
    if extra_params:
        params.update(extra_params)

    for attempt in range(1, max_retries + 1):
        try:
            logging.debug(
                "Requesting %s with params=%s (attempt %d/%d)",
                url, params, attempt, max_retries
            )
            resp = SESSION.get(url, params=params, timeout=timeout)

            # Retry on rate limit or server errors
            if resp.status_code in (429, 500, 502, 503, 504):
                logging.warning(
                    "RIPEstat returned %d for %s %s (attempt %d/%d)",
                    resp.status_code, dataset, resource, attempt, max_retries
                )
                if attempt == max_retries:
                    resp.raise_for_status()
            else:
                resp.raise_for_status()
                return resp.json()

        except (requests.exceptions.Timeout, requests.exceptions.ConnectionError) as e:
            logging.warning(
                "Network error talking to RIPEstat for %s %s: %s (attempt %d/%d)",
                dataset, resource, e, attempt, max_retries
            )
            if attempt == max_retries:
                raise

        # Only sleep if we are going to retry
        sleep_seconds = backoff_factor ** (attempt - 1)
        logging.info("Sleeping %.1f seconds before retrying %s %s", sleep_seconds, dataset, resource)
        time.sleep(sleep_seconds)

    # Should never reach here because of the raise above
    raise RuntimeError(f"Exhausted retries for RIPEstat dataset={dataset} resource={resource}")


def get_as_holder(asn: str) -> str:
    """
    Fetch the AS holder name (AS overview 'holder' field) from RIPEstat.
    """
    resource = f"AS{asn}"
    logging.info("Fetching AS overview for %s", resource)
    data = ripe_stat_request("as-overview", resource)
    holder = data.get("data", {}).get("holder")
    if not holder:
        holder = resource
    logging.info("AS %s holder: %s", asn, holder)
    return holder

def get_announced_prefixes(asn: str) -> List[str]:
    """
    Query RIPEstat for announced prefixes for the given ASN.

    Returns only:
      • IPv4 prefixes with mask <= 20  (i.e. larger than /20)
      • IPv6 prefixes with mask <= 48  (i.e. larger than /48)
    """
    logging.info("Fetching announced prefixes for AS%s from RIPEstat...", asn)
    data = ripe_stat_request("announced-prefixes", asn)
    result = data.get("data", {}).get("prefixes", [])
    #print (result)

    filtered = []
    for item in result:
        p = item.get("prefix")
        if not p:
            continue

        try:
            net = ipaddress.ip_network(p, strict=False)
        except Exception:
            logging.error ("Error getting address: %s", p)
            sys.exit()
            continue

        # IPv4: keep /0–/20
        logging.debug ("Checking subnet: %s", net)
        if isinstance(net, ipaddress.IPv4Network):
            if net.prefixlen <= 20:
                filtered.append(p)
                logging.debug ("adding subnet with prefix: %d", net.prefixlen)
            else:
                logging.debug ("skipping small subnet with prefix: %d", net.prefixlen)
            continue

        # IPv6: keep /0–/48
        if isinstance(net, ipaddress.IPv6Network):
            if net.prefixlen <= 48:
                filtered.append(p)

    logging.info(
        "RIPEstat returned %d prefixes for AS%s, %d kept after filtering",
        len(result), asn, len(filtered)
    )

    return filtered



def extract_org_name_from_whois_records(records: List[List[Dict[str, str]]]) -> Optional[str]:
    """
    Given RIPEstat WHOIS 'records', try to extract a useful organization name.

    We look for (in order):
      - org-name
      - organisation
      - descr
      - owner
    """
    preferred_keys = ["org-name", "organisation", "descr", "owner"]

    for key in preferred_keys:
        for record in records:
            for item in record:
                item_key = (item.get("key") or "").strip().lower()
                if item_key == key:
                    value = (item.get("value") or "").strip()
                    if value:
                        return value

    return None


def fetch_org_name_for_prefix(prefix: str, default_org: str) -> str:
    """
    Fetch org name for a given prefix via RIPEstat WHOIS.

    Falls back to default_org if no suitable org-name can be found.
    """
    logging.debug("Fetching WHOIS org-name for prefix %s", prefix)
    data = ripe_stat_request("whois", prefix)
    records = data.get("data", {}).get("records", [])

    org_name = extract_org_name_from_whois_records(records)
    if org_name:
        logging.debug("Found org-name '%s' for prefix %s", org_name, prefix)
        return org_name

    logging.debug(
        "No org-name found in WHOIS for %s; using default org '%s'",
        prefix, default_org
    )
    return default_org


def build_community_entries( asn: str, community: str,) -> List[Dict[str, Any]]:
    """
    Build the list of community entries (dicts) for the given ASN and community label.

    Each entry looks like:
      {
          "addresses": [ "x.x.x.x/yy", ... ],
          "org_name": "Some Org",
          "community": "<community>",
          "asn": "<asn>"
      }
    """
    as_holder = get_as_holder(asn)
    prefixes = get_announced_prefixes(asn)

    org_to_prefixes: Dict[str, Set[str]] = {}

    total = len(prefixes)
    if total == 0:
        logging.error("No prefixes found. Exiting")
        sys.exit()
    for idx, prefix in enumerate(prefixes, start=1):
        if idx == 1 or idx % 20 == 0 or idx == total:
            logging.info("Processing prefix %d/%d: %s", idx, total, prefix)

        try:
            org_name = fetch_org_name_for_prefix(prefix, default_org=as_holder)
        except Exception as e:
            logging.error("Failed to fetch org-name for prefix %s: %s; skipping", prefix, e)
            continue

        org_to_prefixes.setdefault(org_name, set()).add(prefix)

    logging.info("Grouped prefixes into %d organizations", len(org_to_prefixes))

    entries: List[Dict[str, Any]] = []
    for org_name in sorted(org_to_prefixes.keys()):
        addresses = sorted(org_to_prefixes[org_name])
        entry = {
            "addresses": addresses,
            "org_name": org_name,
            "community": community,
            "asn": asn,
        }
        entries.append(entry)

    logging.info("Built %d community entries", len(entries))
    return entries


def write_json(entries: List[Dict[str, Any]], output_path: Path) -> None:
    """
    Write entries to a JSON file.
    """
    logging.info("Writing %d entries to %s", len(entries), output_path)
    with output_path.open("w", encoding="utf-8") as f:
        json.dump(entries, f, indent=4, ensure_ascii=False)
    logging.info("Done writing %s", output_path)


def parse_args(argv: List[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate a community-*.json file from RIPEstat announced prefixes."
    )
    parser.add_argument(
        "--asn",
        required=True,
        help="AS number to query (e.g. 559). Do not include 'AS' prefix.",
    )
    parser.add_argument(
        "--community",
        required=True,
        help="Community label to store in the JSON (e.g. SWITCH).",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug logging.",
    )
    return parser.parse_args(argv)


def main(argv: List[str]) -> int:
    args = parse_args(argv)

    log_level = logging.DEBUG if args.debug else logging.INFO
    logging.basicConfig(
        level=log_level,
        format="[%(asctime)s] %(levelname)s: %(message)s",
    )

    asn = args.asn.strip()
    community = args.community.strip()
    # Always derive the output filename automatically based on the community
    output_path = Path(f"community-{community}.json")

    logging.info(
        "Starting community JSON build for AS%s, community '%s', output %s",
        asn, community, output_path
    )

    try:
        entries = build_community_entries(
            asn=asn,
            community=community,
        )
        write_json(entries, output_path)
    except Exception as e:
        logging.exception("Fatal error: %s", e)
        return 1

    logging.info("Completed successfully.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

