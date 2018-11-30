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

import unittest, streams, sugar, sequtils
import bitio/integers, bitio/bitreader, bitio/bitwriter

suite "integers":
  test "Round-up integer division":
    check 42 /^ 2 == 21
    check 43 /^ 2 == 22

  test "truncateToUint8":
    check truncateToUint8(0xFA'u8) == 0xFA'u8
    check truncateToUint8(0x00FA'u16) == 0xFA'u8
    check truncateToUint8(0xFFFA'u16) == 0xFA'u8

  test "bitLength":
    check bitLength(0b1_1111) == 5
    check bitLength(0b1000_0000) == 8

  test "leastSignificantBits":
    check leastSignificantBits(0xFF'u8, 3) == 0b0000_0111'u8
    check leastSignificantBits(0b0001_0101'u8, 3) == 0b0000_0101'u8
    check leastSignificantBits(0xFF'u8, 10) == 0xFF'u8
    check leastSignificantBits(0xFFFF'u16, 16) == 0xFFFF'u16
    check leastSignificantBits(0xFFFF'u16, 8) == 0x00FF'u16

  test "chunks iterator":
    check toSeq(chunks(70, uint32)) == @[(0, 32), (1, 32), (2, 6)]
    check toSeq(chunks(32, uint16)) == @[(0, 16), (1, 16)]

suite "bitreader":
  test "readBool":
    let stream = newStringStream()
    defer: stream.close()
    stream.write(0b1001_1111'u8)
    stream.write(0b0110_0000'u8)
    stream.setPosition(0)
    
    let bitReader = stream.bitReader()
    check lc[bitReader.readBool() | (_ <- 0..<16), bool] == @[
      true, true, true, true, true, false, false, true,
      false, false, false, false, false, true, true, false]

    expect IOError: discard bitReader.readBool()
    check bitReader.atEnd()

  test "readBits":
    let stream = newStringStream()
    defer: stream.close()
    stream.write(0xF00F'u16)
    stream.write(0x0FFF'u16)
    stream.setPosition(0)

    let bitReader = stream.bitReader()
    check bitReader.readBits(8, uint8) == 0x0F'u8
    check bitReader.readBits(16, uint16) == 0xFFF0'u16
    check bitReader.readBits(8, uint8) == 0x0F'u8

    expect RangeError: discard bitReader.readBits(9, uint8)
    expect IOError: discard bitReader.readBits(16, uint16)
    check bitReader.atEnd()

  test "readBits (look-ahead overflow)":
    let stream = newStringStream()
    defer: stream.close()
    stream.write(0xAB'u8)
    stream.setPosition(0)

    let bitReader = stream.bitReader()
    check bitReader.readBits(4, uint16) == 0x000B'u16
    check bitReader.readBits(4, uint16) == 0x000A'u16
    check bitReader.atEnd()

  test "readBits (from buffer composition)":
    let stream = newStringStream()
    defer: stream.close()
    stream.write(0xABCD'u16)
    stream.setPosition(0)

    let bitReader = stream.bitReader()
    check bitReader.readBits(4, uint16) == 0x000D'u16
    check bitReader.readBits(8, uint16) == 0x00BC'u16
    check bitReader.readBits(4, uint16) == 0x000A'u16
    check bitReader.atEnd()

  test "readSeq":
    let stream = newStringStream()
    defer: stream.close()
    stream.write(0x0F00_F0FF_F0F0_F0F0'u64)
    stream.setPosition(0)

    let bitReader = stream.bitReader()
    check bitReader.readSeq(32, uint16) == (32, @[0xF0F0'u16, 0xF0F0])
    check bitReader.readSeq(40, uint8) == (32, @[0xFF'u8, 0xF0, 0x00, 0x0F])
    check bitReader.atEnd()

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
