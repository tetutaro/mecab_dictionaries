#!/usr/bin/env python3
# -*- coding:utf-8 -*-
from typing import List
from mmap import mmap
import os
import re
from argparse import ArgumentParser

from tqdm import tqdm

MAX_WORD_LEN: int = 32


def get_nline(fname: str) -> int:
    nlines: int = 0
    with open(fname, "r+") as fp:
        buf: mmap = mmap(fp.fileno(), 0)
        while buf.readline():
            nlines += 1
    return nlines


def create_format(
    surf: str,
    spch: str,
    yomi: str,
    base: str,
    pron: str,
    goshu: str,
    kind: str,
) -> str:
    fmt: str = (
        f"{surf},,,,{spch},*,*,"
        f"{yomi},{yomi},{base},{pron},{base},{pron},"
        f"{goshu},*,*,*,*,*,*,{kind},"
        f"{yomi},{yomi},{yomi},{yomi},*,*,*,*,*"
    )
    return fmt


def detect_goshu(surf: str) -> str:
    goshu: str = "不明"
    if re.match(r"^[a-zA-Z0-9]+$", surf):
        goshu = "外"
    elif re.match(r"^[ア-ン]+$", surf):
        goshu = "外"
    elif re.match(r"^[あ-ん]+$", surf):
        goshu = "和"
    else:
        goshu = "混"
    return goshu


def convert_proper_noun(
    pos3: str,
    pos4: str,
    surf: str,
    spch: str,
    yomi: str,
    base: str,
    pron: str,
) -> str:
    conved: str = ""
    if pos3 == "人名" and pos4 == "姓":
        conved = create_format(
            surf=surf,
            spch=spch,
            yomi=yomi,
            base=base,
            pron=pron,
            goshu="固",
            kind="姓",
        )
    elif pos3 == "人名" and pos4 == "名":
        conved = create_format(
            surf=surf,
            spch=spch,
            yomi=yomi,
            base=base,
            pron=pron,
            goshu="固",
            kind="名",
        )
    elif pos3 == "人名" and pos4 == "一般":
        conved = create_format(
            surf=surf,
            spch=spch,
            yomi=yomi,
            base=base,
            pron=pron,
            goshu="固",
            kind="人名",
        )
    elif pos3 == "地名" and pos4 == "一般":
        conved = create_format(
            surf=surf,
            spch=spch,
            yomi=yomi,
            base=base,
            pron=pron,
            goshu="固",
            kind="地名",
        )
    elif pos3 == "一般":
        conved = create_format(
            surf=surf,
            spch=spch,
            yomi=yomi,
            base=base,
            pron=pron,
            goshu="固",
            kind="固有名",
        )
    return conved


def convert_noun(
    pos3: str,
    surf: str,
    spch: str,
    yomi: str,
    base: str,
    pron: str,
) -> str:
    conved: str = ""
    goshu = detect_goshu(surf=surf)
    if pos3 in ["一般", "サ変可能"]:
        conved = create_format(
            surf=surf,
            spch=spch,
            yomi=yomi,
            base=base,
            pron=pron,
            goshu=goshu,
            kind="体",
        )
    return conved


def convert_format(poss: List[str]) -> str:
    conved: str = ""
    surf: str = poss[0]
    pos1: str = poss[4]
    pos2: str = poss[5]
    pos3: str = poss[6]
    pos4: str = poss[7]
    yomi: str = poss[10]
    base: str = poss[11]
    pron: str = poss[15]
    spch: str = ",".join(poss[4:8])
    if yomi == "カオモジ":
        conved: str = create_format(
            surf=surf,
            spch="補助記号,ＡＡ,顔文字,*",
            yomi="*",
            base=surf,
            pron="*",
            goshu="記号",
            kind="補助",
        )
    elif pos1 == "記号" and pos2 == "一般":
        conved = create_format(
            surf=surf,
            spch=spch,
            yomi=yomi,
            base=base,
            pron=pron,
            goshu="記号",
            kind="記号",
        )
    elif pos1 == "名詞":
        if pos2 == "固有名詞":
            conved = convert_proper_noun(
                pos3=pos3,
                pos4=pos4,
                surf=surf,
                spch=spch,
                yomi=yomi,
                base=base,
                pron=pron,
            )
        elif pos2 == "普通名詞":
            conved = convert_noun(
                pos3=pos3,
                surf=surf,
                spch=spch,
                yomi=yomi,
                base=base,
                pron=pron,
            )
    return conved


def convert(seed: str, output: str) -> None:
    if not os.path.exists(seed):
        raise ValueError(f"seed({seed}) is not found")
    with open(seed, "rt") as rf, open(output, "wt") as wf:
        for line in tqdm(rf, total=get_nline(seed)):
            line = line.strip()
            # remove word which contains HTML tags
            if re.search(r"<.*?>", line) is not None:
                continue
            poss = line.split(",")
            if len(poss) != 21:
                continue
            # remove word which is too long
            if len(poss[0]) > MAX_WORD_LEN:
                continue
            conved = convert_format(poss=poss)
            if len(conved) > 0:
                wf.write(conved + "\n")
                wf.flush()
    return


def main() -> None:
    parser = ArgumentParser(
        description=(
            "convert the seed of mecab-unidic-neologd for UniDic3 format"
        )
    )
    parser.add_argument(
        "seed",
        type=str,
        help=(
            "the filename of the unzipped seed file of mecab-unidic-neologd"
        ),
    )
    parser.add_argument(
        "-o", "--output", type=str, required=True, help="the output filename"
    )
    args = parser.parse_args()
    convert(**vars(args))
    return


if __name__ == "__main__":
    main()
