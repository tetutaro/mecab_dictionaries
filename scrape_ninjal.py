#!/usr/bin/env python3
# -*- coding:utf-8 -*-
from __future__ import annotations
from typing import Tuple, List
import os
from argparse import ArgumentParser

import requests
from requests.models import Response
from bs4 import BeautifulSoup
from bs4.element import Tag
from packaging.version import Version


class Handler:
    def __init__(self: Handler, dictionary: str) -> None:
        self.dictionary: str = dictionary
        return

    def scrape(self: Handler) -> None:
        domain: str = "https://clrd.ninjal.ac.jp"
        url: str = domain + "/unidic/back_number.html"
        r: Response = requests.get(url)
        soup: BeautifulSoup = BeautifulSoup(r.text, "html.parser")
        div: Tag = soup.find(
            name="div", attrs={"id": f"unidic_{self.dictionary}"}
        )
        zips: List[Tuple[Version, str]] = list()
        for a in div.find_all("a"):
            href: str = a.get("href")
            if href.endswith("-full.zip"):
                version: str = os.path.basename(href).split("-")[-2]
                zips.append((Version(version=version), domain + href))
        zips = sorted(zips, key=lambda x: x[0], reverse=True)
        print(zips[0][1])
        return


def main() -> None:
    parser = ArgumentParser(
        description=("print the latest version of zip file")
    )
    parser.add_argument("dictionary", type=str, choices=["cwj", "csj"])
    args = parser.parse_args()
    handler = Handler(**vars(args))
    handler.scrape()
    return


if __name__ == "__main__":
    main()
