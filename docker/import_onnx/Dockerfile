FROM oraclelinux:9

RUN dnf upgrade -y && dnf install -y \
    python3.12 \
    python3.12-pip \
    python3.12-devel \
    perl-File-Copy \
    gcc \
    gcc-c++ \
    make \
    git \
    unzip \
    wget \
    curl \
    vim \
    perl-Env \
    libaio \
    libffi-devel \
    openssl \
    openssl-devel \
    tk-devel \
    xz-devel \
    zlib-devel \
    bzip2-devel \
    readline-devel \
    libuuid-devel \
    ncurses-devel \
    && dnf clean all

SHELL [ "/usr/bin/bash", "-c"]

RUN mkdir /opt/build
WORKDIR /opt/build

COPY ./src/oml4py-client-linux-x86*.zip /opt/build/oml4py-client-linux-x86.zip
COPY ./src/requirements.txt /opt/build/requirements.txt

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN unzip /opt/build/oml4py-client-linux-x86.zip -d /opt/build/ && \
    pipenv run pip install --no-cache-dir -r /opt/build/requirements.txt && \
    pipenv run perl -Iclient client/client.pl -y

RUN rm -rf /opt/build/.cache /opt/build/__pycache__
RUN rm /opt/build/oml4py-client-linux-x86.zip

RUN mkdir /opt/build/shared
VOLUME /opt/build/shared

COPY ./src/*.py /opt/build/

ENTRYPOINT /bin/bash

