extend:
  apache24:
    service.running:
      - require:
        - npm: "@terragon/terragon@0.0.8"

git:
  pkg.installed

www/npm:
  pkg.installed

"@terragon/terragon@0.0.8":
  npm.installed:
    - require:
      - pkg: www/npm
