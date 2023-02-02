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
function download_jumandic () {
    gid="0B4y35FiV1wh7X2pESGlLREpxdXM"
    fname="jumandic-7.0-20130310.tar.gz"
    dname=${fname%.*.*}
    version=${dname#*-}
    # Ideally, the official (?) way is following
    #
    # url="https://drive.google.com/uc?export=download&id=${gid}"
    # wget -q --keep-session-cookies --save-cookies=/tmp/cookie "${url}"
    # CODE="$(awk '/_warning_/ {print $NF}' /tmp/cookie)"
    # url="https://drive.google.com/uc?export=download&confirm=${CODE}&id=${gid}"
    # wget -O ${fname} --load-cookies=/tmp/cookie "${url}"
    #
    # But, I cannot download that way. I don't know why.
    # Maybe, The file size is not too big.
    CODE="t"
    url="https://drive.google.com/uc?export=download&confirm=${CODE}&id=${gid}"

    if [[ ! -f ${fname} ]]; then
        echo "get the latest version of Juman Dictionary for MeCab"
        wget -O ${fname} ${url}
    fi
    if [[ ! -d ${dname} ]]; then
        echo "unzip ${fname} and convert encodings"
        # extract
        tar zxf ${fname}
        mv "mecab-${dname}" ${dname}
    fi
    echo "remove old sources of ipadic"
    if [[ -d "jumandic/src-jumandic" ]]; then
        rm -rf jumandic/src-jumandic
        mkdir jumandic/src-jumandic
    fi
    echo "copy sources of jumandic"
    cp -R ${dname}/ jumandic/src-jumandic/
    echo "set the version of jumandic"
    echo "${version}" > jumandic/version-jumandic
}

# create user dictionary
function create_user_dictionary () {
    if [[ -f "userdic.jsonl" ]]; then
        python3 convert_userdic.py jumandic
    fi
}

# main
download_jumandic
create_user_dictionary
