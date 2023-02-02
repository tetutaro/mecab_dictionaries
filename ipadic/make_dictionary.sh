#!/usr/bin/env bash
# check mecab-dict-index
if [[ -x ${PWD}/../mecab-0.996/src/mecab-dict-index ]]; then
    dictindex="${PWD}/../mecab-0.996/src/mecab-dict-index"
else
    echo "mecab is not installed"
    exit 1
fi
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
# check directories
if [[ ! -d src-ipadic ]]; then
    echo "src-ipadic is not created. do ${PWD}/../download_ipadic.sh."
    exit 1
fi
if [[ ! -d src-ipadic-neologd ]]; then
    echo "src-ipadic-neologd is not created. do ${PWD}/../download_ipadic.sh."
    exit 1
fi
if [[ ! -d mecab-ipadic-neologd ]]; then
    echo "mecab-ipadic-neologd is not created. do ${PWD}/../download_ipadic.sh."
    exit 1
fi

set -eu

# get the path of source dictionary
function get_source_path () {
    is_neologd=$1
    if "${is_neologd}"; then
        src_path="src-ipadic-neologd"
    else
        src_path="src-ipadic"
    fi
    echo ${src_path}
}

# add the name of dictionary to the system dictionary
function add_dictionary_name () {
    src_path=$1
    if [[ ! -f "${src_path}/.added" ]]; then
        ${sed} -i -e "s/$/,ipadic/g" ${src_path}/*.csv
        touch ${src_path}/.added
    fi
}

# add left-ID, right-ID, cost and name to the user dictionary
function create_user_dictionary () {
    src_path=$1
    if [[ ! -f "user.csv" ]]; then
        return 0
    fi
    ${dictindex} -m ${src_path}/model.bin -d ${src_path} -u ${src_path}/user.csv -f UTF8 -t UTF8 -a user.csv
    ${sed} -i -e "s/$/,user/g" ${src_path}/user.csv
}

# convert unidic-neologd for the UniDic3 format
function convert_neologd () {
    if [[ -f neologd/version-ipadic-neologd ]]; then
        old_version=$(cat neologd/version-ipadic-neologd)
        cd mecab-ipadic-neologd >/dev/null 2>&1
        new_version=$(git show --format='%h' --no-patch)
        cd - >/dev/null 2>&1
        if [[ "${old_version}" == "${new_version}" ]]; then
            return 0
        fi
    fi
    echo "retrieve the seed of mecab-ipadic-neologd"
    if [[ -d neologd ]]; then
        rm -rf neologd
    fi
    mkdir neologd
    cp mecab-ipadic-neologd/seed/*.xz neologd/.
    unxz neologd/*.xz
    nkf -w --overwrite neologd/*
    cp -f version-ipadic-neologd neologd/.
}

# add left-ID, right-ID, cost and name to the NEologd dictionary
function create_neologd_dictionary () {
    src_path=$1
    for file in $(ls neologd/*.csv); do
        bname=${file##*/}
        dfile="${src_path}/${bname}"
        cp ${file} ${dfile}
        ${sed} -i -e "s/$/,ipadic-neologd/g" ${dfile}
    done
}

# get the path of target dictionary
function get_target_path () {
    is_neologd=$1
    if "${is_neologd}"; then
        tgt_path="ipadic-neologd"
    else
        tgt_path="ipadic"
    fi
    echo ${tgt_path}
}

# get the path of target dictionary
function get_target_dictionary_path () {
    is_neologd=$1
    if "${is_neologd}"; then
        tgt_dic_path="ipadic-neologd/ipadic_neologd/dic"
    else
        tgt_dic_path="ipadic/ipadic/dic"
    fi
    echo ${tgt_dic_path}
}

# get the version of the dictionary
function get_version () {
    is_neologd=$1
    ipadic_version=$(cat version-ipadic)
    neologd_version=$(cat version-ipadic-neologd)
    if "${is_neologd}"; then
        version="${ipadic_version}+${neologd_version}"
    else
        version="${ipadic_version}"
    fi
    echo ${version}
}

# build the target dictionary
function build_target_dictionary () {
    src_path=$1
    tgt_path=$2
    tgt_dic_path=$3
    version=$4
    tgt_pkg_path=${tgt_dic_path%/*}
    if [[ -d ${tgt_dic_path} ]]; then
        rm -rf ${tgt_dic_path}
    fi
    mkdir ${tgt_dic_path}
    cp -f ${src_path}/char.* ${tgt_dic_path}/.
    cp -f dicrc ${tgt_dic_path}/.
    cp -f ${src_path}/feature.def ${tgt_dic_path}/.
    cp -f ${src_path}/left-id.def ${tgt_dic_path}/.
    cp -f ${src_path}/*.csv ${tgt_dic_path}/.
    cp -f ${src_path}/matrix.bin ${tgt_dic_path}/.
    cp -f ${src_path}/model.bin ${tgt_dic_path}/.
    cp -f ${src_path}/pos-id.def ${tgt_dic_path}/.
    cp -f ${src_path}/rewrite.def ${tgt_dic_path}/.
    cp -f ${src_path}/right-id.def ${tgt_dic_path}/.
    cp -f ${src_path}/sys.dic ${tgt_dic_path}/.
    cp -f ${src_path}/unk.def ${tgt_dic_path}/.
    cp -f ${src_path}/unk.dic ${tgt_dic_path}/.
    echo "__version__ = \"${version}\"" > ${tgt_pkg_path}/__version__.py
    echo "build Python package: ${tgt_path}"
    cd ${tgt_path} >/dev/null 2>&1
    poetry version ${version}
    poetry build
    cd - >/dev/null 2>&1
}

# rebuild UniDic
function rebuild_dictionary () {
    is_neologd=$1
    src_path=$(get_source_path ${is_neologd})
    echo "create ${src_path}"
    add_dictionary_name ${src_path}
    if [[ ! -f "${src_path}/model.bin" ]]; then
        # make binary beforehand to compile user dictionary.
        cd ${src_path} >/dev/null 2>&1
        ${dictindex} -f UTF8 -t UTF8
        cd - >/dev/null 2>&1
    fi
    create_user_dictionary ${src_path}
    if "${is_neologd}"; then
        convert_neologd
        create_neologd_dictionary ${src_path}
    fi
    cd ${src_path} >/dev/null 2>&1
    ${dictindex} -f UTF8 -t UTF8
    cd - >/dev/null 2>&1
    tgt_path=$(get_target_path ${is_neologd})
    echo "build ${tgt_path}"
    tgt_dic_path=$(get_target_dictionary_path ${is_neologd})
    version=$(get_version ${is_neologd})
    build_target_dictionary ${src_path} ${tgt_path} ${tgt_dic_path} ${version}
}

if [[ $# -gt 0 ]]; then
    if [[ "$1" == "ipadic" ]]; then
        # rebuild IPA Dictionary
        rebuild_dictionary false
    elif [[ "$1" == "ipadic-neologd" ]]; then
        # create IPA Dictionary + NEologd
        rebuild_dictionary true
    else
        echo "no dictionary is build"
    fi
else
    # rebuild all dictionaries
    rebuild_dictionary false
    rebuild_dictionary true
fi
