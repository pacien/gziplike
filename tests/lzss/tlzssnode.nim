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

import unittest
import lzss/lzssnode

suite "lzssnode":
  test "equality":
    check lzssCharacter(1) == lzssCharacter(1)
    check lzssCharacter(0) != lzssCharacter(1)
    check lzssReference(0, 1) == lzssReference(0, 1)
    check lzssReference(1, 0) != lzssReference(0, 1)
    check lzssCharacter(0) != lzssReference(0, 1)
