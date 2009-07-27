SOURCE_DIR=/home/artemis/perl510/lib/site_perl/5.10.0/Artemis/
DEST_DIR=/opt/artemis/lib/perl5/site_perl/5.10.0/Artemis/


live:
	./scripts/dist_upload_wotan.sh
	ssh artemis@bancroft "sudo rsync -ruv  ${SOURCE_DIR}/CLI.pm ${DEST_DIR}; sudo rsync -ruv  ${SOURCE_DIR}/CLI/ ${DEST_DIR}/CLI/"
	ssh artemis@bancroft "sudo rsync -ruv  /home/artemis/perl510/bin/artemis-* /opt/artemis/bin/"
devel:
	perl Build.PL
	./Build install