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

import unittest, sequtils, tables
import polyfill, lzssnode, lzsschain

suite "lzsschain":
  proc chain(): LzssChain =
    let chainArray = [
      lzssCharacter(0), lzssCharacter(1), lzssCharacter(2),
      lzssCharacter(3), lzssCharacter(4), lzssCharacter(5),
      lzssReference(4, 6), lzssCharacter(0), lzssCharacter(1),
      lzssReference(3, 8), lzssCharacter(5),
      lzssReference(3, 3), lzssCharacter(5)]
    var chain = lzssChain()
    for node in chainArray: chain.append(node)
    result = chain

  test "decode":
    check chain().decode() == @[0'u8, 1, 2, 3, 4, 5, 0, 1, 2, 3, 0, 1, 4, 5, 0, 5, 5, 0, 5, 5]

  test "stats":
    let stats = chain().stats()
    check stats.characters == newCountTable(concat(
      repeat(0'u8, 2), repeat(1'u8, 2), repeat(2'u8, 1), repeat(3'u8, 1), repeat(4'u8, 1), repeat(5'u8, 3)))
    check stats.lengths == newCountTable(concat(
      repeat(3, 2), repeat(4, 1)))
    check stats.positions == newCountTable(concat(
      repeat(3, 1), repeat(6, 1), repeat(8, 1)))
