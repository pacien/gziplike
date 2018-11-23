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

import unittest, streams, sugar, sequtils
import integers, bitstream

suite "bitstream":
  test "chunks iterator":
    check toSeq(chunks(70, uint32)) == @[(0, 32), (1, 32), (2, 6)]
    check toSeq(chunks(32, uint16)) == @[(0, 16), (1, 16)]

  test "flush":
    let stream = newStringStream()
    defer: stream.close()
    let bitStream = stream.bitStream()

    bitStream.writeBool(true)
    stream.setPosition(0)
    expect IOError: discard stream.peekUint8()
  
    bitStream.flush()
    stream.setPosition(0)
    check stream.readUint8() == 0x01'u8
    check stream.atEnd()

    bitStream.flush()
    check stream.atEnd()

  test "readBool":
    let stream = newStringStream()
    defer: stream.close()
    stream.write(0b1001_1111'u8)
    stream.write(0b0110_0000'u8)
    stream.setPosition(0)
    
    let bitStream = stream.bitStream()
    check lc[bitStream.readBool() | (_ <- 0..<16), bool] == @[
      true, true, true, true, true, false, false, true,
      false, false, false, false, false, true, true, false]

    expect IOError: discard bitStream.readBool()
    check bitStream.atEnd()

  test "readBits":
    let stream = newStringStream()
    defer: stream.close()
    stream.write(0xF00F'u16)
    stream.write(0x0FFF'u16)
    stream.setPosition(0)

    let bitStream = stream.bitStream()
    check bitStream.readBits(8, uint8) == 0x0F'u8
    check bitStream.readBits(16, uint16) == 0xFFF0'u16
    check bitStream.readBits(8, uint8) == 0x0F'u8

    expect RangeError: discard bitStream.readBits(9, uint8)
    expect IOError: discard bitStream.readBits(16, uint16)
    check bitStream.atEnd()

  test "readSeq":
    let stream = newStringStream()
    defer: stream.close()
    stream.write(0x0F00_F0FF_F0F0_F0F0'u64)
    stream.setPosition(0)

    let bitStream = stream.bitStream()
    check bitStream.readSeq(32, uint16) == (32, @[0xF0F0'u16, 0xF0F0])
    check bitStream.readSeq(40, uint8) == (32, @[0xFF'u8, 0xF0, 0x00, 0x0F])
    check bitStream.atEnd()

  test "writeBool":
    let stream = newStringStream()
    defer: stream.close()

    let bitStream = stream.bitStream()
    let booleanValues = @[
      true, true, true, true, true, false, false, true,
      false, false, false, false, false, true, true, false,
      true, true, false, true]
    for b in booleanValues: bitStream.writeBool(b)
    bitStream.flush()

    stream.setPosition(0)
    check stream.readUint8() == 0b1001_1111'u8
    check stream.readUint8() == 0b0110_0000'u8
    check stream.readUint8() == 0b0000_1011'u8
    expect IOError: discard stream.readUint8()
    check stream.atEnd()

  test "writeBits":
    let stream = newStringStream()
    defer: stream.close()

    let bitStream = stream.bitStream()
    bitStream.writeBits(4, 0xF00F'u16)
    bitStream.writeBits(16, 0xF00F'u16)
    bitStream.writeBits(16, 0xFFFF'u16)
    bitStream.flush()

    stream.setPosition(0)
    check stream.readUint16() == 0x00FF'u16
    check stream.readUint16() == 0xFFFF'u16
    check stream.readUint8() == 0x0F'u8
    expect IOError: discard stream.readUint8()
    check stream.atEnd()

  test "writeSeq":
    let stream = newStringStream()
    defer: stream.close()

    let bitStream = stream.bitStream()
    bitStream.writeSeq(32, @[0xF0F0'u16, 0xF0F0])
    bitStream.writeSeq(28, @[0xFF'u8, 0xF0, 0x00, 0xFF])
    bitStream.flush()

    stream.setPosition(0)
    check stream.readUint64() == 0x0F00_F0FF_F0F0_F0F0'u64
    check stream.atEnd()
