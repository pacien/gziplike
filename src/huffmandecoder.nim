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

import huffmantree, bitreader

type HuffmanDecoder*[T: SomeUnsignedInt] = object
  tree: HuffmanTreeNode[T]

proc decoder*[T](tree: HuffmanTreeNode[T]): HuffmanDecoder[T] =
  HuffmanDecoder[T](tree: tree)

proc decode*[T](decoder: HuffmanDecoder[T], bitReader: BitReader): T =
  proc walk(node: HuffmanTreeNode[T]): T =
    case node.kind:
      of branch:
        case bitReader.readBool():
          of false: walk(node.left)
          of true: walk(node.right)
      of leaf:
        node.value
  walk(decoder.tree)
