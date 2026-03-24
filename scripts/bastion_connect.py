#!/usr/bin/env python3
"""
Create an OCI Bastion port-forwarding session and print the SSH connection command.

Uses port forwarding instead of managed SSH — no Bastion plugin required on the
target instance.

Usage:
  python bastion_connect.py                     # Connect to POC instance (default)
  python bastion_connect.py --target dev        # Connect to Dev instance (hop via POC)
  python bastion_connect.py --ttl 1800          # Custom session TTL (seconds)
  python bastion_connect.py --key compute.pem   # Custom private key path
  python bastion_connect.py --local-port 2222   # Custom local port for tunnel

Requires: oci, subprocess (terraform must be on PATH)
"""

import argparse
import os
import stat
import subprocess
import sys
import time

import oci


def terraform_output(name):
    """Fetch a Terraform output value."""
    result = subprocess.run(
        ["terraform", "output", "-raw", name],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"ERROR: Failed to read terraform output '{name}': {result.stderr.strip()}")
        sys.exit(1)
    return result.stdout.strip()


def write_key_file(content, path):
    """Write key content to a file."""
    with open(path, "w", newline="\n") as f:
        f.write(content)
    try:
        os.chmod(path, stat.S_IRUSR | stat.S_IWUSR)
    except OSError:
        pass  # Windows may not support chmod


def wait_for_session(bastion_client, session_id, timeout=300):
    """Poll until the bastion session is ACTIVE or fails."""
    print("  Waiting for session to become ACTIVE...", end="", flush=True)
    start = time.time()
    while time.time() - start < timeout:
        session = bastion_client.get_session(session_id).data
        if session.lifecycle_state == "ACTIVE":
            print(" ACTIVE")
            return session
        if session.lifecycle_state in ("FAILED", "DELETED"):
            print(f" {session.lifecycle_state}")
            print(f"ERROR: Session entered {session.lifecycle_state} state.")
            sys.exit(1)
        print(".", end="", flush=True)
        time.sleep(5)
    print(" TIMEOUT")
    print(f"ERROR: Session did not become ACTIVE within {timeout}s.")
    sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Create a bastion port-forwarding session and print the SSH command."
    )
    parser.add_argument("--target", choices=["poc", "dev"], default="poc",
                        help="Target instance: poc (default) or dev (requires hop through POC)")
    parser.add_argument("--ttl", type=int, default=3600,
                        help="Session TTL in seconds (default: 3600)")
    parser.add_argument("--key", default="compute.pem",
                        help="Path to the SSH private key file (default: compute.pem)")
    parser.add_argument("--local-port", type=int, default=2222,
                        help="Local port for the SSH tunnel (default: 2222)")
    parser.add_argument("--timeout", type=int, default=300,
                        help="Max seconds to wait for session activation (default: 300)")
    args = parser.parse_args()

    # ── Gather Terraform outputs ─────────────────────────────────────────────
    print("Reading Terraform outputs...")
    bastion_id = terraform_output("bastion_id")
    poc_private_ip = terraform_output("poc_instance_private_ip")
    dev_private_ip = terraform_output("dev_instance_private_ip")
    ssh_pub_key = terraform_output("ssh_public_key_openssh")

    target_ip = poc_private_ip if args.target == "poc" else dev_private_ip

    # ── Write keys if needed ─────────────────────────────────────────────────
    if not os.path.exists(args.key):
        print(f"  Private key '{args.key}' not found, extracting from Terraform state...")
        ssh_priv_key = terraform_output("ssh_private_key_pem")
        write_key_file(ssh_priv_key, args.key)
        print(f"  Written to {args.key}")

    pub_key_file = args.key.replace(".pem", "_pub.key")
    if not os.path.exists(pub_key_file):
        write_key_file(ssh_pub_key, pub_key_file)
        print(f"  Public key written to {pub_key_file}")

    # ── Create port-forwarding session ───────────────────────────────────────
    print(f"\nCreating port-forwarding session to {args.target.upper()} instance ({target_ip})...")
    config = oci.config.from_file()
    bastion_client = oci.bastion.BastionClient(config)

    session_details = oci.bastion.models.CreateSessionDetails(
        bastion_id=bastion_id,
        target_resource_details=oci.bastion.models.CreatePortForwardingSessionTargetResourceDetails(
            session_type="PORT_FORWARDING",
            target_resource_private_ip_address=target_ip,
            target_resource_port=22,
        ),
        key_details=oci.bastion.models.PublicKeyDetails(
            public_key_content=ssh_pub_key,
        ),
        session_ttl_in_seconds=args.ttl,
    )

    response = bastion_client.create_session(session_details)
    session_id = response.data.id
    print(f"  Session ID: {session_id}")

    # ── Wait for session ─────────────────────────────────────────────────────
    session = wait_for_session(bastion_client, session_id, timeout=args.timeout)

    # ── Build SSH commands ───────────────────────────────────────────────────
    region = config.get("region", "us-ashburn-1")
    bastion_host = f"host.bastion.{region}.oci.oraclecloud.com"
    proxy_session = f"{session_id}@{bastion_host}"
    key_path = args.key.replace("\\", "/")
    local_port = args.local_port

    print()
    print("=" * 70)
    print(f"BASTION TUNNEL — {args.target.upper()} Instance ({target_ip})")
    print("=" * 70)
    print()
    print("Step 1: Open the tunnel (run in a separate terminal):")
    print()
    print(f"  ssh -i {key_path} -N -L {local_port}:{target_ip}:22 \\")
    print(f"    -p 22 {proxy_session}")
    print()
    print("Step 2: Connect through the tunnel (in another terminal):")
    print()
    print(f"  ssh -i {key_path} -p {local_port} opc@localhost")
    print()

    if args.target == "poc":
        print("To reach the Dev instance, from the POC instance run:")
        print(f"  ssh opc@{dev_private_ip}")
        print()

    print("=" * 70)
    print(f"Session expires in {args.ttl // 60} minutes.")


if __name__ == "__main__":
    main()
