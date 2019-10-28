ETHERNET_INTERFACE=enp0s31f6

# Dump docker images
.PRECIOUS: images/rabbitmq-it490-rabbitmq.tar
images/rabbitmq-it490-rabbitmq.tar:
	docker save -o images/rabbitmq-it490-rabbitmq.tar it490/rabbitmq

.PRECIOUS: images/application-it490-gateway.tar
images/application-it490-gateway.tar:
	docker save -o images/application-it490-gateway.tar it490/gateway

.PRECIOUS: images/database-it490-app.tar
images/database-it490-app.tar:
	docker save -o images/database-it490-app.tar it490/app

.PRECIOUS: images/api-it490-imdbscraper.tar
images/api-it490-imdbscraper.tar:
	docker save -o images/api-it490-imdbscraper.tar it490/imdbscraper

.PRECIOUS: images/api-it490-weatherscraper.tar
images/api-it490-weatherscraper.tar:
	docker save -o images/api-it490-weatherscraper.tar it490/weatherscraper

.PRECIOUS: images/database-mariadb-10-4-8-bionic.tar
images/database-mariadb-10-4-8-bionic.tar:
	docker save -o images/database-mariadb-10-4-8-bionic.tar mariadb:10.4.8-bionic

# Build each os.
.PRECIOUS: servers/%/image.raw
servers/%/image.raw: images/database-mariadb-10-4-8-bionic.tar images/database-it490-app.tar images/application-it490-gateway.tar images/rabbitmq-it490-rabbitmq.tar images/api-it490-imdbscraper.tar images/api-it490-weatherscraper.tar
	# Copy in all source containers
	mkdir -p servers/$*/mkosi.extra/srv/containers/
	cp images/$*-*.tar servers/$*/mkosi.extra/srv/containers/
	# Build image
	sudo mkosi --force --directory servers/$*

# Create VM in virtualbox
.PHONY: %.vmdk
%.vmdk: servers/%/image.raw
	# Convert raw to vmdk
	qemu-img convert -f raw "$<" -O vmdk $@

	# Register in VirtualBox
	VBoxManage createvm --name vm-$* --ostype Ubuntu_64 --register
	VBoxManage modifyvm vm-$* --firmware efi
	VBoxManage modifyvm vm-$* --nic1 bridged --bridgeadapter1 "$ETHERNET_INTERFACE"
	VBoxManage modifyvm vm-$* --memory 1024
	VBoxManage storagectl vm-$* --name "SATA Controller" --add sata --controller IntelAhci
	VBoxManage storageattach vm-$* --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $*.vmdk

.PHONY: vms
vms: rabbitmq.vmdk database.vmdk application.vmdk api.vmdk
	echo "Configured all VMs"

# clean
.PHONY: clean
clean:
	rm images/*.tar || true
	rm *.vmdk       || true

	rm servers/rabbitmq/image.raw    || true
	rm servers/database/image.raw    || true
	rm servers/application/image.raw || true

	rm -r servers/application/mkosi.extra/srv/containers/  || true
	rm -r servers/database/mkosi.extra/srv/containers/     || true
	rm -r servers/application/mkosi.extra/srv/containers/  || true
	rm -r servers/api/mkosi.extra/srv/containers/          || true
	rm -r servers/rabbitmq/mkosi.extra/srv/containers/     || true

	VBoxManage unregistervm --delete vm-rabbitmq    || true
	VBoxManage unregistervm --delete vm-database    || true
	VBoxManage unregistervm --delete vm-application || true
	VBoxManage unregistervm --delete vm-api         || true

