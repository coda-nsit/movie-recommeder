#FROM alpine:3.5
#RUN apk update && apk add \
#    curl \
#    vim
#WORKDIR /opt/docker

#FROM openjdk:jre-alpine
#RUN apk update && apk add \
#    curl \
#    vim
#
#WORKDIR /opt/docker
#COPY opt /opt

#FROM openjdk:7
# COPY . /usr/src/myapp
# WORKDIR /usr/src/myapp
#RUN javac Main.java
#CMD ["java", "Main"]



#python
#java
#hadoop
#scala
#spark

#FROM hseeberger/scala-sbt



FROM openjdk:jre-alpine

MAINTAINER "Rishab Banerjee<loccapollo@gmail.con>"


# scala installation
ENV SCALA_VERSION="2.12.8" \
    SBT_VERSION="1.2.8" \
    SCALA_HOME="/usr/share/scala" \
    SBT_HOME="/usr/share/sbt"

RUN apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    apk add --no-cache bash && \
    cd "/tmp" && \
    wget "https://downloads.typesafe.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz" && \
    tar xzf "scala-${SCALA_VERSION}.tgz" && \
    mkdir "${SCALA_HOME}" && \
    rm "/tmp/scala-${SCALA_VERSION}/bin/"*.bat && \
    mv "/tmp/scala-${SCALA_VERSION}/bin" "/tmp/scala-${SCALA_VERSION}/lib" "${SCALA_HOME}" && \
    ln -s "${SCALA_HOME}/bin/"* "/usr/bin/" && \
    apk del .build-dependencies && \
    rm -rf "/tmp/"*

# tools installation, should be at LAST, to keep build time minimal
RUN apk update && apk add \
    curl \
    vim

# install hadoop
