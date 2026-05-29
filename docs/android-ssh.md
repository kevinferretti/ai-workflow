# Android SSH Access

Use this path for phone access to the hosted workspace. It gives a real shell on
the OVH VM over the private tailnet. It is the reliable mobile fallback when
Codex mobile does not surface remote SSH project threads from the desktop app.

## Recommended Path

Use:

```text
Android Tailscale app
  -> Termux with OpenSSH
  -> ssh codex@<TAILSCALE_NAME_OR_IP>
  -> ~/ai-workflow
  -> bash scripts/workspace-shell.sh
  -> codex
```

Keep the VM private. Do not expose SSH, Codex app-server, code-server, or other
workspace services on the public OVH IP for phone access.

## Phone Setup

1. Install Tailscale on Android from Google Play and sign in to the same tailnet
   as the OVH VM.
2. Leave the Tailscale VPN connected.
3. Install Termux from F-Droid or the Termux GitHub release. Prefer those
   sources over the Google Play branch for this workflow.
4. In Termux, install OpenSSH:

```bash
pkg update
pkg upgrade
pkg install openssh
```

## Connect With Tailscale SSH

The VM bootstrap path enables Tailscale SSH with:

```bash
sudo tailscale up --ssh
```

If Tailscale SSH is enabled and your tailnet policy allows your account to SSH
as `codex`, Termux can use the normal SSH client:

```bash
ssh codex@<TAILSCALE_NAME_OR_IP>
```

Use the VM's MagicDNS name when it works. Otherwise use the `100.x.y.z` address
shown by the Tailscale app or admin console.

After the first successful connection, add a phone-local SSH alias in Termux:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat > ~/.ssh/config <<'EOF'
Host ovh-codex
  HostName <TAILSCALE_NAME_OR_IP>
  User codex
  ServerAliveInterval 30
  ServerAliveCountMax 3
EOF
chmod 600 ~/.ssh/config
```

Then connect with:

```bash
ssh ovh-codex
```

## Open The Workspace

After connecting:

```bash
cd ~/ai-workflow
bash scripts/check-workspace.sh
bash scripts/workspace-shell.sh
codex
```

Use the same repo layout as the laptop workflow. Additional working repos belong
under:

```text
~/workspace/repos
```

## If Tailscale SSH Does Not Work

First check the obvious causes:

- The Android phone is connected to Tailscale.
- The VM is online in the Tailscale machines list.
- The VM was started with `sudo tailscale up --ssh`.
- The tailnet policy allows your Tailscale identity to SSH as `codex`.
- You are using the VM tailnet name or `100.x.y.z` address, not the public OVH
  IP.

If you intentionally choose regular OpenSSH over the tailnet instead of
Tailscale SSH, disable Tailscale SSH on the VM and use an Android SSH key. In
Termux:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/ovh_codex -C "android-codex"
cat ~/.ssh/ovh_codex.pub
```

Add only the printed public key to the VM as the `codex` user from an existing
trusted laptop or VM shell:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
printf '%s\n' '<PASTE_ANDROID_PUBLIC_KEY>' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Then configure Termux:

```bash
cat > ~/.ssh/config <<'EOF'
Host ovh-codex
  HostName <TAILSCALE_NAME_OR_IP>
  User codex
  IdentityFile ~/.ssh/ovh_codex
  IdentitiesOnly yes
  ServerAliveInterval 30
  ServerAliveCountMax 3
EOF
chmod 600 ~/.ssh/config
ssh ovh-codex
```

Do not paste the private key anywhere. Only the `.pub` value belongs on the VM.

## References

- Tailscale Android install: <https://tailscale.com/kb/1079/install-android>
- Tailscale SSH: <https://tailscale.com/kb/1193/tailscale-ssh/>
- Termux installation: <https://github.com/termux/termux-app#installation>
