#!/usr/bin/env bash

# check sed
gsed=$(which gsed)
psed=$(which sed)
if [[ "${gsed}" != "" ]]; then
    sed="${gsed}"
elif [[ "${psed}" != "" ]]; then
    sed="${psed}"
else
    echo "sed is not installed"
    exit 1
fi

set -eu

# function to download and extract IPA Dictionary
function download_ipadic () {
    fname="ipadic-2.7.0-20070801.tar.gz"
    dname=${fname%.*.*}
    version=${dname#*-}
    url="https://sourceforge.net/projects/mecab/files/mecab-${fname}/download"
    bin_fname="ipadic-2.7.0-20070801.model.bz2"
    ebin_fname=${bin_fname%.*}
    bin_url="https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7bnc5aFZSTE9qNnM"
    if [[ ! -f ${fname} ]]; then
        echo "get the latest version of IPA Dictionary"
        wget -O ${fname} ${url}
    fi
    if [[ ! -f ${bin_fname} ]]; then
        echo "get the latest version of IPA Dictionary (pretrained binary)"
        wget -O ${bin_fname} ${bin_url}
    fi
    if [[ ! -d ${dname} ]]; then
        echo "unzip ${fname} and convert encodings"
        # extract
        tar zxf ${fname}
        mv "mecab-${dname}" ${dname}
        cp ${bin_fname} model.def.bz2
        bunzip2 model.def.bz2
        # convert encodings (EUC-JP -> UTF-8)
        nkf -Ew --overwrite ${dname}/*
        nkf -Ew --overwrite model.def
        ${sed} -i -e "s/euc-jp/UTF-8/" model.def
        mv model.def ${dname}/model.def
    fi
    echo "remove old sources of ipadic"
    if [[ -d "ipadic/src-ipadic" ]]; then
        rm -rf ipadic/src-ipadic
        mkdir ipadic/src-ipadic
    fi
    if [[ -d "ipadic/src-ipadic-neologd" ]]; then
        rm -rf ipadic/src-ipadic-neologd
        mkdir ipadic/src-ipadic-neologd
    fi
    echo "copy sources of ipadic"
    cp -R ${dname}/ ipadic/src-ipadic/
    cp -R ${dname}/ ipadic/src-ipadic-neologd/
    echo "set the version of ipadic"
    echo "${version}" > ipadic/version-ipadic
}

function download_ipadic_neologd () {
    neologd_dir="ipadic/mecab-ipadic-neologd"
    neologd_vfname="ipadic/version-ipadic-neologd"
    neologd_repo="https://github.com/neologd/mecab-ipadic-neologd.git"
    if [[ ! -d ${neologd_dir} ]]; then
        echo "clone mecab-ipadic-neologd"
        git clone --depth 1 ${neologd_repo} ${neologd_dir}
    fi
    echo "set the version of mecab-unidic-neologd"
    cd ${neologd_dir} >/dev/null 2>&1
    version=$(git show --format='%h' --no-patch)
    cd - >/dev/null 2>&1
    echo "${version}" > ${neologd_vfname}
}

# create user dictionary
function create_user_dictionary () {
    if [[ -f "userdic.jsonl" ]]; then
        python3 convert_userdic.py ipadic
    fi
}

# main
download_ipadic
download_ipadic_neologd
create_user_dictionary
