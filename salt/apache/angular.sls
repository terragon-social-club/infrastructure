extend:
  /usr/local/etc/apache24/httpd.conf:
    file.managed:
      - source: salt:///files/apache/httpd.angular.jinja
  
