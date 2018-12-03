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

const matchLimit* = 4

type MatchRing* = object
  offset, size: int
  indices: array[matchLimit, int]

proc initMatchRing*(): MatchRing =
  MatchRing()

proc addMatch*(ring: var MatchRing, index: int) =
  if ring.size < matchLimit:
    ring.indices[ring.size] = index
    ring.size += 1
  else:
    let ringIndex = (ring.offset + ring.size) mod matchLimit
    ring.indices[ringIndex] = index
    ring.offset = (ring.offset + 1) mod ring.indices.len

iterator items*(ring: MatchRing): int {.closure.} =
  for i in countdown(ring.size - 1, 0):
    yield ring.indices[(ring.offset + i) mod ring.indices.len]
