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

import sequtils
import bitio/integers, bitio/bitreader, bitio/bitwriter
import rawblock, lzssblock

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

proc isLast*(streamBlock: StreamBlock): bool =
  streamBlock.last

proc readSerialised*(bitReader: BitReader): StreamBlock =
  result.last = bitReader.readBool()
  result.kind = bitReader.readBits(2, uint8).BlockKind
  case result.kind:
    of uncompressed: result.rawBlock = rawblock.readSerialised(bitReader)
    of lzss: result.lzssBlock = lzssblock.readSerialised(bitReader)
    else: raise newException(ValueError, "unhandled block type")

proc writeSerialisedTo*(streamBlock: StreamBlock, bitWriter: BitWriter) =
  bitWriter.writeBool(streamBlock.last)
  bitWriter.writeBits(2, streamBlock.kind.uint8)
  case streamBlock.kind:
    of uncompressed: streamBlock.rawBlock.writeSerialisedTo(bitWriter)
    of lzss: streamBlock.lzssBlock.writeSerialisedTo(bitWriter)
    else: raise newException(ValueError, "unhandled block type")

proc readRaw*(bitReader: BitReader, kind: BlockKind = uncompressed): StreamBlock =
  result.kind = kind
  case kind:
    of uncompressed: result.rawBlock = rawblock.readRaw(bitReader)
    of lzss: result.lzssBlock = lzssblock.readRaw(bitReader)
    else: raise newException(ValueError, "unhandled block type")
  result.last = bitReader.atEnd()

proc writeRawTo*(streamBlock: StreamBlock, bitWriter: BitWriter) =
  case streamBlock.kind:
    of uncompressed: streamBlock.rawBlock.writeRawTo(bitWriter)
    of lzss: streamBlock.lzssBlock.writeRawTo(bitWriter)
    else: raise newException(ValueError, "unhandled block type")
