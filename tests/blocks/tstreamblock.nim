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

import unittest, streams
import bitio/bitreader, bitio/bitwriter, blocks/streamblock

suite "streamblock":
  test "serialise":
    let rawStream = newStringStream()
    defer: rawStream.close()
    rawStream.write(0xFEDC_BA98_7654_3210'u64)
    rawStream.setPosition(0)
    let rawBitReader = rawStream.bitReader()
    let streamBlock = readRaw(rawBitReader, uncompressed)
    check streamBlock.isLast()

    let outputStream = newStringStream()
    defer: outputStream.close()
    let outputBitWriter = outputStream.bitWriter()
    streamBlock.writeSerialisedTo(outputBitWriter)
    outputBitWriter.flush()

    outputStream.setPosition(0)
    let produceReader = outputStream.bitReader()
    check produceReader.readBool() == true # last block flag
    check produceReader.readBits(2, uint8) == 0x00'u8 # block kind
    check produceReader.readBits(16, uint16) == 64 # raw block length
    check produceReader.readSeq(64, uint8) == (64, @[0x10'u8, 0x32, 0x54, 0x76, 0x98, 0xBA, 0xDC, 0xFE]) # raw block content
    discard produceReader.readBits(8 - 2 - 1, uint8)
    check produceReader.atEnd()

  test "deserialise":
    let serialisedStream = newStringStream()
    defer: serialisedStream.close()
    let serialisedBitWriter = serialisedStream.bitWriter()
    serialisedBitWriter.writeBool(true)
    serialisedBitWriter.writeBits(2, 0x00'u8)
    serialisedBitWriter.writeBits(16, 64'u16)
    serialisedBitWriter.writeBits(64, 0xFEDC_BA98_7654_3210'u64)
    serialisedBitWriter.flush()

    serialisedStream.setPosition(0)
    let serialisedBitReader = serialisedStream.bitReader()
    let streamBlock = streamblock.readSerialised(serialisedBitReader)

    let outputStream = newStringStream()
    defer: outputStream.close()
    let outputBitWriter = outputStream.bitWriter()
    check streamBlock.isLast()
    streamBlock.writeRawTo(outputBitWriter)
    outputBitWriter.flush()

    outputStream.setPosition(0)
    check outputStream.readUint64 == 0xFEDC_BA98_7654_3210'u64
    check outputStream.atEnd()
