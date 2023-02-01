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
if [[ ! -d src-unidic-cwj ]]; then
    echo "src-unidic-cwj is not created. do ${PWD}/../download_unidic.sh."
    exit 1
fi
if [[ ! -d src-unidic-cwj-neologd ]]; then
    echo "src-unidic-cwj-neologd is not created. do ${PWD}/../download_unidic.sh."
    exit 1
fi
if [[ ! -d src-unidic-csj ]]; then
    echo "src-unidic-csj is not created. do ${PWD}/../download_unidic.sh."
    exit 1
fi
if [[ ! -d src-unidic-csj-neologd ]]; then
    echo "src-unidic-csj-neologd is not created. do ${PWD}/../download_unidic.sh."
    exit 1
fi
if [[ ! -d mecab-unidic-neologd ]]; then
    echo "mecab-unidic-neologd is not created. do ${PWD}/../download_unidic.sh."
    exit 1
fi

# get the path of source dictionary
function get_source_path () {
    base_dic=$1
    is_neologd=$2
    if "${is_neologd}"; then
        src_path="src-unidic-${base_dic}-neologd"
    else
        src_path="src-unidic-${base_dic}"
    fi
    echo ${src_path}
}

# add the name of dictionary to the system dictionary
function add_dictionary_name () {
    src_path=$1
    base_dic=$2
    if [[ ! -f "${src_path}/.added" ]]; then
        ${sed} -i -e "s/$/,unidic-${base_dic}/g" ${src_path}/*.csv
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
    if [[ -f neologd/version-unidic-neologd ]]; then
        old_version=$(cat neologd/version-unidic-neologd)
        cd mecab-unidic-neologd >/dev/null 2>&1
        new_version=$(git show --format='%h' --no-patch)
        cd - >/dev/null 2>&1
        if [[ "${old_version}" == "${new_version}" ]]; then
            return 0
        fi
    fi
    echo "retrieve the seed of mecab-unidic-neologd"
    if [[ -d temp ]]; then
        rm -rf temp
    fi
    mkdir temp
    cp mecab-unidic-neologd/seed/*.xz temp/.
    unxz temp/*.xz
    if [[ -d neologd ]]; then
        rm -rf neologd
    fi
    mkdir neologd
    for file in $(ls temp/*.csv); do
        bname=${file##*/}
        echo "convert ${bname} for the UniDic3 format"
        python3 convert_neologd2unidic3.py -o neologd/${bname} ${file}
    done
    rm -rf temp
    cp -f version-unidic-neologd neologd/.
}

# add left-ID, right-ID, cost and name to the NEologd dictionary
function create_neologd_dictionary () {
    src_path=$1
    for file in $(ls neologd/*.csv); do
        bname=${file##*/}
        dfile="${src_path}/${bname}"
        echo "add indexes to ${bname}"
        ${dictindex} -m ${src_path}/model.bin -d ${src_path} -u ${dfile} -f UTF8 -t UTF8 -a ${file}
        ${sed} -i -e "s/$/,unidic-neologd/g" ${dfile}
    done
}

# get the path of target dictionary
function get_target_path () {
    base_dic=$1
    is_neologd=$2
    if "${is_neologd}"; then
        tgt_path="unidic-${base_dic}-neologd"
    else
        tgt_path="unidic-${base_dic}"
    fi
    echo ${tgt_path}
}

# get the path of target dictionary
function get_target_dictionary_path () {
    base_dic=$1
    is_neologd=$2
    if "${is_neologd}"; then
        tgt_dic_path="unidic-${base_dic}-neologd/unidic_${base_dic}_neologd/dic"
    else
        tgt_dic_path="unidic-${base_dic}/unidic_${base_dic}/dic"
    fi
    echo ${tgt_dic_path}
}

# get the version of the dictionary
function get_version () {
    base_dic=$1
    is_neologd=$2
    unidic_version=$(cat version-unidic-${base_dic})
    neologd_version=$(cat version-unidic-neologd)
    if "${is_neologd}"; then
        version="${unidic_version}+${neologd_version}"
    else
        version="${unidic_version}"
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
    base_dic=$1
    is_neologd=$2
    src_path=$(get_source_path ${base_dic} ${is_neologd})
    echo "create ${src_path}"
    add_dictionary_name ${src_path} ${base_dic}
    create_user_dictionary ${src_path}
    if "${is_neologd}"; then
        convert_neologd
        create_neologd_dictionary ${src_path}
    fi
    cd ${src_path} >/dev/null 2>&1
    ${dictindex} -f UTF8 -t UTF8
    cd - >/dev/null 2>&1
    tgt_path=$(get_target_path ${base_dic} ${is_neologd})
    echo "build ${tgt_path}"
    tgt_dic_path=$(get_target_dictionary_path ${base_dic} ${is_neologd})
    version=$(get_version ${base_dic} ${is_neologd})
    build_target_dictionary ${src_path} ${tgt_path} ${tgt_dic_path} ${version}
}

if [[ $# -gt 0 ]]; then
    if [[ "$1" == "cwj" ]]; then
        # rebuild UniDic-cwj
        rebuild_dictionary cwj false
    elif [[ "$1" == "cwj-neologd" ]]; then
        # create UniDic-cwj + NEologd
        rebuild_dictionary cwj true
    elif [[ "$1" == "csj" ]]; then
        # rebuild UniDic-csj
        rebuild_dictionary csj false
    elif [[ "$1" == "csj-neologd" ]]; then
        # create UniDic-csj + NEologd
        rebuild_dictionary csj true
    else
        echo "no dictionary is build"
    fi
else
    # rebuild all dictionaries
    rebuild_dictionary cwj false
    rebuild_dictionary cwj true
    rebuild_dictionary csj false
    rebuild_dictionary csj true
fi
