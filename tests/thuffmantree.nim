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
import bitreader, bitwriter, huffmantree

suite "huffmantree":
  let tree = huffmanBranch(
    huffmanLeaf(1'u),
    huffmanBranch(
      huffmanLeaf(2'u),
      huffmanLeaf(3'u)))

  test "equality":
    check huffmanLeaf(12'u) == huffmanLeaf(12'u)
    check huffmanLeaf(12'u) != huffmanLeaf(21'u)
    check huffmanLeaf(12'u) != huffmanBranch(huffmanLeaf(12'u), huffmanLeaf(12'u))
    check huffmanBranch(huffmanLeaf(12'u), huffmanLeaf(21'u)) == huffmanBranch(huffmanLeaf(12'u), huffmanLeaf(21'u))
    check huffmanBranch(huffmanLeaf(12'u), huffmanLeaf(21'u)) != huffmanBranch(huffmanLeaf(12'u), huffmanLeaf(1'u))
    check tree == tree

  test "maxValue":
    check tree.maxValue() == 3

  test "deserialise":
    let stream = newStringStream()
    defer: stream.close()
    let bitWriter = stream.bitWriter()
    bitWriter.writeBits(valueLengthFieldBitLength, 2'u8)
    bitWriter.writeBool(false)   # root
    bitWriter.writeBool(true)    # 1 leaf
    bitWriter.writeBits(2, 1'u)
    bitWriter.writeBool(false)   # right branch
    bitWriter.writeBool(true)    # 2 leaf
    bitWriter.writeBits(2, 2'u)
    bitWriter.writeBool(true)    # 3 leaf
    bitWriter.writeBits(2, 3'u)
    bitWriter.flush()

    stream.setPosition(0)
    let bitReader = stream.bitReader()
    check huffmantree.deserialise(bitReader, uint) == tree

  test "serialise":
    let stream = newStringStream()
    defer: stream.close()
    let bitWriter = stream.bitWriter()
    tree.serialise(bitWriter)
    bitWriter.flush()

    stream.setPosition(0)
    let bitReader = stream.bitReader()
    check bitReader.readBits(valueLengthFieldBitLength, uint8) == 2
    check bitReader.readBool() == false  # root
    check bitReader.readBool() == true   # 1 leaf
    check bitReader.readBits(2, uint8) == 1
    check bitReader.readBool() == false  # right branch
    check bitReader.readBool() == true   # 2 leaf
    check bitReader.readBits(2, uint8) == 2
    check bitReader.readBool() == true   # 3 leaf
    check bitReader.readBits(2, uint8) == 3
