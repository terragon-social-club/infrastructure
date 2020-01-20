"Pull Artifact":
  local.state.single:
    - tgt: beast
    - arg:
      - cmd.run
      - salt butter cp.push '/usr/local/jenkins/jobs/{{ grains['fqdn'] }} Build And Deploy Artifact/lastSuccessful/archive/*' upload_path='/'
