/dev/da0:
  zfs.filesystem_present:
    - create_parent: true
    - properties:
        quota: 1G
