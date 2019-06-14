# Basic FreeBSD Security
sendmail:
  service.disabled

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

