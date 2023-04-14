# CHANGED: to use an image that works on Apple M1 chips
FROM arm64v8/debian:stable

USER root

# Set environment variables.
ENV HOME /root
ENV TEST_ENV test-value
ENV RUNNING_IN_DOCKER_CONTAINER True
ENV LOGFILE /var/log/test.log
ENV WORKING_DIR /app
# cannot use ENV variables in RUN commands, so 
# can't parameterize things like the non-root username

WORKDIR ${WORKING_DIR}

# Set the time zone to US Eastern, ignore host time zone
RUN echo "America/New_York" > /etc/timezone && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Dependencies Debian version, clean up APT cache afterward
RUN apt-get update                                && \
    apt-get install -y --no-install-recommends \
    software-properties-common=0.96.20.2-2.1   \
    procps=2:3.3.17-5                          \
    cron=3.0pl1-137                            \
    ffmpeg=7:4.3.5-0+deb11u1                   \
    curl=7.74.0-1.3+deb11u7                    \
    screen=4.8.0-6                             \
    python3=3.9.2-3 python-is-python3 python3-pip && \
    apt-get clean -y && apt-get autoclean -y      && \
    apt-get autoremove -y                         && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# DON'T REMOVE THIS IN CASE IT CAUSES AN ISSUE
# RUN apt-get purge -y software-properties-common

# Python:3.11 (Debian) version:
RUN useradd -ms /bin/bash dockeruser

# set ownership of directories and files before copying new ones over
RUN touch ${LOGFILE} && \
    chmod 777 ${LOGFILE} && \
    chown -R dockeruser ${WORKING_DIR} ${LOGFILE}

# Copy over files and set permissions
# TODO: CHANGE OWNER
COPY --chown=dockeruser --chmod=0744 ["*.py", "*.txt", "${WORKING_DIR}/"]
# Install pip dependencies
RUN pip3 install --no-cache-dir --no-cache --upgrade -r requirements.txt


COPY --chown=root       --chmod=0644 ["cron-python", "/etc/cron.d/"]
# install the crontab
# mark log as global writable, install crontab for user
RUN /usr/bin/crontab -u dockeruser /etc/cron.d/cron-python


# start the cron service
CMD ["/app/run-cron.py"]
