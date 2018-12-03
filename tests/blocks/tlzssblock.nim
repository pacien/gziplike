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
import bitio/bitreader, bitio/bitwriter, blocks/lzssblock

suite "lzssblock":
  test "identity":
    let value = 0xFEDC_BA98_7654_3210'u64
    let rawStream = newStringStream()
    defer: rawStream.close()
    rawStream.write(value)
    rawStream.setPosition(0)
    let rawBitReader = rawStream.bitReader()
    let rawBlock = lzssblock.readRaw(rawBitReader)

    let serialisedStream = newStringStream()
    defer: serialisedStream.close()
    let serialisedBitWriter = serialisedStream.bitWriter()
    rawBlock.writeSerialisedTo(serialisedBitWriter)
    serialisedBitWriter.flush()

    serialisedStream.setPosition(0)
    let serialisedBitReader = serialisedStream.bitReader()
    let lzssBlock = lzssblock.readSerialised(serialisedBitReader)

    let outputStream = newStringStream()
    defer: outputStream.close()
    let outputBitWriter = outputStream.bitWriter()
    rawBlock.writeRawTo(outputBitWriter)
    outputBitWriter.flush()

    outputStream.setPosition(0)
    check outputStream.readUint64 == value
    check outputStream.atEnd()
