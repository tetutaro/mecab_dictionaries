#!/usr/bin/env python3
# -*- coding:utf-8 -*-
import os

from unidic_csj.__version__ import __version__

dicdir = os.path.join(os.path.dirname(__file__), "dic")
__all__ = ["__version__", "dicdir"]
