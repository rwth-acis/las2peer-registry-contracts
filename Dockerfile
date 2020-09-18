FROM openjdk:11-slim

WORKDIR /build

RUN set -eux; \
	apt-get update; \
	apt-get install -y \
		build-essential \
		curl \
		;

ADD https://get.epirus.io/ /build/install-epirus.sh
RUN set -eux; \
	chmod +x install-epirus.sh; \
	./install-epirus.sh;

ENV PATH $PATH:/root/.epirus

CMD set -eux; \
	ls build/contracts/*.json | xargs -L1 epirus truffle generate -o build/java -p i5.las2peer.registry.contracts -t
