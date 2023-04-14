#!/bin/bash
# Tim H 2023
# inside docker container test script

set -e

test_failed_exit(){
    echo "
**********************************************************************
    TEST FAILED:    $1
    EXITING.
**********************************************************************

"
    # printenv
    exit 1
}

if pgrep -x cron >/dev/null
then
    echo "[TEST] PASSED: cron is running"
else
    # turns out that if cron dies, the container exits
    ps aux
    test_failed_exit "cron is not running"
fi

# test if the nonroot user's crontab mentions the right script
if crontab -l -u dockeruser | grep -q "/app/test.py" ; then
    echo "[TEST] PASSED: dockeruser's crontab has /app/test.py"
else   
    ps aux
    test_failed_exit "[TEST] FAILED: dockeruser's crontab does NOT have /app/test.py"
fi

# check if cron is successfully running:
# have to wait at least 1 minute for cron to trigger:
echo "[TEST] Waiting at least 1 minute for cron to trigger before checking log..."
sleep 62s

if grep -q "Cron job has run " /var/log/test.log; then
    echo "[TEST] PASSED: test log has cron entries"
else
    ls -lah /var/log/test.log
    cat     /var/log/test.log
    test_failed_exit "[TEST] FAILED: cron is NOT outputting to log."
fi

# ls -lah /var/log/test.log /app

echo "[TEST] All tests passed successfully. Test script finished."
