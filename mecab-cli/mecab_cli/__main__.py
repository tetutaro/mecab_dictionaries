#!/usr/bin/env python
# -*- coding:utf-8 -*-
from __future__ import annotations
from typing import List, Dict, NamedTuple, Optional
import os
import re
from re import Match
import json
from argparse import ArgumentParser

from fugashi import GenericTagger
from neologdn import normalize as neonorm

DictionaryPackages: List[str] = [
    "unidic_cwj",
    "unidic_csj",
    "unidic_cwj_neologd",
    "unidic_csj_neologd",
    "ipadic",
    "ipadic_neologd",
    "jumandic",
]


class Node(NamedTuple):
    # min
    surface: str
    pos1: str
    pos2: str
    pos3: str
    pos4: str
    orthBase: str
    kana: str
    dic: str
    # disp
    cType: Optional[str] = "*"
    cForm: Optional[str] = "*"
    pron: Optional[str] = "*"
    # full
    lForm: Optional[str] = "*"
    lemma: Optional[str] = "*"
    orth: Optional[str] = "*"
    pronBase: Optional[str] = "*"
    goshu: Optional[str] = "*"
    iType: Optional[str] = "*"
    iForm: Optional[str] = "*"
    fType: Optional[str] = "*"
    fForm: Optional[str] = "*"
    iConType: Optional[str] = "*"
    fConType: Optional[str] = "*"
    n_type: Optional[str] = "*"
    kanaBase: Optional[str] = "*"
    form: Optional[str] = "*"
    formBase: Optional[str] = "*"
    aType: Optional[str] = "*"
    aConType: Optional[str] = "*"
    aModType: Optional[str] = "*"
    lid: Optional[str] = "*"
    lemma_id: Optional[str] = "*"

    def __str__(self: Node) -> str:
        return (
            f"{self.surface} "
            f"({self.kana:*<1}) "
            f"[{self.orthBase:*<1}] "
            f"<{self.pos1:*<1}."
            f"{self.pos2:*<1}."
            f"{self.pos3:*<1}."
            f"{self.pos4:*<1}>"
            f" ({self.dic})"
        )


class NodeDisp(Node):
    def __str__(self: NodeDisp) -> str:
        return (
            f"{self.surface} "
            f"({self.kana:*<1}:"
            f"{self.pron:*<1}) "
            f"[{self.orthBase:*<1}] "
            f"<{self.pos1:*<1}."
            f"{self.pos2:*<1}."
            f"{self.pos3:*<1}."
            f"{self.pos4:*<1}> "
            f"{{{self.cType:*<1}:"
            f"{self.cForm:*<1}}}"
            f" ({self.dic})"
        )


class NodeFull(NodeDisp):
    def __str__(self: NodeFull) -> str:
        return json.dumps(self._asdict(), ensure_ascii=False)


class Nodes:
    nodes: List[Node]

    def __init__(self: Nodes) -> None:
        self.nodes = list()
        return

    def append(self: Nodes, node: Node) -> None:
        self.nodes.append(node)
        return

    def __len__(self: Nodes) -> int:
        return len(self.nodes)

    def __str__(self: Nodes) -> str:
        return "\n".join([str(node) for node in self.nodes])


