FROM debian:12-slim

SHELL [ "/usr/bin/bash", "-c"]

RUN mkdir /app
WORKDIR /app

COPY requirements.txt /app

RUN apt-get update && apt-get upgrade && \
        apt-get install -y python3.11 python3.11-venv

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --no-cache-dir -r requirements.txt

RUN wget https://download.oracle.com/otn_software/linux/instantclient/2340000/instantclient-basic-linux.x64-23.4.0.24.05.zip && \
       unzip instantclient-basic-linux.x64-*

ENV OPENAI_API_KEY=""
ENV ADB_CS=""
ENV ADB_USERNAME=""
ENV ADB_PASSWORD=""

EXPOSE 3000/udp
EXPOSE 3000/tcp

RUN rm -rf /app/.cache /app/__pycache__

COPY src/ /app

#entrypoint /bin/bash

ENTRYPOINT ["chainlit", "run", "app.py", "--port", "3000"]