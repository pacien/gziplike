"À-la-gzip" LZSS compressor
===========================

A toy implementation of a simple gzip-like LZSS text compressor written in Nim.
This project is part of the compressor course at the Paris-East Marne-la-Vallée university.


Test and build
--------------

Building this project requires Nim and Nimble version 0.19.0 or later.

* `nimble build` produces a binary named `main`
* `nimble test` runs the included unit tests


Usage
-----

Compression and decompression are done using the `compress` and `decompress` commands repsectively.

The input stream is read from the standard input.
The result is outputted to the standard output.


License
-------

Copyright (C) 2018 Pacien TRAN-GIRARD.

This project is distributed under the terms of the GNU Affero General Public License v3.0, as detailed in the provided `license.md` file.

