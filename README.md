# Virtual Challenge deploy

## SSH

Copy the public key to a file named `id_ed25519.pub`, and use it in `secrets/secrets.nix`.

## Secrets

Generate a new secret with `nix run github:ryantm/agenix -- -e ./secrets/<SECRET-FILE-NAME.age>`

- `root-password`: Root user password.
- `env-docker-db-password`: Environment file for database password on docker (e.g. `POSTGRES_PASSWORD=1234`).
- `backend-db-password`: Raw database password (must be same value as `env-docker-db-password`).
- `backend-better-auth-secret`: Better Auth secret (generated with `openssl rand -base64 32`).
- `env-cloudflare-api-key`: Cloudflare domain API keys (with zone and dns permissions). Using the format:

  ```
    CF_DNS_API_TOKEN=token-here
    CF_ZONE_API_TOKEN=token-here
  ```

If the public keys defined on `secrets.nix` changed, remember to rekey with `nix run github:ryantm/agenix -- --rekey`.

## Backend files

The files in the `files_to_copy` folder are apied to the server maintaining the same structure from the root folder. The destination path is configured via backend-path in `configuration.nix` (default: `/opt/virtualchallenge`).

## Networking

This deployment is designed for Hetzner VPS static networking (see `hetzner.nix`). Adjust it to suit your needs.

## Testing

To check if the configuration compiles: `nix build .#nixosConfigurations.daredevil.config.system.build.toplevel --dry-run`

## Deploy

`nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-generate-config ./hardware-configuration.nix --flake '.#daredevil' --target-host root@<SERVER-IP> --extra-files ./files_to_copy --copy-host-keys`

## Update config on remote

`nixos-rebuild switch --flake .#daredevil --target-host root@<SERVER-IP>`
