${HIVE_HOME}/bin/schematool -dbType derby -initSchema \
&& ${HIVE_HOME}/hcatalog/sbin/hcat_server.sh start \
&& tail -f ${HIVE_HOME}/hcatalog/sbin/../var/log/hcat.out