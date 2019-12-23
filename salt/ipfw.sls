/etc/rc.conf:
  file.append:
    - text: firewall_script="/usr/local/etc/ipfw.rules"
    - text: firewall_enable="NO"

/usr/local/etc/ipfw.rules:
  file.managed:
    - source: salt:///files/ipfw/base.rules
    - template: jinja
