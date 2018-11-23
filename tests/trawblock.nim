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

import unittest, streams
import bitstream, rawblock

suite "rawblock":
  test "serialise":
    let rawStream = newStringStream()
    defer: rawStream.close()
    rawStream.write(0xFEDC_BA98_7654_3210'u64)
    rawStream.setPosition(0)
    let rawBitStream = rawStream.bitStream()
    let rawBlock = rawblock.readRaw(rawBitStream)

    let outputStream = newStringStream()
    defer: outputStream.close()
    let outputBitStream = outputStream.bitStream()
    rawBlock.writeSerialisedTo(outputBitStream)
    outputBitStream.flush()

    outputStream.setPosition(0)
    check outputStream.readUint16() == 64
    check outputStream.readUint64() == 0xFEDC_BA98_7654_3210'u64
    check outputStream.atEnd()

  test "deserialise":
    let serialisedStream = newStringStream()
    defer: serialisedStream.close()
    serialisedStream.write(60'u16)
    serialisedStream.write(0xFEDC_BA98_7654_3210'u64)
    serialisedStream.setPosition(0)
    let serialisedBitStream = serialisedStream.bitStream()
    let rawBlock = rawBlock.readSerialised(serialisedBitStream)

    let outputStream = newStringStream()
    defer: outputStream.close()
    let outputBitStream = outputStream.bitStream()
    rawBlock.writeRawTo(outputBitStream)
    outputBitStream.flush()

    outputStream.setPosition(0)
    check outputStream.readUint64 == 0x0EDC_BA98_7654_3210'u64
    check outputStream.atEnd()
