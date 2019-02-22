FROM openjdk:jre-alpine

MAINTAINER "Rishab Banerjee<loccapollo@gmail.con>"


# scala installation
ENV SCALA_VERSION="2.12.8" \
    SBT_VERSION="1.2.8" \
    SCALA_HOME="/usr/share/scala" \
    SBT_HOME="/usr/share/sbt"
RUN apk update && apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
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
RUN apk update && apk add --no-cache --virtual=.build-dependencies \
    curl \
    vim \
    openssh

# install hadoop
RUN cd "/tmp" && \
#    wget "http://us.mirrors.quenda.co/apache/hadoop/common/stable/hadoop-${HADOOP_VERSION}.tar.gz"
    wget "http://us.mirrors.quenda.co/apache/hadoop/common/stable/hadoop-3.2.0.tar.gz"
ENV HADOOP_VERSION="3.2.0" \
#    HADOOP_HOME="/opt/hadoop-${HADOOP_VERSION}" \
    HADOOP_HOME="/opt/hadoop-3.2.0" \
    HADOOP_CONF_DIR="/etc/hadoop" \
    MULTIHOMED_NETWORK=1 \
    USER=root
ENV PATH="${HADOOP_HOME}/bin/:${PATH}"
RUN echo $HADOOP_HOME
RUN cd "/tmp" && \
    tar xzf "hadoop-${HADOOP_VERSION}.tar.gz" && \
    mkdir "/opt" && \
    mv "/tmp/hadoop-${HADOOP_VERSION}" "/opt/" && \
    rm -rf "/tmp/" && \
    ln -s "/opt/hadoop-${HADOOP_VERSION}/etc/hadoop" "/etc/hadoop" && \
    cp "/etc/hadoop/mapred-queues.xml.template" "/etc/hadoop/mapred-queues.xml" && \
    mkdir "/opt/hadoop-${HADOOP_VERSION}/logs" && \
    mkdir "/hadoop-data"

# install spark
