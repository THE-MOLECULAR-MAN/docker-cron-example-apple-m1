# CHANGED: to use an image that works on Apple M1 chips
FROM arm64v8/debian:stable

# Set environment variables.
ENV HOME /root
ENV TEST_ENV test-value

# CHANGED: adding support for the "ps" command to see what's running
# WARNING: PYTHON IS OLD VERSION, COULD CAUSE ISSUES!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common=0.96.20.2-2.1   \
    procps=2:3.3.17-5 \
    cron=3.0pl1-137   \
    python         && \
    apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Python Setuptools
# POTENTIAL FUTURE PROBLEM, OLD PYTHON VERSION: 2.7.18 is default python
# RUN apt-get install -y --no-install-recommends apt-get install python3=3.9.2-3 python-is-python3

# DON'T REMOVE THIS IN CASE IT CAUSES AN ISSUE
# RUN apt-get purge -y software-properties-common

# Copy over files and set permissions
# TODO: CHANGE OWNER
COPY --chmod=0744 ["test.py", "run-cron.py", "/"]
COPY --chown=root --chmod=0644 ["cron-python", "/etc/cron.d/"]

# Set the time zone to US Eastern, ignore host time zone
RUN echo "America/New_York" > /etc/timezone && \
    dpkg-reconfigure --frontend noninteractive tzdata

# start the cron service
CMD ["/run-cron.py"]
