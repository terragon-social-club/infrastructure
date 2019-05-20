"touch /etc/localtime":
  cmd.run:
    - creates: "/etc/localtime"

America/New_York:
  timezone.system:
    - utc: True
    - require:
      - cmd: "touch /etc/localtime"
