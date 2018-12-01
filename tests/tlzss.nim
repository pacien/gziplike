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

import unittest, sequtils, tables, lists
import lzss/matchtable, lzss/lzssnode, lzss/lzsschain, lzss/lzssencoder

suite "matchtable":
  test "matchList":
    let matchTable = initMatchTable(seq[int], int)
    check matchTable.matchList(@[0, 1, 2]).len == 0

  test "addMatch":
    let matchTable = initMatchTable(seq[int], int)
    matchTable.addMatch(@[0, 1, 2], 42)
    matchTable.addMatch(@[2, 1, 0], 24)
    check matchTable.len == 2
    check matchTable.matchList(@[0, 1, 2]) == [42]
    check matchTable.matchList(@[2, 1, 0]) == [24]
    matchTable.addMatch(@[0, 1, 2], 1337)
    check matchTable.len == 2
    check matchTable.matchList(@[0, 1, 2]) == [1337, 42]
    check matchTable.matchList(@[2, 1, 0]) == [24]

suite "lzssnode":
  test "equality":
    check lzssCharacter(1) == lzssCharacter(1)
    check lzssCharacter(0) != lzssCharacter(1)
    check lzssReference(0, 1) == lzssReference(0, 1)
    check lzssReference(1, 0) != lzssReference(0, 1)
    check lzssCharacter(0) != lzssReference(0, 1)

suite "lzsschain":
  test "decode":
    let chain = lzssChain([
      lzssCharacter(0), lzssCharacter(1), lzssCharacter(2),
      lzssCharacter(3), lzssCharacter(4), lzssCharacter(5),
      lzssReference(4, 6), lzssCharacter(0), lzssCharacter(1),
      lzssReference(3, 8), lzssCharacter(5),
      lzssReference(3, 3), lzssCharacter(5)])
    check chain.decode() == @[0'u8, 1, 2, 3, 4, 5, 0, 1, 2, 3, 0, 1, 4, 5, 0, 5, 5, 0, 5, 5]
 
suite "lzssencoder":
  test "commonPrefixLength":
    check commonPrefixLength([], [], 0, 10) == 0
    check commonPrefixLength([1'u8, 2], [1'u8, 2, 3], 0, 10) == 2
    check commonPrefixLength([1'u8, 2], [1'u8, 2, 3], 1, 10) == 2
    check commonPrefixLength([1'u8, 2, 3], [1'u8, 2, 4], 1, 10) == 2
    check commonPrefixLength([1'u8, 2, 3, 4], [1'u8, 2, 3, 4], 1, 3) == 3

  test "longestPrefix":
    let buffer = [
      0'u8, 1, 2, 9,
      0, 1, 2, 3,
      0, 1, 2,
      0, 1, 2, 3, 4]
    var candidatePos = [0, 4, 8]
    let result = longestPrefix(candidatePos, buffer.toOpenArray(0, 10), buffer.toOpenArray(11, buffer.len - 1))
    check result.pos == 4
    check result.length == 4

  test "addGroups":
    let matchTable = initMatchTable(seq[uint8], int)
    let buffer = toSeq(0'u8..10'u8)
    matchTable.addGroups(buffer, 0, 1)
    check matchTable.len == 0
    matchTable.addGroups(buffer, 2, 9)
    check matchTable.len == 5
    check matchTable.matchList(@[1'u8, 2, 3]).len == 0
    check matchTable.matchList(@[7'u8, 8, 9]).len == 0
    check matchTable.matchList(@[2'u8, 3, 4]) == [2]
    check matchTable.matchList(@[4'u8, 5, 6]) == [4]
    check matchTable.matchList(@[6'u8, 7, 8]) == [6]

  test "lzssEncode":
    let buffer = [0'u8, 1, 2, 3, 4, 5, 0, 1, 2, 3, 0, 1, 4, 5, 0, 5, 5, 0, 5, 5]
    check lzssEncode(buffer) == [
      lzssCharacter(0), lzssCharacter(1), lzssCharacter(2),
      lzssCharacter(3), lzssCharacter(4), lzssCharacter(5),
      lzssReference(4, 6), lzssCharacter(0), lzssCharacter(1),
      lzssReference(3, 8), lzssCharacter(5),
      lzssReference(3, 3), lzssCharacter(5)]
