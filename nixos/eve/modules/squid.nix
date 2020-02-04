{ pkgs, ... }: {

  services.squid = {
    enable = true;
    proxyPort = 8888;
    extraConfig = ''
      auth_param basic program ${pkgs.squid}/libexec/basic_ldap_auth -b "ou=users,dc=eve" -f "(&(objectClass=proxyUser)(mail=%s))" -D cn=squid,ou=system,ou=users,dc=eve -W /run/keys/squid-ldap -h 127.0.0.1
      acl ldapauth proxy_auth REQUIRED
      http_access allow ldapauth

      https_port 8889 cert=/var/lib/acme/devkid.net/fullchain.pem key=/var/lib/acme/devkid.net/key.pem

      # for netdata
      access_log stdio:/var/log/squid/access.log combined

      # for netdata
      http_access allow localhost manager
      http_access deny manager
    '';
  };

  networking.firewall.allowedTCPPorts = [ 8888 8889 ];

  users.users.squid.extraGroups = [ "keys" ];
  systemd.services.squid.serviceConfig.SupplementaryGroups = [ "keys" ];

  krops.secrets.files.squid-ldap.owner = "squid";

  environment.etc."netdata/python.d/squid.conf".text = ''
    tcp8888new:
      name : 'local'
      host : 'localhost'
      port : 8888
      request : '/squid-internal-mgr/counters'
  '';

  environment.etc."netdata/python.d/web_log.conf".text = ''
    squid_log3:
      name: 'squid'
      path: '/var/log/squid/access.log'
  '';

  users.users.netdata.extraGroups = [ "squid" ];

  services.openldap.extraConfig = ''
    objectClass ( 1.3.6.1.4.1.16548.1.2.4 NAME 'proxyUser'
        SUP top AUXILIARY
        DESC 'Account to allow a user to use the Squid proxy'
	  MUST ( mail $ userPassword ))
  '';

  services.icinga2.extraConfig = ''
    apply Service "SQUID HTTP v4 (eve)" {
      import "eve-http4-service"
      vars.http_port = 8888
      vars.http_expect = "HTTP/1.1"
      vars.http_sni = false
      vars.http_ssl_force_tlsv1_2 = false
      assign where host.name == "eve.thalheim.io"
    }

    apply Service "SQUID HTTP v6 (eve)" {
      import "eve-http6-service"
      vars.http_port = 8888
      vars.http_expect = "HTTP/1.1"
      vars.http_sni = false
      vars.http_ssl_force_tlsv1_2 = false
      assign where host.name == "eve.thalheim.io"
    }

    apply Service "SQUID HTTPS v4 (eve)" {
      import "eve-http4-service"
      vars.http_port = 8889
      vars.http_expect = "HTTP/1.1"
      assign where host.name == "eve.thalheim.io"
    }

    apply Service "SQUID HTTPS v6 (eve)" {
      import "eve-http6-service"
      vars.http_port = 8889
      vars.http_expect = "HTTP/1.1"
      assign where host.name == "eve.thalheim.io"
    }
  '';

}