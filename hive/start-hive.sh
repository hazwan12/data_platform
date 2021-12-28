docker run --rm \
    -p 9083:9083 \
    --net=data_platform_network \
    --name=hive \
    data_platform/hive:latest