'emacs-nox11':
  pkg.installed

/root/.emacs:
  file.managed:
    - source: salt:///files/.emacs
    - require:
      - pkg: emacs-nox11

"emacs --daemon --eval '(save-buffers-kill-terminal)' || true":
  cmd.run:
    - onchanges:
      - file: '/root/.emacs'
