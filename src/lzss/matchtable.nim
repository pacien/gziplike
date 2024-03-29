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

import tables
import matchring

const matchGroupLength = 3
const hashShift = 5
const tableHeight = 0b1 shl 15

type MatchTable* = object
  table: array[tableHeight, MatchRing]

proc initMatchTable*(): MatchTable =
  result = MatchTable()

proc hash(pattern: array[matchGroupLength, uint8]): int =
  ((pattern[0].int shl (hashShift * 2)) xor (pattern[1].int shl hashShift) xor pattern[2].int) mod tableHeight

proc addMatch*(matchTable: var MatchTable, pattern: array[matchGroupLength, uint8], index: int) =
  matchTable.table[hash(pattern)].addMatch(index)

proc candidates*(matchTable: MatchTable, pattern: array[matchGroupLength, uint8]): MatchRing =
  matchTable.table[hash(pattern)]
