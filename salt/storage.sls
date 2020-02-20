storage_bootstrap:
  cmd.run:
    - name: "newfs -m 1 /dev/da0 && touch /root/.formatted_disk && mkdir -p /mnt/storage && mount -o rw,noatime /dev/da0 /mnt/storage && touch /root/.formatted_disk && echo '/dev/da0 /mnt/storage ufs rw,noatime 0 0' | sudo tee -a /etc/fstab"
    - creates: /root/.formatted_disk
