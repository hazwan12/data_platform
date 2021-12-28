docker run --rm \
    -p 8080:8080 \
    --net=data_platform_network \
    --name trino \
    data_platform/trino:latest