//
// Copyright (c) 2019 muukii
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

public struct GroupByIndex<
  Schema: EntitySchemaType,
  GroupEntity: EntityType,
  GroupedEntity: EntityType
>: IndexType {
  
  private var backing: [GroupEntity.ID : OrderedIDIndex<Schema, GroupedEntity>] = [:]
  
  public init() {
    
  }
  
  // MARK: - Querying
  
  public func groups() -> Dictionary<GroupEntity.ID, OrderedIDIndex<Schema, GroupedEntity>>.Keys {
    backing.keys
  }
  
  public func orderedID(in groupEntityID: GroupEntity.ID) -> OrderedIDIndex<Schema, GroupedEntity> {
    backing[groupEntityID, default: .init()]
  }
  
  // MARK: - Mutating
    
  public mutating func _apply(removing: BackingRemovingEntityStorage<Schema>) {
    
    let group = removing._getTable(GroupEntity.self)
    group?.forEach {
      backing.removeValue(forKey: $0)
    }
        
    backing.keys.forEach { key in
      backing[key]?._apply(removing: removing)
      
      cleanup: do {
        
        if backing[key]?.isEmpty == true {
          backing.removeValue(forKey: key)
        }
        
      }
    }
    
   
    
  }
  
  public mutating func update(in groupEntityID: GroupEntity.ID, update: (inout OrderedIDIndex<Schema, GroupedEntity>) -> Void) {
    update(&backing[groupEntityID, default: .init()])
  }
      
  public mutating func removeGroup(_ groupEntityID: GroupEntity.ID) {
    backing.removeValue(forKey: groupEntityID)
  }
      
}