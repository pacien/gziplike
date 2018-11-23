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

import streams
import integers

type BitWriter* = ref object
  stream: Stream
  bitOffset: int
  writeBuffer: uint8

proc bitWriter*(stream: Stream): BitWriter =
  BitWriter(stream: stream, bitOffset: 0, writeBuffer: 0)

proc flush*(bitWriter: BitWriter) =
  if bitWriter.bitOffset == 0: return
  bitWriter.stream.write(bitWriter.writeBuffer)
  bitWriter.stream.flush()
  (bitWriter.bitOffset, bitWriter.writeBuffer) = (0, 0'u8)

proc atEnd*(bitWriter: BitWriter): bool =
  bitWriter.stream.atEnd()

proc writeBits*(bitWriter: BitWriter, bits: int, value: SomeUnsignedInt) =
  let valueContainerBitLength = sizeof(value) * wordBitLength
  if bits < 0 or bits > valueContainerBitLength:
    raise newException(RangeError, "invalid bit length")
  var bitsToWrite = bits
  if bitsToWrite + bitWriter.bitOffset >= wordBitLength:
    bitWriter.stream.write(truncateToUint8(value shl bitWriter.bitOffset) or bitWriter.writeBuffer)
    bitsToWrite -= wordBitLength - bitWriter.bitOffset
    (bitWriter.bitOffset, bitWriter.writeBuffer) = (0, 0'u8)
  while bitsToWrite >= wordBitLength:
    bitWriter.stream.write(truncateToUint8(value shr (bits - bitsToWrite)))
    bitsToWrite -= wordBitLength
  if bitsToWrite > 0:
    let left = truncateToUint8((value shl (valueContainerBitLength - bits)) shr (valueContainerBitLength - bitsToWrite))
    bitWriter.writeBuffer = (left shl bitWriter.bitOffset) or bitWriter.writeBuffer
    bitWriter.bitOffset = (bitWriter.bitOffset + bitsToWrite) mod wordBitLength

proc writeBool*(bitWriter: BitWriter, value: bool) =
  bitWriter.writeBits(1, value.uint8)

proc writeSeq*[T: SomeUnsignedInt](bitWriter: BitWriter, bitLength: int, data: seq[T]) =
  for i, chunkBitLength in chunks(bitLength, T):
    bitWriter.writeBits(chunkBitLength, data[i])
