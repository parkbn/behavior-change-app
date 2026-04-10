#!/usr/bin/env python3
"""
Bulk-provision legacy HEALTHFLEXX Medical users into the
behavior_change_app Supabase project so they can log in with a
password reset instead of going through the Sign-up flow.

What it does, per row in the legacy dump:
  1. Calls POST /auth/v1/admin/users with email + random password
     and email_confirm=true. That creates the auth.users row,
     which fires handle_new_user, which creates the persons row,
     which fires the set_resolved_id_default trigger, which
     auto-links external_id and resolved_id from legacy_user_map.
     (Run migrate_legacy_external_ids.sql FIRST so the map and
     trigger are in place.)
  2. Sends a password-reset email via POST /auth/v1/recover so
     the user can set their own password.

Idempotent: if a user already exists (HTTP 422 "already registered"
or 409), we skip step 1 and still send the reset email.

Usage:
  export SUPABASE_URL=https://xxx.supabase.co
  export SUPABASE_SERVICE_ROLE_KEY=eyJ...            # service role
  python bulk_provision_legacy_users.py legacy_users.json

  # dry run (no API calls):
  python bulk_provision_legacy_users.py --dry-run legacy_users.json

Requires: stdlib only. No `requests` dependency.
"""

from __future__ import annotations

import argparse
import json
import os
import secrets
import sys
import time
import urllib.error
import urllib.request
from typing import Any


def env(name: str) -> str:
    v = os.environ.get(name)
    if not v:
        sys.exit(f"error: {name} not set")
    return v


def post_json(url: str, headers: dict[str, str], body: dict[str, Any]) -> tuple[int, dict[str, Any]]:
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers={**headers, "Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.status, json.loads(resp.read().decode("utf-8") or "{}")
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        try:
            parsed = json.loads(body)
        except json.JSONDecodeError:
            parsed = {"raw": body}
        return e.code, parsed


def create_user(base: str, service_key: str, email: str) -> tuple[bool, str]:
    """Returns (created, message). created=False means already existed (still OK)."""
    url = f"{base}/auth/v1/admin/users"
    headers = {"apikey": service_key, "Authorization": f"Bearer {service_key}"}
    body = {
        "email": email,
        "password": secrets.token_urlsafe(24),  # random; user will reset
        "email_confirm": True,
    }
    status, resp = post_json(url, headers, body)
    if 200 <= status < 300:
        return True, "created"
    msg = resp.get("msg") or resp.get("error") or resp.get("error_description") or str(resp)
    # Supabase returns 422 with "already registered" if the email exists
    if status in (409, 422) and "already" in msg.lower():
        return False, "already exists"
    return False, f"HTTP {status}: {msg}"


def send_reset(base: str, service_key: str, email: str) -> tuple[bool, str]:
    url = f"{base}/auth/v1/recover"
    headers = {"apikey": service_key, "Authorization": f"Bearer {service_key}"}
    status, resp = post_json(url, headers, {"email": email})
    if 200 <= status < 300:
        return True, "reset sent"
    msg = resp.get("msg") or resp.get("error") or str(resp)
    return False, f"HTTP {status}: {msg}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("dump", help="Path to the legacy users JSON array")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--skip-reset", action="store_true", help="Create users but don't send reset emails")
    ap.add_argument("--sleep", type=float, default=0.2, help="Seconds between API calls")
    args = ap.parse_args()

    with open(args.dump, encoding="utf-8") as f:
        users = json.load(f)

    if not isinstance(users, list):
        sys.exit("error: dump must be a JSON array")

    print(f"Loaded {len(users)} legacy users from {args.dump}")

    if args.dry_run:
        for u in users:
            print(f"  would provision: {u.get('email')}  (externalId={u.get('externalId')})")
        return 0

    base = env("SUPABASE_URL").rstrip("/")
    key = env("SUPABASE_SERVICE_ROLE_KEY")

    created = existed = failed = reset_sent = 0

    for i, u in enumerate(users, 1):
        email = (u.get("email") or "").strip().lower()
        if not email:
            print(f"[{i}/{len(users)}] SKIP: no email in record")
            continue

        ok, msg = create_user(base, key, email)
        if ok:
            created += 1
            status = "created"
        elif msg == "already exists":
            existed += 1
            status = "exists"
        else:
            failed += 1
            print(f"[{i}/{len(users)}] {email}: FAIL {msg}")
            continue

        if not args.skip_reset:
            ok, msg = send_reset(base, key, email)
            if ok:
                reset_sent += 1
                status += ", reset emailed"
            else:
                print(f"[{i}/{len(users)}] {email}: reset failed — {msg}")

        print(f"[{i}/{len(users)}] {email}: {status}")
        time.sleep(args.sleep)

    print()
    print(f"Summary: created={created}  already_existed={existed}  failed={failed}  reset_emails={reset_sent}")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
