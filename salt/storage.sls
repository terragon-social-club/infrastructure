/srv/storage:
  mount.mounted:
    - device: /dev/da0
    - fstype: zfs
    - opts: defaults,nofail,discard,noatime
    - persist: True
    - mkmnt: True
