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

# Stream functions

proc newEIO(msg: string): ref IOError =
  new(result)
  result.msg = msg

proc read[T](s: Stream, t: typedesc[T]): T =
  if readData(s, addr(result), sizeof(T)) != sizeof(T):
    raise newEIO("cannot read from stream")

proc peek[T](s: Stream, t: typedesc[T]): T =
  if peekData(s, addr(result), sizeof(T)) != sizeof(T):
    raise newEIO("cannot read from stream")

# BitReader

type BitReader* = ref object
  stream: Stream
  bitOffset: int

proc bitReader*(stream: Stream): BitReader =
  BitReader(stream: stream, bitOffset: 0)

proc atEnd*(bitReader: BitReader): bool =
  bitReader.stream.atEnd()

proc readBits*[T: SomeUnsignedInt](bitReader: BitReader, bits: int, to: typedesc[T]): T =
  let targetBitLength = sizeof(T) * wordBitLength
  if bits < 0 or bits > targetBitLength:
    raise newException(RangeError, "invalid bit length")
  elif bits == 0:
    result = 0
  elif bits < targetBitLength - bitReader.bitOffset:
    result = bitReader.stream.peek(T) shl (targetBitLength - bits - bitReader.bitOffset) shr (targetBitLength - bits)
  elif bits == targetBitLength - bitReader.bitOffset:
    result = bitReader.stream.read(T) shl (targetBitLength - bits - bitReader.bitOffset) shr (targetBitLength - bits)
  else:
    let rightBits = targetBitLength - bitReader.bitOffset
    let leftBits = bits - rightBits
    let right = bitReader.stream.read(T) shr bitReader.bitOffset
    let left = bitReader.stream.peek(T) shl (targetBitLength - leftBits) shr (targetBitLength - bits)
    result = left or right
  bitReader.bitOffset = (bitReader.bitOffset + bits) mod wordBitLength

proc readBool*(bitReader: BitReader): bool =
  bitReader.readBits(1, uint8) != 0

proc readSeq*[T: SomeUnsignedInt](bitReader: BitReader, bitLength: int, to: typedesc[T]): tuple[bitLength: int, data: seq[T]] =
  result = (0, newSeqOfCap[T](bitLength /^ (sizeof(T) * wordBitLength)))
  for _, chunkBitLength in chunks(bitLength, T):
    if bitReader.atEnd(): return
    result.bitLength += chunkBitLength
    result.data.add(bitReader.readBits(chunkBitLength, T))
