#!/usr/bin/env bash

echo "Loading container"
for container in $(find /srv -name "*.tar" -type f);
do
	echo "Loading $container ..."
	docker load -i "$container"
done
