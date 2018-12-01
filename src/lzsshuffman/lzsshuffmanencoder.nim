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

import ../bitio/bitwriter
import ../lzss/lzssnode, ../lzss/lzsschain, ../lzss/lzssencoder
import ../huffman/huffmantree, ../huffman/huffmantreebuilder, ../huffman/huffmanencoder
import lzsshuffmansymbol

proc writeSymbol(bitWriter: BitWriter, encodedSymbol: tuple[bitLength: int, value: uint16]) =
  bitWriter.writeBits(encodedSymbol.bitLength, encodedSymbol.value)

proc writeChain*(lzssChain: LzssChain, symbolEncoder, positionEncoder: HuffmanEncoder[uint16, uint16], bitWriter: BitWriter) =
  for node in lzssChain:
    case node.kind:
      of character:
        bitWriter.writeSymbol(symbolEncoder.encode(node.character))
      of reference:
        bitWriter.writeSymbol(symbolEncoder.encode(shiftLzssLength(node.length)))
        bitWriter.writeSymbol(positionEncoder.encode(node.relativePos.uint16))
  bitWriter.writeSymbol(symbolEncoder.encode(endSymbol))
