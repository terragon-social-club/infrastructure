git:
  pkg.installed

www/npm:
  pkg.installed

"@terragon/terragon@0.0.2":
  npm.installed:
    - require:
      - pkg: www/npm