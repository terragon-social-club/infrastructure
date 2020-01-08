/srv/storage:
  mount.mounted:
    - device: /dev/da0
    - fstype: xfs
    - opts: defaults,nofail,discard,noatime
    - persist: True
    - mkmnt: True