class Tokenizer(object):
    dic: str = ""  # path to the directory
    dic_name: str = ""
    dic_versoin: str = ""
    rc: str = ""
    raw_output: bool = False
    nbest: int = 1

    def __init__(
        self: Tokenizer,
        dictionary: str,
        path: str,
        rcfile: str,
        output_format_type: str,
        nbest: int,
        dictionary_info: bool,
        opts: List[str],
    ) -> None:
        self._check_raw_output(
            path=path,
            rcfile=rcfile,
            output_format_type=output_format_type,
            opts=opts,
        )
        if self.dic == "":
            self._get_dicdir(dic=dictionary)
        self._set_tagger(
            output_format_type=output_format_type,
            nbest=nbest,
            dictionary_info=dictionary_info,
            opts=opts,
        )
        self.format = output_format_type
        return

    def _check_raw_output(
        self: Tokenizer,
        path: str,
        rcfile: str,
        output_format_type: str,
        opts: List[str],
    ) -> bool:
        if rcfile != "":
            if not os.path.exists(rcfile):
                raise ImportError(f"{rcfile} is not found.")
            self.rc = rcfile
            self.raw_output = True
        if path != "":
            if not os.path.isdir(path):
                raise ImportError(f"{path} is not a directory.")
            if self.rc == "":
                rcfile: str = os.path.join(path, "dicrc")
                if not os.path.exists(rcfile):
                    raise ImportError(
                        f"{rcfile} is not found. is {path} a MeCab dictionary?"
                    )
                self.rc = rcfile
            self.dic = path
            self.raw_output = True
        if output_format_type == "wakati":
            opts.append("-O")
            opts.append("wakati")
            self.raw_output = True
        return

    def _get_dicdir(self: Tokenizer, dic: str) -> None:
        if dic in DictionaryPackages:
            ldic: Dict[str, str] = dict()
            exec(
                f"""import {dic}
dic_dir: str = {dic}.dicdir
dic_version: str = {dic}.__version__""",
                globals(),
                ldic,
            )
            self.dic = ldic["dic_dir"]
            self.dic_version = ldic["dic_version"]
        else:
            raise ImportError(f"{dic} is not a valid dictionary")
        if self.rc == "":
            self.rc = os.path.join(self.dic, "dicrc")
            if not os.path.exists(self.rc):
                raise ImportError(f"{dic} don't have dicrc")
        self.dic_name = dic
        userdic: str = os.path.join(self.dic, "user.csv")
        if os.path.exists(userdic):
            self.dic_name += " + user dictionary"
        return

    def _set_tagger(
        self: Tokenizer,
        output_format_type: str,
        nbest: int,
        dictionary_info: bool,
        opts: List[str],
    ) -> None:
        arg: str = f"-d {self.dic} -r {self.rc}"
        if nbest > 1:
            arg += f" -N {nbest}"
            self.nbest = nbest
        if output_format_type in ["disp", "full"]:
            arg += f" -O json-{output_format_type}"
        if opts is not None and len(opts) > 0:
            arg += " " + " ".join(opts)
        try:
            self.tagger: GenericTagger = GenericTagger(arg)
        except Exception as e:
            raise ImportError(f"cannot load dictionary: {e}")
        return

    def print_dictionaries(self: Tokenizer) -> None:
        infos: List[Dict[str, str]] = list()
        for di in self.tagger.dictionary_info:
            info: Dict[str, str] = dict()
            dic_fname: str = os.path.basename(di["filename"])
            dname: str = os.path.dirname(di["filename"])
            if dic_fname == "sys.dic":
                if self.dic_name != "":
                    info["type"] = "Package"
                    info["name"] = self.dic_name
                    info["version"] = self.dic_version
                    info["size"] = str(di["size"])
                    info["charset"] = di["charset"]
                    info["directory"] = dname
                else:
                    info["type"] = "Directory"
                    info["name"] = dname.split(os.sep)[-1]
                    info["version"] = str(di["version"])
                    info["size"] = str(di["size"])
                    info["charset"] = di["charset"]
                    info["directory"] = dname
            else:
                info["type"] = "User"
                info["name"] = os.path.splitext(dic_fname)[0]
                info["version"] = str(di["version"])
                info["size"] = str(di["size"])
                info["charset"] = di["charset"]
                info["directory"] = dname
            infos.append(info)
        for i, info in enumerate(infos):
            print(f"=== Dictionary {i + 1} ===")
            for key, val in info.items():
                print(f'{(key + ":").rjust(10)} {val}')
        return

    def tokenize(self: Tokenizer, text: str) -> None:
        text: str = neonorm(text)
        if self.nbest > 1:
            n_raw_nodes: List[str] = self._parse_nbest(text=text)
            for i, raw_nodes in enumerate(n_raw_nodes):
                print(f"  === Best {i + 1} ===")
                self._output_nodes(raw_nodes=raw_nodes)
        else:
            raw_nodes: str = self._parse_one(text=text)
            self._output_nodes(raw_nodes=raw_nodes)
        return

    def _parse_nbest(self: Tokenizer, text: str) -> List[str]:
        raw: str = self.tagger.nbest(text, num=self.nbest)
        return [raw_nodes.strip() for raw_nodes in raw.split("EOS")][:-1]

    def _parse_one(self: Tokenizer, text: str) -> str:
        raw: str = self.tagger.parse(text)
        return raw.split("EOS")[0].strip()

    def _cast_node(self: Tokenizer, raw_node: str) -> Node:
        if self.format == "min":
            node_cls = Node
        elif self.format == "disp":
            node_cls = NodeDisp
        elif self.format == "full":
            node_cls = NodeFull
        else:
            raise ValueError(
                f"output_format_type ({self.format}) is invalid.",
            )
        while True:
            match: Optional[Match] = re.search(
                r':"[^:,]*?(?<!\\)(")[^:,]*?",', raw_node
            )
            if match is None:
                break
            start: int = match.start(1)
            raw_node = raw_node[:start] + "\\" + raw_node[start:]
        try:
            node: Node = node_cls(**json.loads(raw_node))
        except Exception as e:
            match = re.match(r'^{"surface":"(.*?)","pos1":"', raw_node)
            if match is None:
                raise e
            node = node_cls(
                surface=match.group(1),
                pos1="記号",
                pos2="一般",
                pos3="",
                pos4="",
                orthBase="",
                kana="",
                dic="UNK",
            )
        return node

    def _output_nodes(self: Tokenizer, raw_nodes: str) -> None:
        nodes: Nodes = Nodes()
        for raw_node in raw_nodes.splitlines():
            raw_node = raw_node.strip()
            if raw_node == "EOS":
                if self.raw_output:
                    print(raw_node)
                break
            if self.raw_output:
                print(raw_node)
                continue
            nodes.append(node=self._cast_node(raw_node=raw_node))
        if len(nodes) > 0:
            print(nodes)
        return


