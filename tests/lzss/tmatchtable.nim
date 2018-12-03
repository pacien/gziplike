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
import lzss/matchring, lzss/matchtable

suite "matchtable":
  test "addMatch":
    var matchTable = initMatchTable()
    matchTable.addMatch([0'u8, 1, 2], 42)
    matchTable.addMatch([2'u8, 1, 0], 24)
    check toSeq(matchTable.candidates([0'u8, 1, 2]).items) == [42]
    check toSeq(matchTable.candidates([2'u8, 1, 0]).items) == [24]
    matchTable.addMatch([0'u8, 1, 2], 1337)
    check toSeq(matchTable.candidates([0'u8, 1, 2]).items) == [1337, 42]
    check toSeq(matchTable.candidates([2'u8, 1, 0]).items) == [24]
