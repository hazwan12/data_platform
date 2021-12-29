FROM openjdk:11-jre-slim

WORKDIR /opt

RUN apt-get update && apt-get install -y wget python3 python3-pip \
&& wget https://dlcdn.apache.org/spark/spark-3.2.0/spark-3.2.0-bin-hadoop3.2.tgz -P /opt \
&& tar -xf spark-3.2.0-bin-hadoop3.2.tgz \
&& ln -s spark-3.2.0-bin-hadoop3.2 spark \
&& rm spark-3.2.0-bin-hadoop3.2.tgz \
&& pip3 install pip --upgrade \
&& pip3 install numpy pandas

ENV SPARK_HOME=/opt/spark
ENV PATH=${SPARK_HOME}/bin:${PATH}
ENV PYTHONPATH=${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-0.10.9.2-src.zip:${PYTHONPATH}

COPY ./jars ${SPARK_HOME}/jars/
