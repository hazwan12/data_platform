FROM openjdk:11-jre-slim

WORKDIR /opt

RUN apt-get update && apt-get install -y wget procps python3 \
&& wget https://repo1.maven.org/maven2/io/trino/trino-server/367/trino-server-367.tar.gz -P /opt \
&& tar -xf trino-server-367.tar.gz \
&& ln -s trino-server-367 trino \
&& rm trino-server-367.tar.gz \
&& ln -sf /usr/bin/python3 /usr/bin/python

COPY ./etc ./trino/etc
COPY ./alluxio-2.7.1-client.jar ./trino/plugin/hive
COPY ./trino /bin/

ENV TRINO_HOME=/opt/trino
ENV PATH=${TRINO_HOME}/bin:${PATH}

CMD ["launcher", "run"]