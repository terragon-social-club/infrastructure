# Disable Sendmail
/etc/rc.conf:
  file.append:
    - text: sendmail_enable="NONE"
    - text: sendmail_msp_queue_enable="NO"
    - text: sendmail_outbound_enable="NO"
    - text: sendmail_submit_enable="NO"
    - text: firewall_script="/usr/local/etc/ipfw.rules"
    - text: firewall_enable="NO"



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

