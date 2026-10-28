{ ... }: {
  networking.useDHCP = false;

  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "2.31.61.43";
      prefixLength = 32;
    }
  ];

  networking.defaultGateway = {
    address = "172.31.1.1";
    interface = "eth0";
  };

  networking.nameservers = [
    "2a01:4ff:ff00::add:2"
    "2a01:4ff:ff00::add:1"
    "185.12.64.1"
  ];
}
