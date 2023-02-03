#!/usr/bin/env python
# -*- coding:utf-8 -*-
from __future__ import annotations
from typing import List, Dict, NamedTuple, Optional
import os
import sys
import json
from argparse import ArgumentParser

from fugashi import GenericTagger
from neologdn import normalize as neonorm


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
        if dic == "unidic_cwj":
            import unidic_cwj

            self.dic = unidic_cwj.dicdir
            self.dic_name = dic
            self.dic_version = unidic_cwj.__version__
        elif dic == "unidic_csj":
            import unidic_csj

            self.dic = unidic_csj.dicdir
            self.dic_name = dic
            self.dic_version = unidic_csj.__version__
        elif dic == "unidic_cwj_neologd":
            import unidic_cwj_neologd

            self.dic = unidic_cwj_neologd.dicdir
            self.dic_name = dic
            self.dic_version = unidic_cwj_neologd.__version__
        elif dic == "unidic_csj_neologd":
            import unidic_csj_neologd

            self.dic = unidic_csj_neologd.dicdir
            self.dic_name = dic
            self.dic_version = unidic_csj_neologd.__version__
        elif dic == "ipadic":
            import ipadic

            self.dic = ipadic.dicdir
            self.dic_name = dic
            self.dic_version = ipadic.__version__
        elif dic == "ipadic_neologd":
            import ipadic_neologd

            self.dic = ipadic_neologd.dicdir
            self.dic_name = dic
            self.dic_version = ipadic_neologd.__version__
        elif dic == "jumandic":
            import jumandic

            self.dic = jumandic.dicdir
            self.dic_name = dic
            self.dic_version = jumandic.__version__
        else:
            raise ImportError(f"{dic} is not a valid dictionary")
        if self.rc == "":
            self.rc = os.path.join(self.dic, "dicrc")
            if not os.path.exists(self.rc):
                raise ImportError(f"{dic} don't have dicrc")
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
            if '"""' in raw_node:
                raw_node = raw_node.replace('"""', '"\\""')
            if self.format == "min":
                node: Node = Node(**json.loads(raw_node))
            elif self.format == "disp":
                node: NodeDisp = NodeDisp(**json.loads(raw_node))
            elif self.format == "full":
                node: NodeFull = NodeFull(**json.loads(raw_node))
            else:
                raise ValueError(
                    f"output_format_type ({self.format}) is invalid.",
                )
            nodes.append(node=node)
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
        choices=[
            "unidic_cwj",
            "unidic_csj",
            "unidic_cwj_neologd",
            "unidic_csj_neologd",
            "ipadic",
            "ipadic_neologd",
            "jumandic",
        ],
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
    # read sentence from stdin
    text: str = sys.stdin.read().strip()
    # run Tokenizer
    tokenizer.tokenize(text=text)
    return


if __name__ == "__main__":
    main()
