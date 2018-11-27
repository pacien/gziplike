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

import unittest, sugar, lists, tables
import polyfill

suite "polyfill":
  test "SinglyLinkedList append":
    const data = [1, 2, 3, 4, 5, 6]
    var L: SinglyLinkedList[int]
    for d in items(data): polyfill.prepend(L, d)
    for d in items(data): polyfill.append(L, d)
    check $L == "[6, 5, 4, 3, 2, 1, 1, 2, 3, 4, 5, 6]"
    check 4 in L
