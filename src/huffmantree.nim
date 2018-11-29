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
import integers, bitreader, bitwriter

const valueLengthFieldBitLength* = 6  # 64

type HuffmanTreeNodeKind* = enum
  branch,
  leaf

type HuffmanTreeNode*[T: SomeUnsignedInt] = ref object
  case kind: HuffmanTreeNodeKind
    of branch:
      left, right: HuffmanTreeNode[T]
    of leaf:
      value: T
  weight: int

proc huffmanBranch*[T](left, right: HuffmanTreeNode[T]): HuffmanTreeNode[T] =
  HuffmanTreeNode[T](kind: branch, left: left, right: right, weight: left.weight + right.weight)

proc huffmanLeaf*[T](value: T, weight = 0): HuffmanTreeNode[T] =
  HuffmanTreeNode[T](kind: leaf, value: value, weight: weight)

proc `==`*[T](a, b: HuffmanTreeNode[T]): bool =
  if a.kind != b.kind or a.weight != b.weight: return false
  case a.kind:
    of branch: a.left == b.left and a.right == b.right
    of leaf: a.value == b.value

proc `~=`*[T](a, b: HuffmanTreeNode[T]): bool =
  if a.kind != b.kind: return false
  case a.kind:
    of branch: a.left ~= b.left and a.right ~= b.right
    of leaf: a.value == b.value

proc `!~`*[T](a, b: HuffmanTreeNode[T]): bool =
  not (a ~= b)

proc `<`*[T](left, right: HuffmanTreeNode[T]): bool =
  left.weight < right.weight

proc maxValue*[T](node: HuffmanTreeNode[T]): T =
  case node.kind:
    of branch: max(node.left.maxValue(), node.right.maxValue())
    of leaf: node.value

proc deserialise*[T](bitReader: BitReader, valueType: typedesc[T]): HuffmanTreeNode[T] =
  let valueBitLength = bitReader.readBits(valueLengthFieldBitLength, uint8).int
  proc readNode(): HuffmanTreeNode[T] =
    case bitReader.readBool():
      of false: huffmanBranch(readNode(), readNode())
      of true: huffmanLeaf(bitReader.readBits(valueBitLength, valueType))
  readNode()

proc serialise*[T](tree: HuffmanTreeNode[T], bitWriter: BitWriter) =
  let maxValue = tree.maxValue()
  let valueBitLength = maxValue.bitLength()
  proc writeNode(node: HuffmanTreeNode[T]) =
    case node.kind:
      of branch:
        bitWriter.writeBool(false)
        writeNode(node.left)
        writeNode(node.right)
      of leaf:
        bitWriter.writeBool(true)
        bitWriter.writeBits(valueBitLength, node.value)
  bitWriter.writeBits(valueLengthFieldBitLength, valueBitLength.uint8)
  writeNode(tree)

proc symbolQueue*[T](stats: CountTableRef[T]): HeapQueue[HuffmanTreeNode[T]] =
  result = newHeapQueue[HuffmanTreeNode[T]]()
  for item, count in stats.pairs: result.push(huffmanLeaf(item, count))

proc buildHuffmanTree*[T: SomeUnsignedInt](stats: CountTableRef[T]): HuffmanTreeNode[T] =
  var symbolQueue = symbolQueue(stats)
  while symbolQueue.len > 1: symbolQueue.push(huffmanBranch(symbolQueue.pop(), symbolQueue.pop()))
  result = symbolQueue[0]
