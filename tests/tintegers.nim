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

import unittest, sequtils
import integers

suite "integers":
  test "Round-up integer division":
    check 42 /^ 2 == 21
    check 43 /^ 2 == 22

  test "truncateToUint8":
    check truncateToUint8(0xFA'u8) == 0xFA'u8
    check truncateToUint8(0x00FA'u16) == 0xFA'u8
    check truncateToUint8(0xFFFA'u16) == 0xFA'u8

  test "leastSignificantBits":
    check leastSignificantBits(0xFF'u8, 3) == 0b0000_0111'u8
    check leastSignificantBits(0b0001_0101'u8, 3) == 0b0000_0101'u8
    check leastSignificantBits(0xFF'u8, 10) == 0xFF'u8
    check leastSignificantBits(0xFFFF'u16, 16) == 0xFFFF'u16
    check leastSignificantBits(0xFFFF'u16, 8) == 0x00FF'u16

  test "chunks iterator":
    check toSeq(chunks(70, uint32)) == @[(0, 32), (1, 32), (2, 6)]
    check toSeq(chunks(32, uint16)) == @[(0, 16), (1, 16)]
