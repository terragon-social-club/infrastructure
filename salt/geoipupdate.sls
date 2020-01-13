geoipupdate:
  pkg.installed: []
  cmd.run:
    - creates: /usr/local/share/GeoIP/GeoLite2-City.mmdb

/usr/local/etc/GeoIP.conf:
  file.managed:
    - source: salt:///files/geoipupdate/geoip.jinja.conf
    - template: jinja
    - require:
        - pkg: geoipupdate

/usr/local/bin/geoipupdate:
  cron.present:
    - user: root
    - hour: 1
