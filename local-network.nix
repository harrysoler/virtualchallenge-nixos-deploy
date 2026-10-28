{ ... }: {
  networking = {
    useDHCP = false;
    interfaces.enp1s0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.122.251";
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = "192.168.122.1";
    nameservers = [ "8.8.8.8" "1.1.1.1" ];
  };
}
