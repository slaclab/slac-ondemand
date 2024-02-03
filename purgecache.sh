#!/bin/bash

/usr/bin/grep missing /var/lib/ondemand-nginx/config/puns/*.conf  2>/dev/null | /usr/bin/grep rewrite | /usr/bin/sed -e 's|/var/lib/ondemand-nginx/config/puns/||g' -e 's|.conf.*||g' | /usr/bin/xargs -n1 -r -I{} /opt/ood/nginx_stage/sbin/nginx_stage pun --skip-nginx --user {} \&\& /opt/ood/nginx_stage/sbin/nginx_stage nginx --signal reload --user {}

