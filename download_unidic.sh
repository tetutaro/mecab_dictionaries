#!/usr/bin/env bash

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
    else
        echo "${fname} has already downloaded"
    fi
    if [[ ! -d ${dname} ]]; then
        echo "unzip ${fname}"
        unzip ${fname}
    else
        echo "${fname} has already unzipped at ${dname}"
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

# UniDic-cwj
download_unidic cwj
# UniDic-csj
download_unidic csj

# clone/update mecab-unidic-neologd
if [[ -d "unidic/mecab-unidic-neologd" ]]; then
    echo "update mecab-unidic-neologd"
    cd unidic/mecab-unidic-neologd >/dev/null 2>&1
    git pull
    cd - >/dev/null 2>&1
else
    echo "clone mecab-unidic-neologd"
    git clone --depth 1 https://github.com/neologd/mecab-unidic-neologd.git unidic/mecab-unidic-neologd
fi
echo "set the version of mecab-unidic-neologd"
cd unidic/mecab-unidic-neologd >/dev/null 2>&1
version=$(git show --format='%h' --no-patch)
cd - >/dev/null 2>&1
echo "${version}" > unidic/version-unidic-neologd

# create user dictionary
if [[ -f "userdic.jsonl" ]]; then
    echo "create user dictionary of unidic"
    python3 convert_userdic.py unidic
fi
