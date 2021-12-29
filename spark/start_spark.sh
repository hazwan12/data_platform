docker run --rm -it \
    -p 4040:4040 \
    --net=data_platform_network \
    --name=spark \
    data_platform/spark:latest pyspark --master local[1]