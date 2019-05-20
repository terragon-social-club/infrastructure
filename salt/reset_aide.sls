reset_aide:
  cmd.run:
    - name: 'aide --init && mv /var/db/aide/databases/aide.db.new /var/db/aide/databases/aide.db'

