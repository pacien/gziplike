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

import unittest
import lzss/lzssnode
import lzsshuffman/lzsshuffmansymbol

suite "lzsshuffmansymbol":
  test "isEndMarker":
    check 'a'.Symbol.isEndMarker() == false
    check endSymbol.isEndMarker()

  test "isCharacter":
    check 'a'.Symbol.isCharacter()
    check endSymbol.isCharacter() == false
    check 300.Symbol.isCharacter() == false
  
  test "unpackLzssReference":
    check unpackLzssReference(257.Symbol, 10) == lzssReference(3, 10)
    check unpackLzssReference(300.Symbol, 10) == lzssReference(46, 10)

  test "shiftLzssLength":
    check shiftLzssLength(3) == 257'u16
    check shiftLzssLength(10) == 264'u16
