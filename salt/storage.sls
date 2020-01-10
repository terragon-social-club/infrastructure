/mnt/storage:
  mount.mounted:
    - device: /dev/da0
    - opts: rw,noatime
    - persist: True
    - mkmnt: True

newfs -m 1 /dev/da0 && touch /root/.formatted_disk:
  cmd.run:
    - creates: /root/.formatted_disk
