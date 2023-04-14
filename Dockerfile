# BUILD-USING:        docker build -t test-cron .
# RUN-USING docker run --detach=true --volumes-from t-logs --name t-cron test-cron

# CHANGED: to use an image that works on Apple M1 chips
FROM arm64v8/debian:stable
#
# Set correct environment variables.
ENV HOME /root
ENV TEST_ENV test-value

# CHANGED: adding support for the "ps" command to see what's running:
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common=0.96.20.2-2.1   \
    procps=2:3.3.17-5 \
    cron=3.0pl1-137   \
    && apt-get update

# Install Python Setuptools
# python3=3.9.2-3   ???
# POTENTIAL FUTURE PROBLEM, OLD PYTHON VERSION: 2.7.18 is default python
# apt-get install python3 python-is-python3
RUN apt-get install -y --no-install-recommends \
    python

# CHANGED: removed package that doesn't exist in this version of Debian
RUN apt-get purge -y software-properties-common && apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# these should be replaced with COPY instead
# TODO: CHANGE OWNER
COPY --chmod=0744 ["test.py", "run-cron.py", "/"]
COPY --chown=root --chmod=0644 ["cron-python", "/etc/cron.d/"]

# ADD cron-python /etc/cron.d/
# ADD test.py /
# ADD run-cron.py /

# RUN chmod a+x test.py run-cron.py

# Set the time zone to the local time zone
RUN echo "America/New_York" > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata
CMD ["/run-cron.py"]
