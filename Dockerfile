# Hardcoded for Apple M1 chips - arm64v8/debian:stable
FROM arm64v8/debian:stable

# LABEL version=“0.1.0”

# set the user as root (temporarily)
USER root

# Set environment variables.
# https://docs.docker.com/engine/reference/builder/#environment-replacement
# Cannot use these in CMD commands, but can use them in RUN commands
# these variables are defined on a PER USER basis - in this case, root
# so trying to use them as the nonroot user won't work.
ENV HOME /root
ENV TEST_ENV test-value
ENV RUNNING_IN_DOCKER_CONTAINER True

# all 3 of these are hardcoded in cron-python
ENV LOGFILE /var/log/test.log
ENV WORKING_DIR /app
ENV NONROOT_USERNAME dockeruser

# warning: this is hardcoded in run-cron.py
ENV CRONJOB_FILENAME cron-python

# set the working directory
WORKDIR ${WORKING_DIR}

# Set the time zone to US Eastern - hardcoded
# TODO: change to use whatever the host timezone/time is, may be tricky
# depending on the host OS
RUN echo "America/New_York" > /etc/timezone && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Install APT dependencies - Debian version, clean up APT cache afterward
    # software-properties-common=0.96.20.2-2.1   \
    # ffmpeg=7:4.3.5-0+deb11u1                   \

RUN apt-get update                                && \
    apt-get install -y --no-install-recommends \
    procps=2:3.3.17-5                          \
    cron=3.0pl1-137                            \
    python3=3.9.2-3                            \
    python-is-python3=3.9.2-1                  \
    vim=2:8.2.2434-3+deb11u1                   \
    curl=7.74.0-1.3+deb11u7                    \
    screen=4.8.0-6                             \
    python3-pip=20.3.4-4+deb11u1                  && \
    apt-get clean -y && apt-get autoclean -y      && \
    apt-get autoremove -y                         && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# DON'T REMOVE THIS IN CASE IT CAUSES AN ISSUE
# RUN apt-get purge -y software-properties-common

# Create non-root user
# Debian version:
RUN useradd -ms /bin/bash ${NONROOT_USERNAME}

# set ownership of directories and files before copying new ones over
RUN touch ${LOGFILE} && \
    chmod 777 ${LOGFILE} && \
    chown -R ${NONROOT_USERNAME} ${WORKING_DIR} ${LOGFILE}

# Copy over files and set permissions
# using *.env to avoid errors since the '.env' file may or may not exist
COPY --chown=${NONROOT_USERNAME} --chmod=0744 ["*.txt", "*.env", "*.py", "*.sh", "${WORKING_DIR}/"]

# Install pip dependencies
RUN pip3 install --no-cache-dir --no-cache --upgrade -r requirements.txt

# install the crontab
# mark log as global writable, install crontab for user
COPY --chown=root       --chmod=0644 ["${CRONJOB_FILENAME}", "/etc/cron.d/"]
RUN /usr/bin/crontab -u ${NONROOT_USERNAME} /etc/cron.d/${CRONJOB_FILENAME}

# start the cron service
# cannot use environment variables with CMD command
# must be hardcoded, or probably a complex workaround that's not worth it
# right now
CMD ["/app/run-cron.py"]
