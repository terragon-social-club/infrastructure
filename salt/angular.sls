git:
  pkg.installed

https://github.com/terragon-social-club/terragon.git:
  git.latest:
    - target: /usr/local/www/apache24/data
    - require:
      - pkg:
        - apache24
        - git
