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
import ../bitio/bitreader
import ../lzss/listpolyfill, ../lzss/lzssnode, ../lzss/lzsschain
import ../huffman/huffmantree, ../huffman/huffmandecoder
import lzsshuffmansymbol

proc readChain*(bitReader: BitReader, symbolDecoder, positionDecoder: HuffmanDecoder[uint16], maxDataByteLength: int): LzssChain =
  var chain = lzssChain()
  var (symbol, byteCursor) = (symbolDecoder.decode(bitReader).Symbol, 0)
  while not symbol.isEndMarker():
    if byteCursor > maxDataByteLength: raise newException(IOError, "lzss block too long")
    if symbol.isCharacter():
      chain.append(lzssCharacter(symbol.uint8))
    else:
      let position = positionDecoder.decode(bitReader)
      chain.append(unpackLzssReference(symbol, position))
    (symbol, byteCursor) = (symbolDecoder.decode(bitReader).Symbol, byteCursor + 1)
  chain
