
DOCKER_IMAGE_NAME ?= adoc-po4a
ASCIIDOCTOR_BASE_FILENAME ?= index
ASCIIDOCTOR_BASE_FILE_PATH ?= $(ASCIIDOCTOR_BASE_FILENAME).adoc
TRANSLATION_DIR ?= ./po
TRANSLATION_TEMPLATE_FILE_PATH ?= $(TRANSLATION_DIR)/$(ASCIIDOCTOR_BASE_FILENAME).pot

build: build-docker translate build-doc

build-docker:
	docker build -t "${DOCKER_IMAGE_NAME}" ./docker-po4a/

init-translation-template:
	docker run --rm -t -v "$(CURDIR)/samples:/docs" "${DOCKER_IMAGE_NAME}" \
		po4a-gettextize -f asciidoc -M utf-8 \
		-m "./$(ASCIIDOCTOR_BASE_FILE_PATH)" \
		-p "$(TRANSLATION_TEMPLATE_FILE_PATH)"

create-translation:
	@[ -n "$(LANGUAGE)" ] || (echo "Please set the variable LANGUAGE" && exit 1) \
		&& docker run --rm -t -v "$(CURDIR)/samples:/docs" "${DOCKER_IMAGE_NAME}" \
			cp "$(TRANSLATION_TEMPLATE_FILE_PATH)" "$(TRANSLATION_DIR)/$(LANGUAGE).po" \
		&& docker run --rm -t -v "$(CURDIR)/samples:/docs" "${DOCKER_IMAGE_NAME}" \
			mkdir -p "./images/$(LANGUAGE)"

update-translation:
	@[ -n "$(LANGUAGE)" ] || (echo "Please set the variable LANGUAGE" && exit 1) \
		&& docker run --rm -t -v "$(CURDIR)/samples:/docs" "${DOCKER_IMAGE_NAME}" \
			po4a-updatepo -f asciidoc -m "./$(ASCIIDOCTOR_BASE_FILE_PATH)" \
			-p "$(TRANSLATION_DIR)/$(LANGUAGE).po"

translate:
	@[ -n "$(LANGUAGE)" ] || (echo "Please set the variable LANGUAGE" && exit 1) \
		&& docker run --rm -t -v "$(CURDIR)/samples:/docs" "${DOCKER_IMAGE_NAME}" \
			po4a-translate -f asciidoc -M utf-8 -m "./$(ASCIIDOCTOR_BASE_FILE_PATH)" \
			-p "$(TRANSLATION_DIR)/$(LANGUAGE).po" -k 0 \
			-l "./$(ASCIIDOCTOR_BASE_FILENAME)_$(LANGUAGE).adoc"

build-doc:
	@[ -n "$(LANGUAGE)" ] || (echo "Please set the variable LANGUAGE" && exit 1) \
		&& docker run --rm -t -v "$(CURDIR)/samples:/docs" "${DOCKER_IMAGE_NAME}" \
			asciidoctor -a lang=$(LANGUAGE) "./$(ASCIIDOCTOR_BASE_FILENAME)_$(LANGUAGE).adoc"

.PHONY: all build-docker init-translation-template init-translation \
		update-translation translate build-doc
