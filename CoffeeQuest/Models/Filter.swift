

import Foundation

public struct Filter {
  public let filter: (Business) -> Bool
  public var bussinesses: [Business]
  
  public static func identity() -> Filter{
    return Filter(filter: { _ in return true }, bussinesses: []
    )
  }
  
  public static func starRating(atLeast starRating: Double) -> Filter {
    return Filter(filter: { $0.rating >= starRating }, bussinesses: [])
  }
  
  public func filterBussinesses() -> [Business] {
    return bussinesses.filter(filter)
  }
}

extension Filter: Sequence {
  public func makeIterator() -> IndexingIterator<[Business]> {
    return filterBussinesses().makeIterator()
  }
}
