.PHONY: all
all: dictionaries

.PHONY: mecab
mecab:
	@download_mecab.sh

.PHONY: dictionaries
dictionaries: unidic

.PHONY: unidic
unidic: mecab
	@download_unidic.sh
	@cd unidic && make dictionaries

.PHONY: unidic-cwj
unidic-cwj: mecab
	@download_unidic.sh cwj
	@cd unidic && make cwj

.PHONY: unidic-cwj-neologd
unidic-cwj-neologd: mecab
	@download_unidic.sh cwj
	@cd unidic && make cwj-neologd

.PHONY: unidic-csj
unidic-csj: mecab
	@download_unidic.sh csj
	@cd unidic && make csj

.PHONY: unidic-csj-neologd
unidic-csj-neologd: mecab
	@download_unidic.sh csj
	@cd unidic && make csj-neologd

.PHONY: clean
clean: clean-python clean-dictionary clean-system

.PHONY: clean-python
clean-python:
	@find . -name '*.pyc' -exec rm -f {} +
	@find . -name '*.pyo' -exec rm -f {} +
	@find . -name '*.pyd' -exec rm -f {} +
	@find . -name '__pycache__' -exec rm -rf {} +

.PHONY: clean-dictonary
clean-dictionary:
	@cd unidic && make clean
	@rm -rf mecab-0.996
	@rm -f unidic/user.csv
	@rm -f unidic/version-unidic-cwj
	@rm -f unidic/version-unidic-csj
	@rm -f unidic/version-unidic-neologd
	@rm -f unidic/src-unidic-cwj
	@rm -f unidic/src-unidic-cwj-neologd
	@rm -f unidic/src-unidic-crj
	@rm -f unidic/src-unidic-crj-neologd
	@rm -rf unidic-cwj-*-full
	@rm -rf unidic-csj-*-full

.PHONY: clean-system
clean-system:
	@find . -name '*~' -exec rm -f {} +
	@find . -name '.DS_Store' -exec rm -f {} +
