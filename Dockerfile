FROM ubuntu:16.04
RUN apt update && \
    apt install -y openjdk-8-jdk


MAINTAINER "Rishab Banerjee<loccapollo@gmail.conm>"

# scala installation
ENV SCALA_VERSION="2.12.8" \
    SBT_VERSION="1.2.8" \
    SCALA_HOME="/usr/share/scala" \
    SBT_HOME="/usr/share/sbt"
RUN apt update && apt install -y wget ca-certificates && \
    cd "/tmp" && \
    wget "https://downloads.typesafe.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz" && \
    tar xzf "scala-${SCALA_VERSION}.tgz" && \
    mkdir "${SCALA_HOME}" && \
    rm "/tmp/scala-${SCALA_VERSION}/bin/"*.bat && \
    mv "/tmp/scala-${SCALA_VERSION}/bin" "/tmp/scala-${SCALA_VERSION}/lib" "${SCALA_HOME}" && \
    ln -s "${SCALA_HOME}/bin/"* "/usr/bin/" && \
    apt autoremove && \
    rm -rf "/tmp/"*


# tools installation, should be at LAST, to keep build time minimal
RUN apt update && apt install -y \
    curl \
    vim \
    openssh-client \
    openssh-server

# install hadoop
ENV HADOOP_VERSION="3.2.0"
RUN cd "/tmp" && \
    wget "http://us.mirrors.quenda.co/apache/hadoop/common/stable/hadoop-${HADOOP_VERSION}.tar.gz"
ENV HADOOP_CONF_DIR="/etc/hadoop" \
    MULTIHOMED_NETWORK=1 \
    USER=root \
    HADOOP_HOME="/opt/hadoop-${HADOOP_VERSION}"
# don't combine the bottom 2 lines as HADOOP_VERSION value wont be available till all the above lines are completed
ENV PATH="${HADOOP_HOME}/bin/:${PATH}" \
    LD_LIBRARY_PATH="${HADOOP_HOME}/lib/native/:${LD_LIBRARY_PATH}"
RUN cd "/tmp" && \
    tar xzf "hadoop-${HADOOP_VERSION}.tar.gz" && \
    mkdir -p "/opt" && \
    mv "/tmp/hadoop-${HADOOP_VERSION}" "/opt/" && \
    rm -rf "/tmp/*" && \
    ln -s "/opt/hadoop-${HADOOP_VERSION}/etc/hadoop" "/etc/hadoop" && \
    cp "/etc/hadoop/mapred-queues.xml.template" "/etc/hadoop/mapred-queues.xml" && \
    mkdir "/opt/hadoop-${HADOOP_VERSION}/logs" && \
    mkdir "/hadoop-data"

# install spark
ENV SPARK_VERSION="2.4.0"
RUN cd "/tmp" && \
    wget "http://mirrors.ibiblio.org/apache/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz"
ENV PATH="/usr/local/spark-${SPARK_VERSION}-bin-hadoop2.7/bin/:${PATH}"
RUN cd "/tmp" && \
    tar xzf "spark-${SPARK_VERSION}-bin-hadoop2.7.tgz" && \
    mv "spark-${SPARK_VERSION}-bin-hadoop2.7" "/usr/local" && \
    cd "/usr/local/spark-${SPARK_VERSION}-bin-hadoop2.7/" && \
    cp "conf/spark-defaults.conf.template" "conf/spark-defaults.conf" && \
    cp "conf/spark-env.sh.template" "conf/spark-env.sh" && \
#    echo "export SPARK_WORKER_MEMORY=1g" >> "conf/spark-env.sh" && \
#    echo "export SPARK_WORKER_DIR=/hadoop-data" >> "conf/spark-env.sh" && \
    rm -rf "/tmp/*" && \
    mkdir "/spark-data"
#    bash "sbin/start-all.sh" && \
#    bash "jps"

# set JAVA_HOME, currently done manually
# sed -i.bak s/# JAVA_HOME/JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64//g  etc/hadoop/hadoop-env.sh

# password-less ssh
RUN apt install -y apt-utils ssh && \
    ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

# fix java home
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/hadoop/hadoop-env.sh
ENV HDFS_NAMENODE_USER="root" \
    HDFS_DATANODE_USER="root" \
    HDFS_SECONDARYNAMENODE_USER="root" \
    YARN_RESOURCEMANAGER_USER="root" \
    YARN_NODEMANAGER_USER="root"

# ENTRYPOINT vs CMD: https://www.youtube.com/watch?v=OYbEWUbmk90
# ENTRYPOINT ["/hadoop-data/./setupHadoop.sh"]