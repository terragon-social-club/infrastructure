/srv/storage:
  mount.mounted:
    - device: da0
    - fstype: zfs
    - opts: defaults,nofail,discard,noatime
    - persist: True
    - mkmnt: True
