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

# https://github.com/nim-lang/Nim/pull/9805

proc prepend*[T](L: var SinglyLinkedList[T], n: SinglyLinkedNode[T]) =
  ## prepends a node to `L`. Efficiency: O(1).
  n.next = L.head
  L.head = n
  if L.tail == nil: L.tail = n

proc prepend*[T](L: var SinglyLinkedList[T], value: T) =
  ## prepends a node to `L`. Efficiency: O(1).
  listpolyfill.prepend(L, newSinglyLinkedNode(value))

proc append*[T](L: var SinglyLinkedList[T], n: SinglyLinkedNode[T]) =
  ## appends a node `n` to `L`. Efficiency: O(1).
  n.next = nil
  if L.tail != nil:
    assert(L.tail.next == nil)
    L.tail.next = n
  L.tail = n
  if L.head == nil: L.head = n

proc append*[T](L: var SinglyLinkedList[T], value: T) =
  ## appends a value to `L`. Efficiency: O(1).
  append(L, newSinglyLinkedNode(value))
