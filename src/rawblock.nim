# "à-la-gzip" gzip-like LZSS compressor
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

import integers, bitreader, bitwriter

const maxDataBitLength = 100_000_000 * wordBitLength # 100MB
const bitLengthFieldBitLength = 2 * wordBitLength

type RawBlock* = object
  bitLength: int
  data: seq[uint8]

proc readSerialised*(bitReader: BitReader): RawBlock =
  let bitLength = bitReader.readBits(bitLengthFieldBitLength, uint16).int
  let data = readSeq(bitReader, bitLength, uint8)
  RawBlock(bitLength: bitLength, data: data.data)

proc writeSerialisedTo*(rawBlock: RawBlock, bitWriter: BitWriter) =
  bitWriter.writeBits(bitLengthFieldBitLength, rawBlock.bitLength.uint16)
  bitWriter.writeSeq(rawBlock.bitLength, rawBlock.data)

proc readRaw*(bitReader: BitReader, bits: int = maxDataBitLength): RawBlock =
  let data = readSeq(bitReader, bits, uint8)
  RawBlock(bitLength: data.bitLength, data: data.data)

proc writeRawTo*(rawBlock: RawBlock, bitWriter: BitWriter) =
  bitWriter.writeSeq(rawBlock.bitLength, rawBlock.data)
