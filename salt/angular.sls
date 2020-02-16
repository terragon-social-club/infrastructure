extend:
  apache24:
    service.running:
      - require:
        - npm: "@terragon/terragon@0.0.5"

git:
  pkg.installed

www/npm:
  pkg.installed

"@terragon/terragon@0.0.5":
  npm.installed:
    - require:
      - pkg: www/npm
