FROM mcr.microsoft.com/vscode/devcontainers/python

ENV DEBIAN_FRONTEND=noninteractive
RUN echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/90assumeyes

# INSTALL DVC
ARG DVC_VERSION=2
RUN cd /etc/apt/sources.list.d \
 && wget https://dvc.org/deb/dvc.list \
 && apt-get update \
 && apt-get install --yes "dvc=${DVC_VERSION}.*" \
 && apt-get clean \
 && rm --recursive --force /var/lib/apt/lists/*


