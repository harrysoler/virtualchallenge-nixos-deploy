{
  modulesPath,
  lib,
  config,
  pkgs,
  pkgs-unstable,
  inputs,
  age,
  ...
} @ args:
let
  certloc = "/var/lib/acme/harryalex.com";

  backend-path = "/opt/virtualchallenge";

  backend-db-user = "postgres";
  backend-db-name = "virtualchallengedb";
  backend-db-host = "localhost";
  backend-db-port = "5432";

  backend-better-auth-url = "http://localhost:8000";
  frontend-url = "http://localhost:5173";
in {
  imports = [
    ./disk-config.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  age.secrets = {
    root-password = {
      file = ./secrets/root-password.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
    env-docker-db-password = {
      file = ./secrets/env-docker-db-password.age;
      owner = "backend";
      group = "docker";
      mode = "0440";
    };
    backend-db-password = {
      file = ./secrets/backend-db-password.age;
      owner = "backend";
      group = "backend";
      mode = "0400";
    };
    backend-better-auth-secret = {
      file = ./secrets/backend-better-auth-secret.age;
      owner = "backend";
      group = "backend";
      mode = "0400";
    };
    backend-openai-api-key = {
      file = ./secrets/backend-openai-api-key.age;
      owner = "backend";
      group = "backend";
      mode = "0400";
    };
    env-cloudflare-api-token = {
      file = ./secrets/env-cloudflare-api-token.age;
      owner = "root";
      group = config.services.caddy.group;
      mode = "0440";
    };
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.hostName = "daredevil";
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  users.users.root = {
    hashedPasswordFile = config.age.secrets.root-password.path;
    openssh.authorizedKeys.keys = [
      (builtins.readFile ./id_ed25519.pub)
    ];
  };

  users.groups.backend = {};

  users.users.backend = {
    isSystemUser = true;
    createHome = false;
    extraGroups = [ "docker" ];
    group = "backend";
  };

  environment.systemPackages = with pkgs; [
    gitMinimal
    sqlit-tui
  ] ++ [
    (pkgs.writeShellApplication {
      name = "virtualchallenge-init-db";
    
      text = ''
        # shellcheck disable=SC1091

        set -euo pipefail

        if [[ $# -ne 1 || ( "$1" != "migrate" && "$1" != "seed" ) ]]; then
            echo "Usage: $0 {migrate|seed}" >&2
            exit 1
        fi

        task="$1"

        OPENAI_API_KEY="$(cat ${config.age.secrets.backend-openai-api-key.path})"
        DATABASE_URL="postgres://${backend-db-user}:$(cat ${config.age.secrets.backend-db-password.path})@${backend-db-host}:${backend-db-port}/${backend-db-name}"
        BETTER_AUTH_SECRET="$(cat ${config.age.secrets.backend-better-auth-secret.path})"
        BETTER_AUTH_URL="${backend-better-auth-url}"
        FRONTEND_URL="${frontend-url}"

        export OPENAI_API_KEY
        export DATABASE_URL
        export BETTER_AUTH_SECRET
        export BETTER_AUTH_URL
        export FRONTEND_URL

        cd ${backend-path}
        exec ${pkgs.deno}/bin/deno task "$task"
      '';
    })
  ];

  systemd.tmpfiles.settings = {
    "virtualchallenge-binaries" = {
      "${backend-path}" = {
        d = {
          mode = "0775";
          user = "backend";
          group = "backend";
        };
      };
    };
  };

  systemd.services.virtualchallenge = {
    description = "Deno Backend of Virtual Challenge";

    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "docker.service" "docker-virtualchallenge-db.service" ];
    requires = [ "docker-virtualchallenge-db.service" ];
    wants = [ "network-online.target" ];

    environment = {
      BETTER_AUTH_URL = backend-better-auth-url;
      FRONTEND_URL = frontend-url;
      DENO_DIR = "/var/lib/virtualchallenge/deno";
    };

    serviceConfig = {
      Type = "exec";
      User = "backend";
      Restart = "on-failure";
      RestartSec = "5s";

      StateDirectory = "virtualchallenge";

      WorkingDirectory = backend-path;

      NoNewPrivileges = true;
      PrivateTmp = true;
    };

    script = ''
      export OPENAI_API_KEY="$(cat ${config.age.secrets.backend-openai-api-key.path})"
      export DATABASE_URL="postgresql://${backend-db-user}:$(cat ${config.age.secrets.backend-db-password.path})@${backend-db-host}:${backend-db-port}/${backend-db-name}"
      export BETTER_AUTH_SECRET="$(cat ${config.age.secrets.backend-better-auth-secret.path})"

      cd ${backend-path}
      exec ${pkgs.deno}/bin/deno run --allow-net --allow-env --allow-read src/main.ts
    '';
  };

  virtualisation.docker.enable = true;

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      virtualchallenge-db = {
        image = "postgres:18";
        ports = [ "${backend-db-port}:${backend-db-port}" ];
        environmentFiles = [
          config.age.secrets.env-docker-db-password.path
        ];

        environment = {
          POSTGRES_USER = backend-db-user;
          POSTGRES_DB = backend-db-name;
        };

        volumes = [
          "pgdata:/var/lib/postgresql"
        ];
      };
    };
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    extraConfig = ''
      PrintLastLog no
    '';
  };

  # nixpkgs.overlays = [
  #   inputs.copyparty.overlays.default
  # ];

  services.caddy = {
    enable = true;
    # virtualHosts."copyparty.harryalex.com".extraConfig = ''
    #   reverse_proxy http://localhost:3923

    #   tls ${certloc}/cert.pem ${certloc}/key.pem {
    #     protocols tls1.3
    #   }
    # '';
    # virtualHosts."penpot.harryalex.com".extraConfig = ''
    #   reverse_proxy http://localhost:9001

    #   tls ${certloc}/cert.pem ${certloc}/key.pem {
    #     protocols tls1.3
    #   }
    # '';
    virtualHosts."virtualchallenge.harryalex.com".extraConfig = ''
      reverse_proxy http://localhost:8000

      tls ${certloc}/cert.pem ${certloc}/key.pem {
        protocols tls1.3
      }
    '';
  };

  users.groups.caddy = {};

  security.acme = {
    acceptTerms = true;
    defaults.email = "harrynotimportant@outlook.com";

    certs."harryalex.com" = {
      group = config.services.caddy.group;

      domain = "harryalex.com";
      extraDomainNames = [ "*.harryalex.com" ];
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1";
      dnsPropagationCheck = true;
      environmentFile = config.age.secrets.env-cloudflare-api-token.path;
    };
  };

  system.stateVersion = "26.05";
}
