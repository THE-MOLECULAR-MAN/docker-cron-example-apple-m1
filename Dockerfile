# BUILD-USING:        docker build -t test-cron .
# RUN-USING docker run --detach=true --volumes-from t-logs --name t-cron test-cron

# CHANGED: to use an image that works on Apple M1 chips
FROM arm64v8/debian:stable
#
# Set correct environment variables.
ENV HOME /root
ENV TEST_ENV test-value

# CHANGED: adding support for the "ps" command to see what's running:
RUN apt-get update && apt-get install -y software-properties-common procps && apt-get update

# Install Python Setuptools
RUN apt-get install -y python cron

# CHANGED: removed package that doesn't exist in this version of Debian
RUN apt-get purge -y software-properties-common && apt-get clean -y && apt-get autoclean -y && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# these should be replaced with COPY instead
ADD cron-python /etc/cron.d/
ADD test.py /
ADD run-cron.py /

RUN chmod a+x test.py run-cron.py

# Set the time zone to the local time zone
RUN echo "America/New_York" > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata
CMD ["/run-cron.py"]
