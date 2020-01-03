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

#if !COCOAPODS
import VergeCore
#endif

extension EntityType {
  
  #if COCOAPODS
  public typealias AnyGetter = Verge.AnyGetter<Self>
  public typealias Getter<Source> = Verge.Getter<Source, Self>
  #else
  public typealias AnyGetter = VergeCore.AnyGetter<Self>
  public typealias Getter<Source> = VergeCore.Getter<Source, Self>
  #endif
  
}

public protocol DatabaseEmbedding {
  
  associatedtype Database: DatabaseType
  
  static var getterToDatabase: (Self) -> Database { get }
  
}

fileprivate final class _RefBox<Value> {
  var value: Value
  init(_ value: Value) {
    self.value = value
  }
}

fileprivate final class _GetterCache {
  
  private let cache = NSCache<NSString, AnyObject>()
  
  @inline(__always)
  private func key<E: EntityType>(entityID: E.EntityID) -> NSString {
    "\(entityID)" as NSString
  }
  
  func getter<E: EntityType>(entityID: E.EntityID) -> AnyObject? {
    cache.object(forKey: key(entityID: entityID))
  }
  
  func setGetter<E: EntityType>(_ getter: AnyObject, entityID: E.EntityID) {
    cache.setObject(getter, forKey: key(entityID: entityID))
  }
  
}

extension AnyGetterType where Output : EntityType {
  
  public var entityID: Output.EntityID {
    value.entityID
  }
  
}

// MARK: - Core Functions

fileprivate var _valueContainerAssociated: Void?

extension ValueContainerType where Value : DatabaseEmbedding {
  
  private var cache: _GetterCache {
   
    if let associated = objc_getAssociatedObject(self, &_valueContainerAssociated) as? _GetterCache {
      
      return associated
      
    } else {
      
      let associated = _GetterCache()
      objc_setAssociatedObject(self, &_valueContainerAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      return associated
    }
  }
    
  /// Make getter to select value with update closure
  ///
  /// - Parameters:
  ///   - update: Updating output value each Input value updated.
  ///   - additionalEqualityComputer: Check to necessory of needs to update to reduce number of updating.
  public func entityGetter<Output>(
    update: @escaping (Value.Database) -> Output,
    additionalEqualityComputer: EqualityComputer<Value.Database>?
  ) -> Getter<Value, Output> {
    
    let path = Value.getterToDatabase
    
    let updatedAtEquality = EqualityComputer<Value.Database>.init(
      selector: { input -> (Date, Date) in
        let v = input
        return (v._backingStorage.entityUpdatedAt, v._backingStorage.indexUpdatedAt)
    },
      equals: { (old, new) -> Bool in
        old == new
    })
    
    let _getter = getter(
      filter: EqualityComputer.init(selector: { path($0) }, equals: { (old, new) -> Bool in
        guard !updatedAtEquality.isEqual(value: new) else {
          return true
        }
        return additionalEqualityComputer?.isEqual(value: new) ?? false
      }),
      map: { (value) -> Output in
        update(Value.getterToDatabase(value))
    })
    
    return _getter
  }
    
  /// A entity getter that entity id based.
  /// - Parameters:
  ///   - tableSelector:
  ///   - entityID:
  public func entityGetter<E: EntityType>(entityID: E.EntityID) -> Getter<Value, E?> {
    
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entityID) as? Getter<Value, E?> else {
      let newGetter = entityGetter(
        update: { db in
          db.entities.table(E.self).find(by: entityID)
      },
        additionalEqualityComputer: nil
      )
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getter
    
  }
  
  public func entityGetter<E: EntityType & Equatable>(
    entityID: E.EntityID
  ) -> Getter<Value, E?> {
    
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entityID) as? Getter<Value, E?> else {
      let newGetter = entityGetter(
        update: { db in
          db.entities.table(E.self).find(by: entityID)
      },
        additionalEqualityComputer: .init(
          selector: { db in db.entities.table(E.self).find(by: entityID) },
          equals: { $0 == $1 }
        )
      )
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getter
      
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType>(entity: E) -> Getter<Value, E> {
    
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entity.entityID) as? Getter<Value, E> else {
      let box = _RefBox(entity)
      let entityID = entity.entityID
      
      let newGetter = entityGetter(
        update: { db -> E in
          let table = db.entities.table(E.self)
          if let e = table.find(by: entityID) {
            box.value = e
          }
          return box.value
      },
        additionalEqualityComputer: nil
      )
      return newGetter
    }
    
    return getter
            
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    entity: E
  ) -> Getter<Value, E> {
       
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entity.entityID) as? Getter<Value, E> else {
      let box = _RefBox(entity)
      let entityID = entity.entityID
            
      let newGetter = entityGetter(
        update: { db -> E in
          let table = db.entities.table(E.self)
          if let e = table.find(by: entityID) {
            box.value = e
          }
          return box.value
      },
        additionalEqualityComputer: .init(
          selector: { db in db.entities.table(E.self).find(by: entityID) },
          equals: { $0 == $1 }
        )
      )
      return newGetter
    }
    
    return getter
    
  }
   
}

// MARK: - Wrapper Functions

extension ValueContainerType where Value : DatabaseEmbedding {
    
  /// A selector that if get nil then return latest non-null value
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType>(
    from insertionResult: EntityTable<Value.Database.Schema, E>.InsertionResult
  ) -> Getter<Value, E> {
    
    return nonNullEntityGetter(entity: insertionResult.entity)
    
  }
    
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from insertionResult: EntityTable<Value.Database.Schema, E>.InsertionResult
  ) -> Getter<Value, E> {
    
    return nonNullEntityGetter(entity: insertionResult.entity)
  }
  
  public func nonNullEntityGetters<E: EntityType, S: Sequence>(
    from insertionResults: S
  ) -> [Getter<Value, E>] where S.Element == EntityTable<Value.Database.Schema, E>.InsertionResult {
    insertionResults.map {
      nonNullEntityGetter(from: $0)
    }
  }
  
  public func nonNullEntityGetters<E: EntityType & Equatable, S: Sequence>(
    from insertionResults: S
  ) -> [Getter<Value, E>] where S.Element == EntityTable<Value.Database.Schema, E>.InsertionResult {
    insertionResults.map {
      nonNullEntityGetter(from: $0)
    }
  }
}