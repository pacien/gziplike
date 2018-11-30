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

import tables, heapqueue
import huffmantree

type WeighedHuffmanTreeNode[T] = ref object
  weight: int
  huffmanTreeNode: HuffmanTreeNode[T]

proc weighedHuffmanBranch[T](left, right: WeighedHuffmanTreeNode[T]): WeighedHuffmanTreeNode[T] =
  WeighedHuffmanTreeNode[T](
    weight: left.weight + right.weight,
    huffmanTreeNode: huffmanBranch(left.huffmanTreeNode, right.huffmanTreeNode))

proc weighedHuffmanLeaf[T](value: T, weight: int): WeighedHuffmanTreeNode[T] =
  WeighedHuffmanTreeNode[T](
    weight: weight,
    huffmanTreeNode: huffmanLeaf(value))

proc `<`*[T](left, right: WeighedHuffmanTreeNode[T]): bool =
  left.weight < right.weight

proc symbolQueue[T](stats: CountTableRef[T]): HeapQueue[WeighedHuffmanTreeNode[T]] =
  result = newHeapQueue[WeighedHuffmanTreeNode[T]]()
  for item, count in stats.pairs: result.push(weighedHuffmanLeaf(item, count))

proc buildHuffmanTree*[T: SomeUnsignedInt](stats: CountTableRef[T]): HuffmanTreeNode[T] =
  var symbolQueue = symbolQueue(stats)
  while symbolQueue.len > 1: symbolQueue.push(weighedHuffmanBranch(symbolQueue.pop(), symbolQueue.pop()))
  symbolQueue[0].huffmanTreeNode
