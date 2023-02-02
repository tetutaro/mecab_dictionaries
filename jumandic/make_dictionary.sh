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
if [[ ! -d src-jumandic ]]; then
    echo "src-jumandic is not created. do ${PWD}/../download_jumandic.sh."
    exit 1
fi

set -eu

# add the name of dictionary to the system dictionary
function add_dictionary_name () {
    src_path=$1
    if [[ ! -f "${src_path}/.added" ]]; then
        ${sed} -i -e "s/$/,jumandic/g" ${src_path}/*.csv
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
    cd ${tgt_path} >/dev/null 2>&1
    poetry version ${version}
    poetry build
    cd - >/dev/null 2>&1
}

# rebuild UniDic
function rebuild_dictionary () {
    src_path="src-jumandic"
    echo "create ${src_path}"
    add_dictionary_name ${src_path}
    if [[ ! -f "${src_path}/model.bin" ]]; then
        # make binary beforehand to compile user dictionary.
        cd ${src_path} >/dev/null 2>&1
        ${dictindex} -f UTF8 -t UTF8
        cd - >/dev/null 2>&1
    fi
    create_user_dictionary ${src_path}
    cd ${src_path} >/dev/null 2>&1
    ${dictindex} -f UTF8 -t UTF8
    cd - >/dev/null 2>&1
    tgt_path="jumandic"
    echo "build ${tgt_path}"
    tgt_dic_path="jumandic/jumandic/dic"
    version=$(cat version-jumandic)
    build_target_dictionary ${src_path} ${tgt_path} ${tgt_dic_path} ${version}
}

rebuild_dictionary
