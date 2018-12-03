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
import lzss/matchring, lzss/matchtable, lzss/lzssnode, lzss/lzssencoder

suite "lzssencoder":
  test "commonPrefixLength":
    check commonPrefixLength([], [], 10) == 0
    check commonPrefixLength([1'u8, 2], [1'u8, 2, 3], 10) == 2
    check commonPrefixLength([1'u8, 2], [1'u8, 2, 3], 10) == 2
    check commonPrefixLength([1'u8, 2, 3], [1'u8, 2, 4], 10) == 2
    check commonPrefixLength([1'u8, 2, 3, 4], [1'u8, 2, 3, 4], 3) == 3

  test "longestPrefix":
    let buffer = [
      0'u8, 1, 2, 9,
      0, 1, 2, 3,
      0, 1, 2,
      0, 1, 2, 3, 4]
    var candidatePos = [0, 4, 8]
    var matchRing = initMatchRing()
    for pos in candidatePos: matchRing.addMatch(pos)
    let result = longestPrefix(matchRing, buffer.toOpenArray(0, 10), buffer.toOpenArray(11, buffer.len - 1))
    check result.pos == 4
    check result.length == 4

  test "addGroups":
    var matchTable = initMatchTable()
    let buffer = toSeq(0'u8..10'u8)
    matchTable.addGroups(buffer, 0, 1)
    matchTable.addGroups(buffer, 2, 9)
    check toSeq(matchTable.candidates([1'u8, 2, 3]).items).len == 0
    check toSeq(matchTable.candidates([7'u8, 8, 9]).items).len == 0
    check toSeq(matchTable.candidates([2'u8, 3, 4]).items) == [2]
    check toSeq(matchTable.candidates([4'u8, 5, 6]).items) == [4]
    check toSeq(matchTable.candidates([6'u8, 7, 8]).items) == [6]

  test "lzssEncode":
    let buffer = [0'u8, 1, 2, 3, 4, 5, 0, 1, 2, 3, 0, 1, 4, 5, 0, 5, 5, 0, 5, 5]
    check lzssEncode(buffer) == [
      lzssCharacter(0), lzssCharacter(1), lzssCharacter(2),
      lzssCharacter(3), lzssCharacter(4), lzssCharacter(5),
      lzssReference(4, 6), lzssCharacter(0), lzssCharacter(1),
      lzssReference(3, 8), lzssCharacter(5),
      lzssReference(3, 3), lzssCharacter(5)]
