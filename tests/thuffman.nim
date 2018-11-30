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

import unittest, streams, sequtils, tables, heapqueue
import bitio/bitreader, bitio/bitwriter
import huffman/huffmantree, huffman/huffmantreebuilder, huffman/huffmanencoder, huffman/huffmandecoder

let
  stats = newCountTable(concat(repeat(1'u, 3), repeat(2'u, 1), repeat(3'u, 2)))
  tree = huffmanBranch(
    huffmanLeaf(1'u),
    huffmanBranch(
      huffmanLeaf(2'u),
      huffmanLeaf(3'u)))

suite "huffmantree":
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

suite "huffmantreebuilder":
  test "buildHuffmanTree":
    check buildHuffmanTree(stats) == tree

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

suite "huffdecoder":
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
