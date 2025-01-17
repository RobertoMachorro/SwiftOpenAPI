import Foundation

extension Collection {

	var nilIfEmpty: Self? {
		isEmpty ? nil : self
	}
}

extension Dictionary {

	func mapKeys<T>(_ map: (Key) -> T) -> [T: Value] {
		[T: Value](self.map { (map($0.key), $0.value) }) { _, new in
			new
		}
	}

	func mapKeys<T, V>(_ map: (Key) -> T, values: (Value) -> V) -> [T: V] {
		[T: V](self.map { (map($0.key), values($0.value)) }) { _, new in
			new
		}
	}
}
