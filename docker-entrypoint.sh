#!/bin/sh

# setup munge
if [ -e /mnt/munge/munge.key ]; then
  echo "Copying munge key from /mnt/munge/munge.key"
  cp /mnt/munge/munge.key /etc/munge/munge.key
  chown munge:munge /etc/munge/munge.key
  chmod 400 /etc/munge/munge.key
fi

# pick up relevant supervisord conf
SUPERVISORD_CONFIG=${SUPERVISORD_CONFIG:-/supervisord.conf}
echo "Starting with supervisord" $(/usr/bin/supervisord --version) "with $SUPERVISORD_CONFIG..."
exec /usr/bin/supervisord --configuration $SUPERVISORD_CONFIG

