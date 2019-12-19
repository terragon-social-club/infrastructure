ipfw:
  service.running: []
  require:
    - file: /etc/rc.conf
    - file: /usr/local/etc/ipfw.rules

/etc/rc.conf:
  file.append:
    - text: firewall_enable="YES"
    - text: firewall_script="/usr/local/etc/ipfw.rules"

/usr/local/etc/ipfw.rules:
  file.managed:
    - source: salt:///files/ipfw/base.rules
    - template: jinja
