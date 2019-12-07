py27-certbot:
  pkg.installed

certbot-2.7 certonly  --non-interactive --standalone -d {{grains['fqdn']}} --agree-tos -m admin@terragon.us:
  cmd.run:
    - creates: /usr/local/etc/letsencrypt/live/{{grains['fqdn']}}/privkey.pem

cat /usr/local/etc/letsencrypt/live/{{grains['fqdn']}}/privkey.pem /usr/local/etc/letsencrypt/live/{{grains['fqdn']}}/cert.pem | tee /usr/local/etc/letsencrypt/live/{{grains['fqdn']}}/{{grains['fqdn']}}.pem:
  cmd.run:
    - creates: /usr/local/etc/letsencrypt/live/{{grains['fqdn']}}/{{grains['fqdn']}}.pem
