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
import ../lzss/lzssnode, ../lzss/lzsschain
import lzsshuffmansymbol

proc aggregateStats*(chain: LzssChain): tuple[symbolTable, positionTable: CountTableRef[uint16]] =
  var (symbolTable, positionTable) = (newCountTable[uint16](), newCountTable[uint16]())
  for node in chain.items:
    case node.kind:
      of character:
        symbolTable.inc(node.character)
      of reference:
        symbolTable.inc(shiftLzssLength(node.length))
        positionTable.inc(node.relativePos.uint16)
  symbolTable.inc(endSymbol)
  if positionTable.len < 1: positionTable.inc(0) # ensure non-empty tree
  (symbolTable, positionTable)
