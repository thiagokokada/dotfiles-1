{ pkgs, config, ... }: 
let
  #args = /run/keys/dovecot-ldap.conf
  ldapConfig = pkgs.writeText "dovecot-ldap.conf" ''
    hosts = 127.0.0.1
    dn = "cn=dovecot,dc=mail,dc=eve"
    dnpass = "@ldap-password@"
    tls = no
    auth_bind = no
    ldap_version = 3
    base = ou=users,dc=eve
    user_filter = (&(objectClass=MailAccount)(mail=%u)(accountActive=TRUE)(delete=FALSE))
    user_attrs = \
      quota=quota_rule=*:bytes=%$, \
      =home=/var/vmail/%d/%n/, \
      =mail=maildir:/var/vmail/%d/%n/Maildir
    pass_attrs = mail=user,userPassword=password
    pass_filter = (&(objectClass=MailAccount)(mail=%u))
    iterate_attrs = =user=%{ldap:mail}
    iterate_filter = (objectClass=MailAccount)
    scope = subtree
    default_pass_scheme = SSHA
  '';
in {

  services.dovecot2 = {
    enable = true;
    enableImap = true;
    enableLmtp = true;
    mailLocation = "maildir:/var/vmail/%d/%n/Maildir";
    mailUser = "vmail";
    mailGroup = "vmail";
    extraConfig = ''
      ssl = yes
      ssl_cert = </etc/letsencrypt/live/higgsboson.tk-0002/fullchain.pem
      ssl_key = </etc/letsencrypt/live/higgsboson.tk-0002/privkey.pem
      local_name devkid.net {
        ssl_cert = </etc/letsencrypt/live/devkid.net/fullchain.pem
        ssl_key = </etc/letsencrypt/live/devkid.net/privkey.pem
      }
      local_name imap.devkid.net {
        ssl_cert = </etc/letsencrypt/live/devkid.net-2/fullchain.pem
        ssl_key = </etc/letsencrypt/live/devkid.net-2/privkey.pem
      }
      ssl_cipher_list = AES128+EECDH:AES128+EDH
      ssl_prefer_server_ciphers = yes
      ssl_dh=<${config.security.dhparams.params.dovecot2.path}

      mail_plugins = virtual

      service lmtp {
        user = vmail
        unix_listener /var/lib/postfix/queue/private/dovecot-lmtp {
          group = postfix
          mode = 0600
          user = postfix
        }
      }

      service doveadm {
        inet_listener {
          port = 4170
          ssl = yes
        }
      }
      protocol lmtp {
        postmaster_address=postmaster@higgsboson.tk
        hostname=mail.higgsboson.tk
        mail_plugins = $mail_plugins sieve
      }
      service auth {
        unix_listener auth-userdb {
          mode = 0640
          user = vmail
          group = vmail
        }
        # Postfix smtp-auth
        unix_listener /var/lib/postfix/queue/private/auth {
          mode = 0666
          user = postfix
          group = postfix
        }
      }
      userdb {
        args = /run/dovecot2/ldap.conf
        driver = ldap
      }
      passdb {
        args = /run/dovecot2/ldap.conf
        driver = ldap
      }

      service imap-login {
        client_limit = 1000
        service_count = 0
        inet_listener imaps {
          port = 993
        }
      }

      service managesieve-login {
        inet_listener sieve {
          port = 4190
        }
      }
      protocol sieve {
        managesieve_logout_format = bytes ( in=%i : out=%o )
      }
      plugin {
        sieve_dir = /var/vmail/%d/%n/sieve/scripts/
        sieve = /var/vmail/%d/%n/sieve/active-script.sieve
        sieve_extensions = +vacation-seconds
        sieve_vacation_min_period = 1min
      }

      # If you have Dovecot v2.2.8+ you may get a significant performance improvement with fetch-headers:
      imapc_features = $imapc_features fetch-headers
      # Read multiple mails in parallel, improves performance
      mail_prefetch_count = 20

    '';
    modules = [
      pkgs.dovecot_pigeonhole
    ];
    protocols = [
      "sieve"
    ];
  };

  users.users.vmail = {
    home = "/var/vmail";
    createHome = true;
    isSystemUser = true;
    uid = 1000;
    shell = "/run/current-system/sw/bin/nologin";
  };

  deployment.keys."dovecot-ldap-password" = {
    keyFile = ../secrets/dovecot-ldap-password;
  };

  security.dhparams = {
    enable = true;
    params.dovecot2 = {};
  };

  systemd.services.dovecot2.preStart = ''
    sed -e "s!@ldap-password@!$(cat /run/keys/dovecot-ldap-password)!" ${ldapConfig} > /run/dovecot2/ldap.conf
  '';
}