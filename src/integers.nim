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

const wordBitLength* = 8
const wordBitMask* = 0b1111_1111'u8

proc `/^`*[T: Natural](x, y: T): T =
  (x + y - 1) div y

proc truncateToUint8*(x: SomeUnsignedInt): uint8 =
  (x and wordBitMask).uint8

iterator chunks*(totalBitLength: int, chunkType: typedesc[SomeInteger]): tuple[index: int, chunkBitLength: int] =
  let chunkBitLength = sizeof(chunkType) * wordBitLength
  let wordCount = totalBitLength div chunkBitLength
  for i in 0..<(wordCount): yield (i, chunkBitLength)
  let remainder = totalBitLength mod chunkBitLength
  if remainder > 0: yield (wordCount, remainder)
