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

import sequtils
import integers, bitstream, rawblock, lzssblock

type BlockKind* = enum
  uncompressed = 0b00'u8,
  lzss = 0b01,
  reserved1 = 0b10,
  reserved2 = 0b11

type StreamBlock* = object
  last: bool
  case kind: BlockKind
    of uncompressed:
      rawBlock: RawBlock
    of lzss:
      lzssBlock: LzssBlock
    else:
      discard

proc readSerialised*(bitStream: BitStream): StreamBlock =
  result.last = bitStream.readBool()
  result.kind = bitStream.readBits(2, uint8).BlockKind
  case result.kind:
    of uncompressed: result.rawBlock = rawblock.readRaw(bitStream)
    of lzss: result.lzssBlock = lzssblock.readRaw(bitStream)
    else: raise newException(ValueError, "unhandled block type")

proc writeSerialisedTo*(streamBlock: StreamBlock, bitStream: BitStream) =
  bitStream.writeBool(streamBlock.last)
  bitStream.writeBits(2, streamBlock.kind.uint8)
  case streamBlock.kind:
    of uncompressed: streamBlock.rawBlock.writeSerialisedTo(bitStream)
    of lzss: streamBlock.lzssBlock.writeSerialisedTo(bitStream)
    else: raise newException(ValueError, "unhandled block type")

proc readRaw*(bitStream: BitStream, kind: BlockKind = uncompressed): StreamBlock =
  result.kind = kind
  case kind:
    of uncompressed: result.rawBlock = rawblock.readRaw(bitStream)
    of lzss: result.lzssBlock = lzssblock.readRaw(bitStream)
    else: raise newException(ValueError, "unhandled block type")
  result.last = bitStream.atEnd()

proc writeRawTo*(streamBlock: StreamBlock, bitStream: BitStream) =
  case streamBlock.kind:
    of uncompressed: streamBlock.rawBlock.writeRawTo(bitStream)
    of lzss: streamBlock.lzssBlock.writeRawTo(bitStream)
    else: raise newException(ValueError, "unhandled block type")
