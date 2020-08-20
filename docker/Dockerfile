FROM ubuntu:latest
MAINTAINER Gregor Jehle <gregor@p3ki.com>


RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y rng-tools openssl

ADD run.sh /mmc/

WORKDIR /mmc
ENTRYPOINT /bin/bash
