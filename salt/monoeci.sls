monoeci:
  user.present:
    - home: /home/monoeci

/usr/bin/monoeci-cli:
  file.managed:
    - source: salt:///files/coins/monoeci/monoeci-cli
    - mode: 744
    - user: monoeci
    - require:
      - user: monoeci

/usr/bin/monoeci-tx:
  file.managed:
    - source: salt:///files/coins/monoeci/monoeci-tx
    - mode: 744
    - user: monoeci
    - require:
      - user: monoeci

/usr/bin/monoecid:
  file.managed:
    - source: salt:///files/coins/monoeci/monoecid
    - mode: 744
    - user: monoeci
    - require:
      - user: monoeci

/home/monoeci/.monoeciCore/monoeci.conf:
  file.managed:
    - source: salt:///files/coins/monoeci/monoeci.conf
    - mode: 744
    - user: monoeci
    - require:
      - file: /home/monoeci/sentinel
      - user: monoeci

'nohup monoecid -server -rpcbind=127.0.0.1 -pid=/tmp/monoecid.pid -daemon > /dev/null 2>&1':
  cmd.run:
    - runas: monoeci
    - creates: /tmp/monoecid.pid
    - require:
      - user: monoeci
    
/home/monoeci/sentinel:
  file.recurse:
    - source: salt://files/coins/monoeci/sentinel-master
    - user: monoeci
    - require:
      - cmd: 'nohup monoecid -server -rpcbind=127.0.0.1 -pid=/tmp/monoecid.pid -daemon > /dev/null 2>&1'
      - user: monoeci
        
/home/monoeci/.wine:
  file.managed:
    - source: salt://files/coins/monoeci/wallet.dat
    - require:
      - user: monoeci
        
virtualenv ./venv:
  cmd.run:
    - runas: monoeci
    - cwd: /home/monoeci/sentinel
    - creates: /home/monoeci/sentinel/venv
    - require:
      - file: /home/monoeci/sentinel
      - user: monoeci

./venv/bin/pip install -r requirements.txt:
  cmd.wait:
    - runas: monoeci
    - cwd: /home/monoeci/sentinel
    - watch:
      - cmd: virtualenv ./venv
    - require:
      - user: monoeci

cd /home/monoeci/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1:
  cron.present:
    - user: monoeci
    - minute: '*/1'
    - require:
      - file: /home/monoeci/sentinel
      - user: monoeci
