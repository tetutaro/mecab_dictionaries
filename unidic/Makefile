.PHONY: dictionaries
dictionaries:
	@make_dictionary.sh

.PHONY: cwj
cwj:
	@make_dictionary.sh cwj

.PHONY: cwj-neologd
cwj-neologd:
	@make_dictionary.sh cwj-neologd

.PHONY: csj
csj:
	@make_dictionary.sh csj

.PHONY: csj-neologd
csj-neologd:
	@make_dictionary.sh csj-neologd

.PHONY: clean
clean:
	@rm -rf unidic-cwj/dist
	@rm -f  unidic-cwj/unidic_cwj/__version__.py
	@rm -rf unidic-cwj/unidic_cwj/dic
	@rm -rf unidic-cwj-neologd/dist
	@rm -f  unidic-cwj-neologd/unidic_cwj_neologd/__version__.py
	@rm -rf unidic-cwj-neologd/unidic_cwj_neologd/dic
	@rm -rf unidic-csj/dist
	@rm -f  unidic-csj/unidic_csj/__version__.py
	@rm -rf unidic-csj/unidic_csj/dic
	@rm -rf unidic-csj-neologd/dist
	@rm -f  unidic-csj-neologd/unidic_csj_neologd/__version__.py
	@rm -rf unidic-csj-neologd/unidic_csj_neologd/dic
	@rm -rf temp
	@rm -rf neologd
