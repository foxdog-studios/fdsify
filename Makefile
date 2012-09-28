.DEFAULT_GOAL := run

CREDS := config/credentials
FDSIFY := ./scripts/fdsify.sh

clean: ${CREDS}
	${FDSIFY} -cRS `cat ${CREDS}`
.PHONY: clean

run: ${CREDS}
	${FDSIFY} -d 1 `cat ${CREDS}`
.PHONY: run

setup: ${CREDS}
	${FDSIFY} -R `cat ${CREDS}`
.PHONY: setup

${CREDS}:
	./scripts/credentials.sh

