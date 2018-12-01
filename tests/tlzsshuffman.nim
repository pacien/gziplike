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

import unittest, tables, lists, sequtils, streams
import bitio/bitwriter, bitio/bitreader
import lzss/listpolyfill, lzss/lzssnode, lzss/lzsschain
import huffman/huffmantree, huffman/huffmantreebuilder, huffman/huffmanencoder, huffman/huffmandecoder
import lzsshuffman/lzsshuffmansymbol, lzsshuffman/lzsshuffmanstats, lzsshuffman/lzsshuffmanencoder, lzsshuffman/lzsshuffmandecoder

suite "lzsshuffmansymbol":
  test "isEndMarker":
    check 'a'.Symbol.isEndMarker() == false
    check endSymbol.isEndMarker()

  test "isCharacter":
    check 'a'.Symbol.isCharacter()
    check endSymbol.isCharacter() == false
    check 300.Symbol.isCharacter() == false
  
  test "unpackLzssReference":
    check unpackLzssReference(257.Symbol, 10) == lzssReference(3, 10)
    check unpackLzssReference(300.Symbol, 10) == lzssReference(46, 10)

  test "shiftLzssLength":
    check shiftLzssLength(3) == 257'u16
    check shiftLzssLength(10) == 264'u16

suite "lzsshuffmanstats":
  test "aggretateStats":
    let chain = lzssChain([
      lzssCharacter(0), lzssCharacter(1), lzssCharacter(2),
      lzssCharacter(3), lzssCharacter(4), lzssCharacter(5),
      lzssReference(4, 6), lzssCharacter(0), lzssCharacter(1),
      lzssReference(3, 8), lzssCharacter(5),
      lzssReference(3, 3), lzssCharacter(5)])
    let (symbolTable, positionTable) = chain.aggregateStats()
    check symbolTable == newCountTable(concat(
      repeat(0'u16, 2), repeat(1'u16, 2), repeat(2'u16, 1), repeat(3'u16, 1), repeat(4'u16, 1), repeat(5'u16, 3),
      repeat(endSymbol.uint16, 1),
      repeat(257'u16, 2), repeat(258'u16, 1)))
    check positionTable == newCountTable(concat(
      repeat(3'u16, 1), repeat(6'u16, 1), repeat(8'u16, 1)))

suite "lzsshuffmanencoder":
  test "writeChain (empty)":
    let chain = lzssChain(newSeq[LzssNode]())
    let symbolTree = huffmanLeaf(endSymbol.uint16)
    let positionTree = huffmanLeaf(0'u16)
    let stream = newStringStream()
    defer: stream.close()
    let bitWriter = stream.bitWriter()
    writeChain(chain, symbolTree.encoder(uint16), positionTree.encoder(uint16), bitWriter)
    bitWriter.flush()
    stream.setPosition(0)
    check stream.atEnd()

  test "writeChain (minimal)":
    let chain = lzssChain([
      lzssCharacter(0), lzssCharacter(1), lzssCharacter(2),
      lzssReference(3, 3), lzssReference(3, 4)])
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
    writeChain(chain, symbolTree.encoder(uint16), positionTree.encoder(uint16), bitWriter)
    bitWriter.flush()
    stream.setPosition(0)
    let bitReader = stream.bitReader()
    check bitReader.readBits(2, uint8) == 0b00'u8   # char 0
    check bitReader.readBits(2, uint8) == 0b10'u8   # char 1
    check bitReader.readBits(3, uint8) == 0b011'u8  # char 2
    check bitReader.readBits(2, uint8) == 0b01'u8   # ref len 3
    check bitReader.readBits(1, uint8) == 0b0'u8    # ref pos 3
    check bitReader.readBits(2, uint8) == 0b01'u8   # ref len 3
    check bitReader.readBits(1, uint8) == 0b1'u8    # ref pos 4
    check bitReader.readBits(3, uint8) == 0b111'u8  # eof

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
    check toSeq(result.items).len == 0

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
    check toSeq(result.items) == [
      lzssCharacter(0), lzssCharacter(1), lzssCharacter(2),
      lzssReference(3, 3), lzssReference(3, 4)]
