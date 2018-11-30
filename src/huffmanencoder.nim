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

import tables
import integers, huffmantree, bitio/bitwriter

type HuffmanEncoder*[T, U: SomeUnsignedInt] = object
  codebook: TableRef[T, U]

proc buildCodebook*[T, U](tree: HuffmanTreeNode[T], codeType: typedesc[U]): TableRef[T, U] =
  var codebook = newTable[T, U]()
  proc addCode(node: HuffmanTreeNode[T], path: U, depth: int) =
    case node.kind:
      of branch:
        addCode(node.left, path, depth + 1)
        addCode(node.right, path or (1.U shl depth), depth + 1)
      of leaf:
        codebook[node.value] = path
  addCode(tree, 0.U, 0)
  codebook

proc encoder*[T, U](tree: HuffmanTreeNode[T], codeType: typedesc[U]): HuffmanEncoder[T, U] =
  HuffmanEncoder[T, U](codebook: buildCodebook(tree, codeType))

proc encode*[T, U](decoder: HuffmanEncoder[T, U], value: T): U =
  decoder.codebook[value]
