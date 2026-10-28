let
  local = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrBZUAXqBnDp2983NfRDUDQBdOAPId25NCWAo/jEWSj";

  # grab the server /etc/ssh/ssh_host_ed25519_key.pub
  remote = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDvR+Nfqb7Dz5AI0d7fj6WjcElSRblEQJUcFbqp5MHSQ";
in
{
  "root-password.age".publicKeys = [ local remote ];
  "env-docker-db-password.age".publicKeys = [local remote ];
  "backend-db-password.age".publicKeys = [local remote ];
  "backend-better-auth-secret.age".publicKeys = [local remote ];
  "backend-openai-api-key.age".publicKeys = [ local remote ];
  "env-cloudflare-api-token.age".publicKeys = [ local remote ];
}
