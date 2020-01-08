/srv/storage:
  mount.mounted:
    - device: da
    - fstype: zfs
    - persist: True
    - mkmnt: True
    - device_name_regex:
      - /dev/da0
