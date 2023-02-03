# mecab_dictionaries

Create Python packages of various MeCab dictionaries.

To analyze morphemes in Japanese sentences (split a sentence into words),
you use [MeCab](https://taku910.github.io/mecab/) analyzer
([fugashi](https://github.com/polm/fugashi),
[mecab-python3](https://github.com/SamuraiT/mecab-python3) in Python).

The Python packages created by scripts in this repository
can use as the dictionary of MeCab to detect words in Japanese sentences.

To use them, the thing you have to do is just importing the Python package
you created with scripts in this repository.

**WARNING** : Each MeCab dictionary has its own LICENSE.
You have to check them and use them **AT YOUR OWN RISK**.

This repository contains only scripts
to create Python packages of MeCab dictionaries.
No resources (dictionary data, MeCab library, ...) is contained.

## Requirements

Following libraries, commands and apps are needed to create packages.

* Libraries (Languages)
    * gcc (g++), Python3
* Commands
    * patch, make, wget, git, zip (unzip), bzip2 (unbzip2), xz (unxz), nkf (convertor of charactor encodings), sed (GNU version)
* Applications
    * [poetry](https://python-poetry.org/)

## How to create Python packages

Invoke `make dictionaries` on your terminal. That's all.

## Features

* contains scripts to download all needed resources
    * Thanks for great developers
        * MeCab library, IPA dictionary for MeCab, JUMAN dictionary for MeCab
            * Taku Kudo
        * UniDic dictionaries
            * [NINJAL](https://clrd.ninjal.ac.jp/unidic/)
        * NEologd dictionaries
            * [NEologd Project](https://github.com/neologd)
    * There is no guarantee that these resources will be available
* create various dictionaries at once
    * UniDic-cwj
        * `unidic/unidic-cwj/dist/unidic_cwj-XXX.whl`
    * UniDic-cwj + mecab-unidic-neologd
        * `unidic/unidic-cwj-neologd/dist/unidic_cwj_neologd-XXX.whl`
    * UniDic-csj
        * `unidic/unidic-csj/dist/unidic_csj-XXX.whl`
    * UniDic-csj + mecab-unidic-neologd
        * `unidic/unidic-csj-neologd/dist/unidic_csj_neologd-XXX.whl`
    * IPA dictionary
        * `ipadic/ipadic/dist/ipadic-XXX.whl`
    * IPA dictionary + mecab-ipadic-neologd
        * `ipadic/ipadic-neologd/dist/ipadic_neologd-XXX.whl`
    * JUMAN dictionary
        * `jumandic/jumandic/dist/jumandic-XXX.whl`
* add an original patch to MeCab library
    * to avild [this problem](https://stackoverflow.com/questions/66299029/how-does-one-determine-what-the-left-and-right-context-ids-should-be-when-buildi)
* you can add your own dictionary (definitions of words) to every dictionaries
    * by just creating `userdic.jsonl`
    * sample of `userdic.jsonl` is [sample_userdic.jsonl](sample_userdic.jsonl)
* MeCab returns information of each word with JSON format (by default)
    * to parse results easily
* information of each word contains the dictionary name that the word comes from
    * to grasp easily the word is UNK (unknown word) or not
* contains simple MeCab CLI ([mecab-cli](mecab-cli))
    * as the sample usage of dictionaries my scripts builds
    * using fugashi and [neologdn](https://github.com/ikegami-yukino/neologdn)
    * Thanks for awesome developers
        * fugashi
            * [Paul O'Leary McCann](https://github.com/polm)
        * neologdn
            * [Yikino Igarashi](https://github.com/ikegami-yukino)
    * you can run this CLI without installing MeCab

Enjoy!
