.DEFAULT_GOAL := run

FDSIFY := ./scripts/fdsify.sh

USER_1 := spotify1
USER_2 := spotify2
USERS := ${USER_1} ${USER_2}

clean:
	${FDSIFY} -cRS ${USERS}
.PHONY: clean

run:
	${FDSIFY} ${USERS}
.PHONY: run

run-clean:
	${FDSIFY} -c ${USERS}
.PHONY: run-clean

setup:
	${FDSIFY} -R ${USERS}
.PHONY: setup

