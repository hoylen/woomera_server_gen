# Makefile

WORKING_REFERENCE=lib/src/server-expected.txt
GENERATED_FILE=lib/src/server.dart

# UTILITY=dev/gen_server.dart
UTILITY=../example.dart

help:
	@echo "Targets:"
	@echo
	@echo "Run utility to show info:"
	@echo "  summary        show summary of annotations"
	@echo "  details        show details of annotations"
	@echo
	@echo "Run utility to generate Dart into ${GENERATED_FILE}:"
	@echo "  gen-server     generate Dart file from annotations"
	@echo "  show-server    show the generated file"
	@echo "  check-server   compare generated Dart to the expected result*"
	@echo "  repair-server  restore expected result* over generated Dart"
	@echo
	@echo "* The expected result can be found in ${WORKING_REFERENCE}."
	@echo

summary:
	${UTILITY} --format summary --verbose

details:
	${UTILITY} --format details

gen-server:
	${UTILITY} --format dart --output ${GENERATED_FILE}

show-server:
	cat ${GENERATED_FILE}

check-server:
	diff ${WORKING_REFERENCE} ${GENERATED_FILE}
	@echo
	dart analyze

repair-server:
	cp ${WORKING_REFERENCE} ${GENERATED_FILE}
