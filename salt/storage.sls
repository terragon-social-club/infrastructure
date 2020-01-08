/srv/storage:
  mount.mounted:
    - persist: True
    - mkmnt: True
    - fstype: zfs
    - device: /dev/da0
