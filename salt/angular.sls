git@github.com:terragon-social-club/terragon.git:
  git.clone:
    - target: /usr/local/www/apache24/data
    - require:
      - pkg: apache24
