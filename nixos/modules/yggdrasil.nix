{
  services.yggdrasil = {
    enable = true;
    persistentKeys = true;
    # The NixOS module will generate new keys and a new IPv6 address each time
    # it is started if persistentKeys is not enabled.

    settings = {
      Peers = [
        # Yggdrasil will automatically connect and "peer" with other nodes it
        # discovers via link-local multicast announcements. Unless this is the
        # case (it probably isn't) a node needs peers within the existing
        # network that it can tunnel to.
        "tcp://s-mow-0.sergeysedoy97.ru:65533"
        "tls://s-mow-0.sergeysedoy97.ru:65534"
        "quic://x-mow-0.sergeysedoy97.ru:65535"
        "tcp://s-mow-1.sergeysedoy97.ru:65533"
        "tls://s-mow-1.sergeysedoy97.ru:65534"
        "quic://x-mow-1.sergeysedoy97.ru:65535"
        "tcp://188.225.9.167:18226"
        "tls://188.225.9.167:18227"
        # Public peers can be found at
        # https://github.com/yggdrasil-network/public-peers
      ];
    };
  };
}
