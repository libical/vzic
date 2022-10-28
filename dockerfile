# escape=`

FROM ubuntu

RUN apt-get update

# build tools
RUN apt-get -y install make
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install pkg-config
RUN apt-get -y install build-essential
RUN apt-get -y install libglib2.0-dev

# wget used to download tzdata and previous zoneinfo
RUN apt-get -y install wget

# perl used to merge new zoneinfo with previous version
RUN apt-get -y install perl
