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

import tables, lists
import polyfill

type MatchTable*[K, V] =
  TableRef[K, SinglyLinkedList[V]]

proc initMatchTable*[K, V](keyType: typedesc[K], valueType: typedesc[V]): MatchTable[K, V] =
  newTable[K, SinglyLinkedList[V]]()

proc matchList*[K, V](matchTable: MatchTable[K, V], pattern: K): SinglyLinkedList[V] =
  matchTable.getOrDefault(pattern, initSinglyLinkedList[V]())

proc addMatch*[K, V](matchTable: MatchTable[K, V], pattern: K, value: V) =
  var matchList = matchTable.matchList(pattern)
  polyfill.prepend(matchList, value)
  matchTable[pattern] = matchList
