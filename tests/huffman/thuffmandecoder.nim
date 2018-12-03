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

import unittest, streams
import bitio/bitreader, bitio/bitwriter
import huffman/huffmantree, huffman/huffmandecoder

suite "huffmandecoder":
  let tree = huffmanBranch(
    huffmanLeaf(1'u),
    huffmanBranch(
      huffmanLeaf(2'u),
      huffmanLeaf(3'u)))

  test "decode":
    let stream = newStringStream()
    defer: stream.close()
    let bitWriter = stream.bitWriter()
    bitWriter.writeBool(true)  # 2
    bitWriter.writeBool(false)
    bitWriter.writeBool(false) # 1
    bitWriter.writeBool(true)  # 3
    bitWriter.writeBool(true)
    bitWriter.flush()
    stream.setPosition(0)
    let bitReader = stream.bitReader()
    let decoder = tree.decoder()
    check decoder.decode(bitReader) == 2'u
    check decoder.decode(bitReader) == 1'u
    check decoder.decode(bitReader) == 3'u
