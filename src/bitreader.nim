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

import streams
import integers

type BitReader* = ref object
  stream: Stream
  bitOffset: int
  overflowBuffer: uint8

proc bitReader*(stream: Stream): BitReader =
  BitReader(stream: stream, bitOffset: 0, overflowBuffer: 0)

proc atEnd*(bitReader: BitReader): bool =
  bitReader.bitOffset == 0 and bitReader.stream.atEnd()

proc readBits*[T: SomeUnsignedInt](bitReader: BitReader, bits: int, to: typedesc[T]): T =
  if bits < 0 or bits > sizeof(T) * wordBitLength: raise newException(RangeError, "invalid bit length")
  if bits == 0: return 0
  var bitsRead = 0
  if bitReader.bitOffset > 0:
    let bitsFromBuffer = min(bits, wordBitLength - bitReader.bitOffset)
    result = (bitReader.overflowBuffer shr bitReader.bitOffset).leastSignificantBits(bitsFromBuffer)
    bitReader.bitOffset = (bitReader.bitOffset + bitsFromBuffer) mod wordBitLength
    bitsRead += bitsFromBuffer
  while bits - bitsRead >= wordBitLength:
    result = result or (bitReader.stream.readUint8().T shl bitsRead)
    bitsRead += wordBitLength
  if bits - bitsRead > 0:
    bitReader.overflowBuffer = bitReader.stream.readUint8()
    bitReader.bitOffset = bits - bitsRead
    result = result or (bitReader.overflowBuffer.leastSignificantBits(bitReader.bitOffset).T shl bitsRead)

proc readBool*(bitReader: BitReader): bool =
  bitReader.readBits(1, uint8) != 0

proc readSeq*[T: SomeUnsignedInt](bitReader: BitReader, bitLength: int, to: typedesc[T]): tuple[bitLength: int, data: seq[T]] =
  result = (0, newSeqOfCap[T](bitLength /^ (sizeof(T) * wordBitLength)))
  for _, chunkBitLength in chunks(bitLength, T):
    if bitReader.atEnd(): return
    result.bitLength += chunkBitLength
    result.data.add(bitReader.readBits(chunkBitLength, T))
