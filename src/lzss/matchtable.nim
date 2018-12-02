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

type MatchTable*[K, V] = ref object
  matchLimit: int
  table: TableRef[K, seq[V]]

proc initMatchTable*[K, V](keyType: typedesc[K], valueType: typedesc[V], matchLimit = 5): MatchTable[K, V] =
  MatchTable[K, V](matchLimit: matchLimit, table: newTable[K, seq[V]]())

proc len*[K, V](matchTable: MatchTable[K, V]): int =
  matchTable.table.len

proc matchList*[K, V](matchTable: MatchTable[K, V], pattern: K): seq[V] =
  if matchTable.table.hasKey(pattern):
    matchTable.table[pattern]
  else:
    newSeqOfCap[V](matchTable.matchLimit)

proc addMatch*[K, V](matchTable: MatchTable[K, V], pattern: K, value: V) =
  var matchList = matchTable.matchList(pattern)
  if matchList.len >= matchTable.matchLimit: matchList.del(matchList.len - 1)
  matchList.insert(value)
  matchTable.table[pattern] = matchList
