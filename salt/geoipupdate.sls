geoipupdate:
  pkg.installed

/usr/local/etc/GeoIP.conf:
  file.managed:
    - source: salt:///files/geoipupdate/geoip.jinja.conf
    - template: jinja
    - require:
      - pkg: geoipupdate
