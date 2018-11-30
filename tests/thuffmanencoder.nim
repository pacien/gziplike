# gzip-like LZSS compressor
# Copyright (C) 2018  Pacien TRAN-GIRARD
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

import unittest, streams, tables
import bitio/bitreader, bitio/bitwriter
import huffmantree, huffmanencoder

suite "huffencoder":
  let tree = huffmanBranch(
    huffmanLeaf(1'u),
    huffmanBranch(
      huffmanLeaf(2'u),
      huffmanLeaf(3'u)))

  test "buildCodebook":
    let codebook = buildCodebook(tree, uint)
    check codebook.len == 3
    check codebook[1'u] == 0b0
    check codebook[2'u] == 0b01
    check codebook[3'u] == 0b11

  test "encode":
    let encoder = tree.encoder(uint)
    check encoder.encode(1'u) == 0b0
    check encoder.encode(2'u) == 0b01
    check encoder.encode(3'u) == 0b11
