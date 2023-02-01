.PHONY: dictionaries
dictionaries:
	@make_dictionary.sh

.PHONY: cwj
cwj:
	@make_dictionary cwj

.PHONY: cwj-neologd
cwj-neologd:
	@make_dictionary cwj-neologd

.PHONY: csj
csj:
	@make_dictionary csj

.PHONY: csj-neologd
csj-neologd:
	@make_dictionary csj-neologd

.PHONY: clean
clean:
	@rm -rf unidic-cwj/dist
	@rm -rf unidic-cwj/unidic_cwj/dic
	@rm -rf unidic-cwj-neologd/dist
	@rm -rf unidic-cwj-neologd/unidic_cwj_neologd/dic
	@rm -rf unidic-csj/dist
	@rm -rf unidic-csj/unidic_csj/dic
	@rm -rf unidic-csj-neologd/dist
	@rm -rf unidic-csj-neologd/unidic_csj_neologd/dic
	@rm -rf temp
	@rm -rf neologd
