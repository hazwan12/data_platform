FROM openjdk:8-jre-slim

WORKDIR /opt

RUN apt-get update && apt-get install -y wget procps \
&& wget https://dlcdn.apache.org/hive/hive-2.3.9/apache-hive-2.3.9-bin.tar.gz -P /opt \
&& tar -xf apache-hive-2.3.9-bin.tar.gz \
&& ln -s apache-hive-2.3.9-bin hive \
&& rm apache-hive-2.3.9-bin.tar.gz \
&& wget https://dlcdn.apache.org/hadoop/common/hadoop-2.10.1/hadoop-2.10.1.tar.gz -P /opt \
&& tar -xf hadoop-2.10.1.tar.gz \
&& ln -s hadoop-2.10.1 hadoop \
&& rm hadoop-2.10.1.tar.gz

COPY ./conf/* ./hive/conf/
COPY ./alluxio-2.7.1-client.jar ./alluxio/client/
COPY ./run.sh ./

ENV ALLUXIO_HOME=/opt/alluxio
ENV HIVE_HOME=/opt/hive
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=${ALLUXIO_HOME}/bin:${HIVE_HOME}/bin:${PATH}

RUN mkdir -p ${HIVE_HOME}/hcatalog/sbin/../var/log/

CMD ["/bin/bash", "run.sh"]