git:
  pkg.installed

https://github.com/terragon-social-club/terragon.git:
  git.latest:
    - target: /usr/local/www/apache24/data
    - force_clone: true
    - require:
      - pkg: apache24
      - pkg: git
