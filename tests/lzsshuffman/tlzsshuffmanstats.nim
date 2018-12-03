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

import unittest, tables, sequtils
import lzss/lzssnode, lzss/lzsschain
import lzsshuffman/lzsshuffmansymbol, lzsshuffman/lzsshuffmanstats

suite "lzsshuffmanstats":
  test "aggretateStats":
    let chain = lzssChain([
      lzssCharacter(0), lzssCharacter(1), lzssCharacter(2),
      lzssCharacter(3), lzssCharacter(4), lzssCharacter(5),
      lzssReference(4, 6), lzssCharacter(0), lzssCharacter(1),
      lzssReference(3, 8), lzssCharacter(5),
      lzssReference(3, 3), lzssCharacter(5)])
    let (symbolTable, positionTable) = chain.aggregateStats()
    check symbolTable == newCountTable(concat(
      repeat(0'u16, 2), repeat(1'u16, 2), repeat(2'u16, 1), repeat(3'u16, 1), repeat(4'u16, 1), repeat(5'u16, 3),
      repeat(endSymbol.uint16, 1),
      repeat(257'u16, 2), repeat(258'u16, 1)))
    check positionTable == newCountTable(concat(
      repeat(3'u16, 1), repeat(6'u16, 1), repeat(8'u16, 1)))
