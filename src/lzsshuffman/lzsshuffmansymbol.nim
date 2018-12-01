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

import lists
import ../lzss/lzssnode, ../lzss/lzssencoder

type Symbol* = uint16

const endSymbol* = 256.Symbol

proc isEndMarker*(symbol: Symbol): bool =
  symbol == endSymbol

proc isCharacter*(symbol: Symbol): bool =
  symbol < endSymbol

proc unpackLzssReference*(symbol: Symbol, position: uint16): LzssNode =
  lzssReference(symbol.int - endSymbol.int - 1 + matchGroupLength, position.int)  

proc shiftLzssLength*(length: int): uint16 =
  (length + endSymbol.int + 1 - matchGroupLength).uint16
