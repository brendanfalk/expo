import ExpoModulesTestCore

@testable import ExpoModulesCore

class PersistentLogSpec: ExpoSpec {
  let serialQueue = DispatchQueue(label: "dev.expo.modules.test.persistentlog")

  let log = PersistentLog(category: "dev.expo.modules.test.persistentlog")

  func clearEntriesSync() {
    serialQueue.sync {
      let sem = DispatchSemaphore(value: 0)
      log.clearEntries { _, _ in
        sem.signal()
      }
      sem.wait()
    }
  }

  func filterEntriesSync(filter: @escaping PersistentLogFilter) {
    serialQueue.sync {
      let sem = DispatchSemaphore(value: 0)
      log.filterEntries(filter: filter) { _, _ in
        sem.signal()
      }
      sem.wait()
    }
  }

  func appendEntrySync(entry: String) {
    serialQueue.sync {
      let sem = DispatchSemaphore(value: 0)
      log.appendEntry(entry: entry) { _, _ in
        sem.signal()
      }
      sem.wait()
    }
  }

  func readEntriesSync() -> Any? {
    var result: Any?
    serialQueue.sync {
      let sem = DispatchSemaphore(value: 0)
      log.readEntries { entries, error in
        if let error = error {
          result = error
        } else {
          result = entries as? [String] ?? []
        }
        sem.signal()
      }
      sem.wait()
    }
    return result
  }

  override func spec() {
    beforeEach {
      self.clearEntriesSync()
    }

    it("cleared file has 0 entries") {
      let result = self.readEntriesSync()
      let error = result as? Error
      let entries = result as? [String]
      expect(error).to(beNil())
      expect(entries).notTo(beNil())
      expect(entries?.count ?? 0).to(be(0))
    }

    it("append one entry works") {
      self.appendEntrySync(entry: "Test string 1")
      let result = self.readEntriesSync()
      let error = result as? Error
      let entries = result as? [String]
      expect(error).to(beNil())
      expect(entries).notTo(beNil())
      expect(entries?.count ?? 0).to(be(1))
      expect(entries?[0] ?? "").to(equal("Test string 1"))
    }

    it("append three entries works") {
      self.appendEntrySync(entry: "Test string 1")
      self.appendEntrySync(entry: "Test string 2")
      self.appendEntrySync(entry: "Test string 3")
      let result = self.readEntriesSync()
      let error = result as? Error
      let entries = result as? [String]
      expect(error).to(beNil())
      expect(entries).notTo(beNil())
      expect(entries?.count ?? 0).to(be(3))
      expect(entries?[0] ?? "").to(equal("Test string 1"))
      expect(entries?[1] ?? "").to(equal("Test string 2"))
    }

    it("filter entries works") {
      self.appendEntrySync(entry: "Test string 1")
      self.appendEntrySync(entry: "Test string 2")
      self.filterEntriesSync { entry in
        entry.contains("2")
      }
      let result = self.readEntriesSync()
      let error = result as? Error
      let entries = result as? [String]
      expect(error).to(beNil())
      expect(entries).notTo(beNil())
      expect(entries?.count ?? 0).to(be(1))
      expect(entries?[0] ?? "").to(equal("Test string 2"))
    }
  }
}