def main() -> None:
    # get arguments
    parser = ArgumentParser(
        description="CLI of tokenizer (MeCab) using fugashi",
    )
    parser.add_argument(
        "-d",
        "--dictionary",
        type=str,
        default="unidic_cwj",
        choices=DictionaryPackages,
        help="Python package of MeCab dictionary",
    )
    parser.add_argument(
        "-p",
        "--path",
        type=str,
        default="",
        help="path to the directory of MeCab dictionary",
    )
    parser.add_argument(
        "-r",
        "--rcfile",
        type=str,
        default="",
        help="MeCab configuration file",
    )
    parser.add_argument(
        "-O",
        "--output-format-type",
        type=str,
        default="min",
        choices=["min", "disp", "full", "wakati"],
        help="set output format type",
    )
    parser.add_argument(
        "-N",
        "--nbest",
        type=int,
        default=1,
        help="output N best results (default 1)",
    )
    parser.add_argument(
        "-D",
        "--dictionary-info",
        action="store_true",
        help="show MeCab dictionary information and exit",
    )
    args, opts = parser.parse_known_args()
    if opts is None:
        opts = []
    # create Tokenizer
    try:
        tokenizer: Tokenizer = Tokenizer(**vars(args), opts=opts)
    except ImportError as e:
        print(f"{e}")
        return
    if args.dictionary_info is True:
        # show dictionary information and exit
        tokenizer.print_dictionaries()
        return
    # read one sentence from stdin
    text: str = input().strip()
    # run Tokenizer
    tokenizer.tokenize(text=text)
    return


if __name__ == "__main__":
    main()
