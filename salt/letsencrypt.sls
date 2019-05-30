py27-certbot:
  pkg.installed

certbot certonly --non-interactive --standalone -d {{grains['fqdn']}} --agree-tos -m admin@terragon.us:
  cmd.run:
    - creates: /usr/local/etc/letsencrypt/live/{{grains['fqdn']}}/privkey.pem

