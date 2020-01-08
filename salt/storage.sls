/srv/storage:
  mount.mounted:
    - fstype: zfs
    - persist: True
    - mkmnt: True
    - device_name_regex:
      - /dev/da0
