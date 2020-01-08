/srv/storage:
  mount.mounted:
    - persist: True
    - fstype: zfs
    - device: /dev/da0
