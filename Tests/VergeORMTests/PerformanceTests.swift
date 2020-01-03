//
//  PerformanceTests.swift
//  VergeORMTests
//
//  Created by muukii on 2019/12/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import XCTest

class PerformanceTests: XCTestCase {
  
  var state = RootState()
  
  func testUpdateFindAndStore() {
    
    state.db.performBatchUpdates { (context) in
      
      let authors = (0..<10000).map { i in
        Author(rawID: "author.\(i)")
      }
      context.author.insertsOrUpdates.insert(authors)
    }
    
    measure {
      state.db.performBatchUpdates { context in
        var author = context.author.current.find(by: .init("author.100"))!
        author.name = "mmm"
        context.author.insertsOrUpdates.insert(author)
      }
    }
    
  }
  
  func testUpdateInline() {
    
    state.db.performBatchUpdates { (context) in
      
      let authors = (0..<10000).map { i in
        Author(rawID: "author.\(i)")
      }
      context.author.insertsOrUpdates.insert(authors)
    }
    
    measure {
      state.db.performBatchUpdates { context -> Void in
        context.author.updateIfExists(id: .init("author.100")) { (author) in
          author.name = "mmm"
        }
      }
    }
    
  }
  
  func testInsertMany() {
    
    measure {
      state.db.performBatchUpdates { (context) in
        
        for i in 0..<1000 {
          let author = Author(rawID: "author.\(i)")
          context.author.insertsOrUpdates.insert(author)
        }
        
      }
    }
           
  }
  
  func testInsert3000() {
    
    measure {
      state.db.performBatchUpdates { (context) in
        
        for i in 0..<3000 {
          let author = Author(rawID: "author.\(i)")
          context.author.insertsOrUpdates.insert(author)
        }
        
      }
    }
    
  }
  
  func testInsert3000UseCollection() {
    
    measure {
      state.db.performBatchUpdates { (context) in
        
        let authors = (0..<1000).map { i in
          Author(rawID: "author.\(i)")
        }
        
        context.author.insertsOrUpdates.insert(authors)
        
      }
    }
    
  }
  
  func testInsert10000UseCollection() {
    
    measure {
      state.db.performBatchUpdates { (context) in
        
        let authors = (0..<10000).map { i in
          Author(rawID: "author.\(i)")
        }
        
        context.author.insertsOrUpdates.insert(authors)
        
      }
    }
    
  }
  
  func testInsert100000UseCollection() {
    
    measure {
      state.db.performBatchUpdates { (context) in
        
        let authors = (0..<100000).map { i in
          Author(rawID: "author.\(i)")
        }
        
        context.author.insertsOrUpdates.insert(authors)
        
      }
    }
    
  }
  
  func testInsertToFatStore() {
    
    state.db.performBatchUpdates { (context) in
      let authors = (0..<100000).map { i in
        Author(rawID: "author.\(i)")
      }
      
      context.author.insertsOrUpdates.insert(authors)
    }
    
    measure {
      state.db.performBatchUpdates { (context) in
        
        let authors = (0..<100000).map { i in
          Author(rawID: "author.\(i)")
        }
        
        context.author.insertsOrUpdates.insert(authors)
        
      }
    }
    
  }
  
  func testInsertSoManySeparatedTransaction() {
        
    measure {
      for l in 0..<10 {
        state.db.performBatchUpdates { (context) in
          
          for i in 0..<1000 {
            let author = Author(rawID: "author.\(l)-\(i)")
            context.author.insertsOrUpdates.insert(author)
          }
          
        }
      }
    }
    
  }
  
  func testInsertManyEachTransaction() {
    measure {
      
      for i in 0..<1000 {
        state.db.performBatchUpdates { (context) in
          let author = Author(rawID: "author.\(i)")
          context.author.insertsOrUpdates.insert(author)
        }
        
      }
    }
  }
  
}

class FindPerformanceTests: XCTestCase {
  
  var state = RootState()
  
  override func setUp() {
    state.db.performBatchUpdates { (context) -> Void in
      
      context.author.insertsOrUpdates.insert((0..<10000).map { i in
        Author(rawID: "author.\(i)")
      })
            
    }
  }
  
  func testFindOne() {

    measure {
      _ = state.db.entities.author.find(by: .init("author.199"))
    }
    
  }
  
  func testFindMultiple() {
    
    let ids = Set<Author.EntityID>([
      .init("author.11"),
      .init("author.199"),
      .init("author.399")
    ])
    
    measure {
      _ = state.db.entities.author.find(in: ids)
    }
    
  }
  
}

class ModifyPerformanceTests: XCTestCase {
  
  var state = RootState()
  
  override func setUp() {
    state.db.performBatchUpdates { (context) -> Void in
      
      context.author.insertsOrUpdates.insert((0..<10000).map { i in
        Author(rawID: "author.\(i)")
      })
      
    }
  }

}
