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

RUN mkdir /opt/build
WORKDIR /opt/build

COPY ./src/oml4py-client-linux-x86*.zip /opt/build/oml4py-client-linux-x86.zip
COPY ./src/requirements.txt /opt/build/requirements.txt

RUN unzip /opt/build/oml4py-client-linux-x86.zip -d /opt/build/ && \
    pip3.12 install pipenv && pipenv --python 3.12 && \
    pipenv run pip3.12 install -r /opt/build/requirements.txt && \
    pipenv run perl -Iclient client/client.pl -y

RUN mkdir /opt/build/shared
VOLUME /opt/build/shared

COPY ./src/*.py /opt/build/

RUN echo "source /root/.local/share/virtualenvs/build-*/bin/activate" >> /root/.bashrc

ENTRYPOINT /bin/bash

