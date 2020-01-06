include:
  - filebeat # logging
{% if 'master' in grains['roles'] %}  - ipfw     # firewall
  - fail2ban
{% endif %}
sendmail_enable:
  sysrc.managed:
    - value: "NONE"

sendmail_msp_queue_enable:
  sysrc.managed:
    - value: "NO"

sendmail_outbound_enable:
  sysrc.managed:
    - value: "NO"

sendmail_submit_enable:
  sysrc.managed:
    - value: "NO"

# IDS
#aide:
#  pkg.installed: []

#refresh_aide:
#  cmd.run:
#    - name: 'aide --init && mv /var/db/aide/databases/aide.db.new /var/db/aide/databases/aide.db'
#    - onchanges:
#      - pkg: aide
#    - require:
#      - file: /etc/rc.conf
