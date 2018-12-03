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

import unittest, sequtils, algorithm
import lzss/matchring

suite "matchring":
  test "items (empty)":
    var ring = initMatchRing()
    check toSeq(ring.items).len == 0

  test "addMatch, items (partial)":
    var ring = initMatchRing()
    let items = [0, 1, 2]
    for i in items: ring.addMatch(i)
    check toSeq(ring.items) == items.reversed()

  test "addMatch, items (rolling)":
    var ring = initMatchRing()
    let items = toSeq(0..13)
    for i in items: ring.addMatch(i)
    check toSeq(ring.items) == items[^matchLimit..<items.len].reversed()
