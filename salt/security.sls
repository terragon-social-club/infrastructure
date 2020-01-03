

# Firewall Enabled & Misc Services Disabled
#
include:
  - ipfw
  - filebeat

/etc/rc.conf:
  file.append:
    - text:
      - sendmail_enable="NONE"
      - sendmail_msp_queue_enable="NO"
      - sendmail_outbound_enable="NO"
      - sendmail_submit_enable="NO"
      - firewall_script="/usr/local/etc/ipfw.rules"
      - firewall_enable="NO"


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

