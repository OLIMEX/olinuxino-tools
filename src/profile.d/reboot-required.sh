#!/bin/sh

if [ -f /var/run/olinuxino-reboot-required ]; then
  echo ""
  cat /var/run/olinuxino-reboot-required
  echo ""
  echo "*** System restart required ***"
  echo ""
fi
