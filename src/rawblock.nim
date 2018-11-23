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

import integers, bitstream

const maxDataBitLength = 100_000_000 * wordBitLength # 100MB
const bitLengthFieldBitLength = 2 * wordBitLength

type RawBlock* = object
  bitLength: int
  data: seq[uint8]

proc readSerialised*(bitStream: BitStream): RawBlock =
  let bitLength = bitStream.readBits(bitLengthFieldBitLength, uint16).int
  let data = readSeq(bitStream, bitLength, uint8)
  RawBlock(bitLength: bitLength, data: data.data)

proc writeSerialisedTo*(rawBlock: RawBlock, bitStream: BitStream) =
  bitStream.writeBits(bitLengthFieldBitLength, rawBlock.bitLength.uint16)
  writeSeq(bitStream, rawBlock.bitLength, rawBlock.data)

proc readRaw*(bitStream: BitStream, bits: int = maxDataBitLength): RawBlock =
  let data = readSeq(bitStream, bits, uint8)
  RawBlock(bitLength: data.bitLength, data: data.data)

proc writeRawTo*(rawBlock: RawBlock, bitStream: BitStream) =
  writeSeq(bitStream, rawBlock.bitLength, rawBlock.data)
