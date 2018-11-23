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

# Utils

iterator chunks*(totalBitLength: int, chunkType: typedesc[SomeInteger]): tuple[index: int, chunkBitLength: int] =
  let chunkBitLength = sizeof(chunkType) * wordBitLength
  let wordCount = totalBitLength div chunkBitLength
  for i in 0..<(wordCount): yield (i, chunkBitLength)
  let remainder = totalBitLength mod chunkBitLength
  if remainder > 0: yield (wordCount, remainder)

# BitStream

type BitStream* = ref object
  stream: Stream
  bitOffset: int
  writeBuffer: uint8

proc bitStream*(stream: Stream): BitStream =
  BitStream(stream: stream, bitOffset: 0, writeBuffer: 0)

proc flush*(bitStream: BitStream) =
  if bitStream.bitOffset == 0: return
  bitStream.stream.write(bitStream.writeBuffer)
  bitStream.stream.flush()
  (bitStream.bitOffset, bitStream.writeBuffer) = (0, 0'u8)

proc atEnd*(bitStream: BitStream): bool =
  bitStream.stream.atEnd()

proc readBits*[T: SomeUnsignedInt](bitStream: BitStream, bits: int, to: typedesc[T]): T =
  let targetBitLength = sizeof(T) * wordBitLength
  if bits < 0 or bits > targetBitLength:
    raise newException(RangeError, "invalid bit length")
  elif bits == 0:
    result = 0
  elif bits < targetBitLength - bitStream.bitOffset:
    result = bitStream.stream.peek(T) shl (targetBitLength - bits - bitStream.bitOffset) shr (targetBitLength - bits)
  elif bits == targetBitLength - bitStream.bitOffset:
    result = bitStream.stream.read(T) shl (targetBitLength - bits - bitStream.bitOffset) shr (targetBitLength - bits)
  else:
    let rightBits = targetBitLength - bitStream.bitOffset
    let leftBits = bits - rightBits
    let right = bitStream.stream.read(T) shr bitStream.bitOffset
    let left = bitStream.stream.peek(T) shl (targetBitLength - leftBits) shr (targetBitLength - bits)
    result = left or right
  bitStream.bitOffset = (bitStream.bitOffset + bits) mod wordBitLength

proc readBool*(bitStream: BitStream): bool =
  bitStream.readBits(1, uint8) != 0

proc readSeq*[T: SomeUnsignedInt](bitStream: BitStream, bitLength: int, to: typedesc[T]): tuple[bitLength: int, data: seq[T]] =
  result = (0, newSeqOfCap[T](bitLength /^ (sizeof(T) * wordBitLength)))
  for _, chunkBitLength in chunks(bitLength, T):
    if bitStream.atEnd(): return
    result.bitLength += chunkBitLength
    result.data.add(bitStream.readBits(chunkBitLength, T))

proc writeBits*(bitStream: BitStream, bits: int, value: SomeUnsignedInt) =
  let valueContainerBitLength = sizeof(value) * wordBitLength
  if bits < 0 or bits > valueContainerBitLength:
    raise newException(RangeError, "invalid bit length")
  var bitsToWrite = bits
  if bitsToWrite + bitStream.bitOffset >= wordBitLength:
    bitStream.stream.write(truncateToUint8(value shl bitStream.bitOffset) or bitStream.writeBuffer)
    bitsToWrite -= wordBitLength - bitStream.bitOffset
    (bitStream.bitOffset, bitStream.writeBuffer) = (0, 0'u8)
  while bitsToWrite >= wordBitLength:
    bitStream.stream.write(truncateToUint8(value shr (bits - bitsToWrite)))
    bitsToWrite -= wordBitLength
  if bitsToWrite > 0:
    let left = truncateToUint8((value shl (valueContainerBitLength - bits)) shr (valueContainerBitLength - bitsToWrite))
    bitStream.writeBuffer = (left shl bitStream.bitOffset) or bitStream.writeBuffer
    bitStream.bitOffset = (bitStream.bitOffset + bitsToWrite) mod wordBitLength

proc writeBool*(bitStream: BitStream, value: bool) =
  bitStream.writeBits(1, value.uint8)

proc writeSeq*[T: SomeUnsignedInt](bitStream: BitStream, bitLength: int, data: seq[T]) =
  for i, chunkBitLength in chunks(bitLength, T):
    bitStream.writeBits(chunkBitLength, data[i])
