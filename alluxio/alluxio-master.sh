docker run --rm \
    -p 19999:19999 \
    -p 19998:19998 \
    --net=data_platform_network \
    --name=alluxio-master \
    -e ALLUXIO_JAVA_OPTS=" \
       -Dalluxio.master.hostname=alluxio-master \
       -Dalluxio.master.mount.table.root.ufs=/opt/alluxio/underFSStorage \
       -Dalluxio.security.authorization.permission.enabled=false" \
    data_platform/alluxio:latest master