#!/usr/bin/env python3
# -*- coding:utf-8 -*-
from __future__ import annotations
from typing import List, Dict, Callable
import os
import json
from argparse import ArgumentParser

USER_DICTIONARY: str = "userdic.jsonl"
CSV_FNAME: str = "user.csv"
DICTIONARIES: List[str] = [
    "ipadic",
    "jumandic",
    "unidic",
]
TYPE_SPCH: Dict[str, Dict[str, str]] = {
    "ipadic": {
        "普通名詞": "名詞,一般,*,*",
        "サ変可能名詞": "名詞,サ変接続,*,*",
        "固有名詞": "名詞,固有名詞,一般,*",
        "人名": "名詞,固有名詞,人名,一般",
        "姓": "名詞,固有名詞,人名,姓",
        "名": "名詞,固有名詞,人名,名",
        "組織": "名詞,固有名詞,組織,*",
        "地名": "名詞,固有名詞,地域,一般",
    },
    "jumandic": {
        "普通名詞": "名詞,普通名詞",
        "サ変可能名詞": "名詞,サ変名詞",
        "固有名詞": "名詞,固有名詞",
        "人名": "名詞,人名",
        "姓": "名詞,人名",
        "名": "名詞,人名",
        "組織": "名詞,組織名",
        "地名": "名詞,地名",
    },
    "unidic": {
        "普通名詞": "名詞,普通名詞,一般,*",
        "サ変可能名詞": "名詞,普通名詞,サ変可能,*",
        "固有名詞": "名詞,固有名詞,一般,*",
        "人名": "名詞,固有名詞,人名,一般",
        "姓": "名詞,固有名詞,人名,姓",
        "名": "名詞,固有名詞,人名,名",
        "組織": "名詞,固有名詞,一般,*",
        "地名": "名詞,固有名詞,地名,一般",
    },
}
KIND_GOSYU: Dict[str, str] = {
    "和語": "和",
    "漢語": "漢",
    "外語": "外",
    "混合": "混",
    "固有": "固",
}
TYPE_KIND: Dict[str, str] = {
    "普通名詞": "体",
    "サ変可能名詞": "体",
    "固有名詞": "固有名",
    "人名": "人名",
    "姓": "姓",
    "名": "名",
    "組織": "固有名",
    "地名": "地名",
}


class Handler:
    def __init__(self: Handler, dictionary: str) -> None:
        self.dictionary: str = dictionary
        return

    def _convert_ipadic(self: Handler, entry: Dict[str, str]) -> str:
        base = entry.get("base")
        spch = TYPE_SPCH[self.dictionary][entry.get("type")]
        yomi = entry.get("yomi")
        pron = entry.get("pron")
        return f"{base},,,,{spch},*,*,{base},{yomi},{pron}"

    def _convert_jumandic(self: Handler, entry: Dict[str, str]) -> str:
        base = entry.get("base")
        spch = TYPE_SPCH[self.dictionary][entry.get("type")]
        yomi = entry.get("yomi")
        pron = entry.get("pron")
        return f"{base},,,,{spch},*,*,{base},{yomi},{pron}"

    def _convert_unidic(self: Handler, entry: Dict[str, str]) -> str:
        base = entry.get("base")
        etype = entry.get("type")
        spch = TYPE_SPCH[self.dictionary][etype]
        gosyu = KIND_GOSYU[entry.get("kind")]
        yomi = entry.get("yomi")
        pron = entry.get("pron")
        kind = TYPE_KIND[etype]
        return (
            f"{base},,,,{spch},*,*,"
            f"{yomi},{yomi},{base},{pron},{base},{pron},"
            f"{gosyu},*,*,*,*,*,*,{kind},"
            f"{yomi},{yomi},{yomi},{yomi},*,*,*,*,*"
        )

    def _convert_dummy(self: Handler, entry: Dict[str, str]) -> str:
        return ""

    def _get_convertor(self: Handler) -> Callable[[Dict[str, str]], str]:
        if self.dictionary == "ipadic":
            return self._convert_ipadic
        elif self.dictionary == "jumandic":
            return self._convert_jumandic
        elif self.dictionary == "unidic":
            return self._convert_unidic
        return self._convert_dummy

    def _check_format(self: Handler, entry: Dict[str, str]) -> None:
        if entry.get("base") is None:
            raise ValueError('no "base"')
        etype = entry.get("type")
        if etype is None:
            raise ValueError('no "type"')
        if etype not in list(TYPE_SPCH[self.dictionary].keys()):
            raise ValueError('wrong "type"')
        if self.dictionary == "unidic":
            kind = entry.get("kind")
            if kind is None:
                raise ValueError('no "kind"')
            if kind not in list(KIND_GOSYU.keys()):
                raise ValueError('wrong "kind"')
            if etype in ["普通名詞", "サ変可能名詞"]:
                if kind not in ["漢語", "和語", "外語", "混合"]:
                    raise ValueError('wrong "kind" of noun')
            else:
                if kind != "固有":
                    raise ValueError('wrong "kind" of noun')
        if entry.get("yomi") is None:
            raise ValueError('no "yomi"')
        if entry.get("pron") is None:
            raise ValueError('no "pron"')
        return

    def _format(self: Handler, entry: Dict[str, str]) -> str:
        self._check_format(entry=entry)
        convertor: Callable[[Dict[str, str]], str] = self._get_convertor()
        return convertor(entry=entry)

    def convert(self: Handler) -> None:
        if not os.path.exists(USER_DICTIONARY):
            return
        if not os.path.isdir(self.dictionary):
            return
        entries: List[str] = list()
        with open(USER_DICTIONARY, "rt") as rf:
            raw_entries: List[str] = rf.read().splitlines()
            for i, text_entry in enumerate(raw_entries):
                if text_entry.startswith("//"):
                    continue
                try:
                    json_entry: Dict = json.loads(text_entry)
                except Exception:
                    print(f"froken JSON, ignore. (line: {i + 1})")
                    continue
                try:
                    entry: str = self._format(entry=json_entry)
                except Exception as e:
                    print(f"wrong format, ignore. (line: {i + 1}): {e}")
                    continue
                if len(entry) > 0:
                    entries.append(entry)
        output_fname = os.path.join(self.dictionary, CSV_FNAME)
        if len(entries) > 0:
            with open(output_fname, "wt") as wf:
                wf.write("\n".join(entries) + "\n")
                wf.flush()
        return


def main() -> None:
    parser = ArgumentParser(description=(f"convert {USER_DICTIONARY} to CSV"))
    parser.add_argument("dictionary", type=str, choices=DICTIONARIES)
    args = parser.parse_args()
    handler = Handler(**vars(args))
    handler.convert()
    return


if __name__ == "__main__":
    main()
