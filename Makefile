.PHONY: all
all: mecab dictionaries

.PHONY: mecab
mecab:
	@download_mecab.sh

.PHONY: dictionaries
dictionaries: unidic

.PHONY: unidic
unidic:
	@download_unidic.sh
	@cd unidic && make dictionary
