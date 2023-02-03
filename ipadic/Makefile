.PHONY: dictionaries
dictionaries:
	@make_dictionary.sh

.PHONY: ipadic
ipadic:
	@make_dictionary.sh ipadic

.PHONY: ipadic-neologd
ipadic-neologd:
	@make_dictionary.sh ipadic-neologd

.PHONY: clean
clean:
	@rm -rf ipadic/dist/
	@rm -f  ipadic/ipadic/__version__.py
	@rm -rf ipadic/ipadic/dic/
	@rm -rf ipadic-neologd/dist/
	@rm -f  ipadic-neologd/ipadic_neologd/__version__.py
	@rm -rf ipadic-neologd/ipadic_neologd/dic/
	@rm -rf neologd/
