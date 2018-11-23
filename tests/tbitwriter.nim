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
import integers, bitwriter

suite "bitwriter":
  test "flush":
    let stream = newStringStream()
    defer: stream.close()
    let bitWriter = stream.bitWriter()

    bitWriter.writeBool(true)
    stream.setPosition(0)
    expect IOError: discard stream.peekUint8()
  
    bitWriter.flush()
    stream.setPosition(0)
    check stream.readUint8() == 0x01'u8
    check stream.atEnd()

    bitWriter.flush()
    check stream.atEnd()

  test "writeBool":
    let stream = newStringStream()
    defer: stream.close()

    let bitWriter = stream.bitWriter()
    let booleanValues = @[
      true, true, true, true, true, false, false, true,
      false, false, false, false, false, true, true, false,
      true, true, false, true]
    for b in booleanValues: bitWriter.writeBool(b)
    bitWriter.flush()

    stream.setPosition(0)
    check stream.readUint8() == 0b1001_1111'u8
    check stream.readUint8() == 0b0110_0000'u8
    check stream.readUint8() == 0b0000_1011'u8
    expect IOError: discard stream.readUint8()
    check stream.atEnd()

  test "writeBits":
    let stream = newStringStream()
    defer: stream.close()

    let bitWriter = stream.bitWriter()
    bitWriter.writeBits(4, 0xF00F'u16)
    bitWriter.writeBits(16, 0xF00F'u16)
    bitWriter.writeBits(16, 0xFFFF'u16)
    bitWriter.flush()

    stream.setPosition(0)
    check stream.readUint16() == 0x00FF'u16
    check stream.readUint16() == 0xFFFF'u16
    check stream.readUint8() == 0x0F'u8
    expect IOError: discard stream.readUint8()
    check stream.atEnd()

  test "writeSeq":
    let stream = newStringStream()
    defer: stream.close()

    let bitWriter = stream.bitWriter()
    bitWriter.writeSeq(32, @[0xF0F0'u16, 0xF0F0])
    bitWriter.writeSeq(28, @[0xFF'u8, 0xF0, 0x00, 0xFF])
    bitWriter.flush()

    stream.setPosition(0)
    check stream.readUint64() == 0x0F00_F0FF_F0F0_F0F0'u64
    check stream.atEnd()
