#!/bin/bash
# Tim H 2023
# inside docker container test script
ps aux
crontab -l -u dockeruser
tail -f /var/log/test.log
