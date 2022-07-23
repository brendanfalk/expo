// Copyright 2022-present 650 Industries. All rights reserved.

import Foundation
import OSLog

import ExpoModulesCore

/**
 Class to read expo-updates logs using OSLogReader
 */
@objc(EXUpdatesLogReader)
public class UpdatesLogReader: NSObject {
  private let serialQueue = DispatchQueue(label: "dev.expo.updates.logging.reader")
  private let logPersistence = PersistentLog(category: UpdatesLogger.EXPO_UPDATES_LOG_CATEGORY)

  /**
   Get expo-updates logs newer than the given date
   Returns the log entries unpacked as dictionaries
   Maximum of one day lookback is allowed
   */
  @objc(getLogEntriesNewerThan:error:)
  public func getLogEntries(newerThan: Date) throws -> [[String: Any]] {
    return try getLogEntries(newerThan: newerThan)
      .compactMap { logEntryString in
        UpdatesLogEntry.create(from: logEntryString)?.asDict()
      }
  }

  /**
   Purge all log entries written prior to the given date
   */
  @objc(purgeLogEntriesOlderThan:error:)
  public func purgeLogEntries(olderThan: Date) throws {
    let epoch = UInt(olderThan.timeIntervalSince1970)
    serialQueue.sync {
      let sem = DispatchSemaphore(value: 0)
      logPersistence.filterEntries(filter: { entryString in
        let suffixFrom = entryString.index(entryString.startIndex, offsetBy: 2)
        let entryStringSuffix = String(entryString.suffix(from: suffixFrom))
        return UpdatesLogEntry.create(from: entryStringSuffix)?.timestamp ?? 0 >= epoch
      }, {_, error in
        if let error = error {
          print("UpdatesLogReader: error in purgeLogEntries, \(error.localizedDescription)")
        }
        sem.signal()
      })
      sem.wait()
    }
  }

  /**
   Get expo-updates logs newer than the given date
   Returned strings are all in the JSON format of UpdatesLogEntry
   Maximum of one day lookback is allowed
   */
  @objc(getLogEntryStringsNewerThan:error:)
  public func getLogEntries(newerThan: Date) throws -> [String] {
    var result: [String] = []
    serialQueue.sync {
      let sem = DispatchSemaphore(value: 0)
      getLogEntriesAsync(newerThan: newerThan) { entries, error in
        if let error = error {
          print("UpdatesLogReader: error in getLogEntries: \(error.localizedDescription)")
        } else {
          result = entries ?? []
        }
        sem.signal()
      }
      sem.wait()
    }
    return result
  }

  /**
   Get expo-updates logs newer than the given date
   Returned strings are all in the JSON format of UpdatesLogEntry
   Maximum of one day lookback is allowed
   Results are returned in the completion handler
   */
  @objc(getLogEntryStringsAsyncNewerThan:completion:)
  public func getLogEntriesAsync(newerThan: Date, completion: @escaping (_: [String]?, _: Error?) -> Void) {
    let earliestDate = Date().addingTimeInterval(-86_400)
    let dateToUse = newerThan.timeIntervalSince1970 < earliestDate.timeIntervalSince1970 ?
      earliestDate :
      newerThan
    let epoch = UInt(dateToUse.timeIntervalSince1970)

    logPersistence.readEntries { entries, error in
      if let error = error {
        completion(nil, error)
      } else {
        let result: [String] = entries as? [String] ?? []
        completion(
          result
            .map { entryString in
              let suffixFrom = entryString.index(entryString.startIndex, offsetBy: 2)
              return String(entryString.suffix(from: suffixFrom))
            }
            .compactMap { entryString in
              UpdatesLogEntry.create(from: entryString)
            }
            .filter { entry in
              entry.timestamp >= epoch
            }
            .compactMap { entry in
              entry.asString()
            },
          nil
        )
      }
    }
  }
}
