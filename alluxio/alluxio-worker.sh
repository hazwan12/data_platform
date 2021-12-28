docker run --rm \
    -p 29999:29999 \
    -p 30000:30000 \
    --net=data_platform_network \
    --name=alluxio-worker \
    --shm-size=1G \
    -e ALLUXIO_JAVA_OPTS=" \
       -Dalluxio.worker.ramdisk.size=1G \
       -Dalluxio.master.hostname=alluxio-master \
       -Dalluxio.worker.hostname=alluxio-worker" \
    data_platform/alluxio:latest worker