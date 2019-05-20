# Basic FreeBSD Security
/etc/rc.conf:
  file.blockreplace:
    - source: salt:///files/freebsd-11.1/rc.security.conf
    - show_changes: True
    - prepend_if_not_found: True

# IDS
aide:
  pkg.installed: []

refresh_aide:
  cmd.run:
    - name: 'aide --init && mv /var/db/aide/databases/aide.db.new /var/db/aide/databases/aide.db'
    - onchanges:
      - pkg: aide
    - require:
      - file: /etc/rc.conf

