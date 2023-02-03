.PHONY: all
all: dictionaries cli

.PHONY: dictionaries
dictionaries: unidic ipadic jumandic

.PHONY: mecab
mecab:
	@download_mecab.sh

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

.PHONY: ipadic
ipadic: mecab
	@download_ipadic.sh
	@cd ipadic && make dictionaries

.PHONY: ipadic-only
ipadic-only: mecab
	@download_ipadic.sh
	@cd ipadic && make ipadic

.PHONY: ipadic-neologd
ipadic-neologd: mecab
	@download_ipadic.sh
	@cd ipadic && make ipadic-neologd

.PHONY: jumandic
jumandic: mecab
	@download_jumandic.sh
	@cd jumandic && make dictionary

.PHONY: cli
cli:
	@cd mecab-cli && poetry build

.PHONY: build-package
build-package:
	@cd unidic/unidic-cwj/ && poetry build
	@cd unidic/unidic-cwj-neologd/ && poetry build
	@cd unidic/unidic-csj/ && poetry build
	@cd unidic/unidic-csj-neologd/ && poetry build
	@cd ipadic/ipadic/ && poetry build
	@cd ipadic/ipadic-neologd/ && poetry build
	@cd jumandic/jumandic/ && poetry build

.PHONY: reflect-dicrc
reflect-dicrc:
	@cp -f unidic/dicrc unidic/unidic-cwj/unidic_cwj/dic/.
	@cp -f unidic/dicrc unidic/unidic-cwj-neologd/unidic_cwj_neologd/dic/.
	@cp -f unidic/dicrc unidic/unidic-csj/unidic_csj/dic/.
	@cp -f unidic/dicrc unidic/unidic-csj-neologd/unidic_csj_neologd/dic/.
	@cp -f ipadic/dicrc ipadic/ipadic/ipadic/dic/.
	@cp -f ipadic/dicrc ipadic/ipadic-neologd/ipadic_neologd/dic/.
	@cp -f jumandic/dicrc jumandic/jumandic/jumandic/dic/.

.PHONY: install-dictionaries-local
install-dictionaries-local:
	pip install unidic/unidic-cwj/dist/unidic_cwj-*.whl
	pip install unidic/unidic-cwj-neologd/dist/unidic_cwj_neologd-*.whl
	pip install unidic/unidic-csj/dist/unidic_csj-*.whl
	pip install unidic/unidic-csj-neologd/dist/unidic_csj_neologd-*.whl
	pip install ipadic/ipadic/dist/ipadic-*.whl
	pip install ipadic/ipadic-neologd/dist/ipadic_neologd-*.whl
	pip install jumandic/jumandic/dist/jumandic-*.whl

.PHONY: uninstall-dictionaries-local
uninstall-dictionaries-local:
	pip uninstall -y unidic-cwj unidic-cwj-neologd unidic-csj unidic-csj-neologd ipadic ipadic-neologd jumandic

.PHONY: install-pipx
install-pipx:
	pipx install mecab-cli/dist/mecab_cli-*.whl
	pipx inject mecab-cli unidic/unidic-cwj/dist/unidic_cwj-*.whl
	pipx inject mecab-cli unidic/unidic-cwj-neologd/dist/unidic_cwj_neologd-*.whl
	pipx inject mecab-cli unidic/unidic-csj/dist/unidic_csj-*.whl
	pipx inject mecab-cli unidic/unidic-csj-neologd/dist/unidic_csj_neologd-*.whl
	pipx inject mecab-cli ipadic/ipadic/dist/ipadic-*.whl
	pipx inject mecab-cli ipadic/ipadic-neologd/dist/ipadic_neologd-*.whl
	pipx inject mecab-cli jumandic/jumandic/dist/jumandic-*.whl

.PHONY: uninstall-pipx
uninstall-pipx:
	pipx uninstall mecab-cli

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
	@cd ipadic && make clean
	@cd jumandic && make clean
	@rm -rf mecab-0.996
	@rm -f unidic/user.csv
	@rm -rf unidic/version-unidic-cwj
	@rm -rf unidic/version-unidic-csj
	@rm -rf unidic/version-unidic-neologd
	@rm -rf unidic/src-unidic-cwj
	@rm -rf unidic/src-unidic-cwj-neologd
	@rm -rf unidic/src-unidic-crj
	@rm -rf unidic/src-unidic-crj-neologd
	@rm -rf unidic-cwj-*-full
	@rm -rf unidic-csj-*-full

.PHONY: clean-system
clean-system:
	@find . -name '*~' -exec rm -f {} +
	@find . -name '.DS_Store' -exec rm -f {} +
