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

import lists, tables, sugar
import polyfill, integers, lzssnode

const maxChainByteLength = 32_000 * wordBitLength

type LzssChain* =
  SinglyLinkedList[LzssNode]

proc lzssChain*(): LzssChain =
  initSinglyLinkedList[LzssNode]()

proc decode*(lzssChain: LzssChain): seq[uint8] =
  result = newSeqOfCap[uint8](maxChainByteLength)
  for node in lzssChain.items:
    case node.kind:
      of character:
        result.add(node.character)
      of reference:
        let absolutePos = result.len - node.relativePos
        result.add(result.toOpenArray(absolutePos, absolutePos + node.length - 1))
