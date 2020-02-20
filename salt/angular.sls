extend:
  apache24:
    service.running:
      - require:
        - npm: "@terragon/terragon@0.0.21"

git:
  pkg.installed

www/npm:
  pkg.installed

"@terragon/terragon@0.0.21":
  npm.installed:
    - require:
      - pkg: www/npm
