#!/usr/bin/env bash

mecab_tarball="mecab-0.996.tar.gz"
mecab_dir="mecab-0.996"
if [[ ! -f "${mecab_tarball}" ]]; then
    echo "download mecab"
    wget -O ${mecab_tarball} "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE"
else
    echo "${mecab_tarball} has already downloaded"
fi
if [[ ! -d "${mecab_dir}" ]]; then
    echo "unzip mecab"
    tar zxf ${mecab_tarball} >/dev/null 2>&1
else
    echo "mecab has already unzipped"
fi
if [[ ! -f "${mecab_dir}/src/dictionary.orig.cpp" ]]; then
    cp ${mecab_dir}/src/dictionary.cpp ${mecab_dir}/src/dictionary.orig.cpp
    patch < mecab.patch
fi
if [[ ! -x "${mecab_dir}/src/mecab-dict-index" ]]; then
    cd ${mecab_dir} >/dev/null 2>&1
    ./configure
    make
    cd - >/dev/null 2>&1
else
    echo "mecab has already compiled"
fi
