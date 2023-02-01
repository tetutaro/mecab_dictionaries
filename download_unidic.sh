#!/usr/bin/env bash

set -eu

# function to download and extract UniDic-{cwj,csj}
function download_unidic () {
    dic=$1
    echo "check the latest version of unidic-${dic}"
    url=$(python3 scrape_ninjal.py ${dic})
    fname=${url##*/}
    dname=${fname%.*}
    bname=${dname%-*}
    version=${bname##*-}
    if [[ ! -f ${fname} ]]; then
        echo "get the latest version of unidic-${dic}"
        wget -O ${fname} ${url}
    fi
    if [[ ! -d ${dname} ]]; then
        echo "unzip ${fname}"
        unzip ${fname}
    fi
    echo "remove old sources of unidic-${dic}"
    if [[ -d "unidic/src-unidic-${dic}" ]]; then
        rm -rf unidic/src-unidic-${dic}
        mkdir unidic/src-unidic-${dic}
    fi
    if [[ -d "unidic/src-unidic-${dic}-neologd" ]]; then
        rm -rf unidic/src-unidic-${dic}-neologd
        mkdir unidic/src-unidic-${dic}-neologd
    fi
    echo "copy sources of unidic-${dic}"
    cp -R ${dname}/ unidic/src-unidic-${dic}/
    cp -R ${dname}/ unidic/src-unidic-${dic}-neologd/
    echo "set the version of unidic-${dic}"
    echo "${version}" > unidic/version-unidic-${dic}
}

# clone/update mecab-unidic-neologd
function download_unidic_neologd () {
    neologd_dir="unidic/mecab-unidic-neologd"
    neologd_vfname="unidic/version-unidic-neologd"
    neologd_repo="https://github.com/neologd/mecab-unidic-neologd.git"
    if [[ ! -d ${neologd_dir} ]]; then
        echo "clone mecab-unidic-neologd"
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
        python3 convert_userdic.py unidic
    fi
}

# main
if [[ $# -gt 0 ]]; then
    if [[ "$1" == "cwj" ]]; then
        # download UniDic-cwj
        download_unidic cwj
    elif [[ "$1" == "csj" ]]; then
        # download UniDic-csj
        download_unidic csj
    else
        echo "no dictionary downloaded"
    fi
else
    # download UniDic-cwj and UniDic-crj
    download_unidic cwj
    download_unidic csj
fi
download_unidic_neologd
create_user_dictionary
