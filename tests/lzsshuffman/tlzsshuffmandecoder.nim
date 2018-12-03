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
import bitio/bitwriter, bitio/bitreader
import lzss/lzssnode
import huffman/huffmantree, huffman/huffmandecoder
import lzsshuffman/lzsshuffmansymbol, lzsshuffman/lzsshuffmandecoder

suite "lzsshuffmandecoder":
  test "readChain (empty)":
    let symbolTree = huffmanLeaf(endSymbol.uint16)
    let positionTree = huffmanLeaf(0'u16)
    let stream = newStringStream()
    defer: stream.close()
    stream.write(0'u8) # eof
    stream.setPosition(0)
    let bitReader = stream.bitReader()
    let result = readChain(bitReader, symbolTree.decoder(), positionTree.decoder(), 32_000)
    check result.len == 0

  test "readChain (minimal)":
    let symbolTree = huffmanBranch(
      huffmanBranch(
        huffmanLeaf(0'u16),
        huffmanLeaf(1'u16)),
      huffmanBranch(
        huffmanLeaf(257'u16),
        huffmanBranch(
          huffmanLeaf(2'u16),  
          huffmanLeaf(256'u16))))
    let positionTree = huffmanBranch(
      huffmanLeaf(3'u16),
      huffmanLeaf(4'u16))
    let stream = newStringStream()
    defer: stream.close()
    let bitWriter = stream.bitWriter()
    bitWriter.writeBits(2, 0b00'u8)
    bitWriter.writeBits(2, 0b10'u8)
    bitWriter.writeBits(3, 0b011'u8)
    bitWriter.writeBits(2, 0b01'u8)
    bitWriter.writeBits(1, 0b0'u8)
    bitWriter.writeBits(2, 0b01'u8)
    bitWriter.writeBits(1, 0b1'u8)
    bitWriter.writeBits(3, 0b111'u8)
    bitWriter.flush()
    stream.setPosition(0)
    let bitReader = stream.bitReader()
    let result = readChain(bitReader, symbolTree.decoder(), positionTree.decoder(), 32_000)
    check result == [
      lzssCharacter(0), lzssCharacter(1), lzssCharacter(2),
      lzssReference(3, 3), lzssReference(3, 4)]
