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

import lists
import ../bitio/integers, ../bitio/bitreader, ../bitio/bitwriter
import ../lzss/lzsschain, ../lzss/lzssencoder
import ../huffman/huffmantree, ../huffman/huffmantreebuilder, ../huffman/huffmanencoder, ../huffman/huffmandecoder
import ../lzsshuffman/lzsshuffmanstats, ../lzsshuffman/lzsshuffmandecoder, ../lzsshuffman/lzsshuffmanencoder

const maxDataByteLength = 32_000

type LzssBlock* = object
  lzssChain: LzssChain

proc readSerialised*(bitReader: BitReader): LzssBlock =
  let symbolHuffmanTree = huffmantree.deserialise(bitReader, uint16)
  let positionHuffmanTree = huffmantree.deserialise(bitReader, uint16)
  let symbolDecoder = symbolHuffmanTree.decoder()
  let positionDecoder = positionHuffmanTree.decoder()
  LzssBlock(lzssChain: readChain(bitReader, symbolDecoder, positionDecoder, maxDataByteLength))

proc writeSerialisedTo*(lzssBlock: LzssBlock, bitWriter: BitWriter) =
  let (symbolStats, positionStats) = aggregateStats(lzssBlock.lzssChain)
  let symbolHuffmanTree = buildHuffmanTree(symbolStats)
  let positionHuffmanTree = buildHuffmanTree(positionStats)
  let symbolEncoder = symbolHuffmanTree.encoder(uint16)
  let positionEncoder = positionHuffmanTree.encoder(uint16)
  symbolHuffmanTree.serialise(bitWriter)
  positionHuffmanTree.serialise(bitWriter)
  lzssBlock.lzssChain.writeChain(symbolEncoder, positionEncoder, bitWriter)

proc readRaw*(bitReader: BitReader): LzssBlock =
  let byteBuf = bitReader.readSeq(maxDataByteLength, uint8)
  LzssBlock(lzssChain: lzssEncode(byteBuf.data))

proc writeRawTo*(lzssBlock: LzssBlock, bitWriter: BitWriter) =
  let byteSeq = lzssBlock.lzssChain.decode()
  bitWriter.writeSeq(byteSeq.len * wordBitLength, byteSeq)
