import Foundation

struct SchemeEncoder {

	var extractReferences = true
	var dateFormat: DateEncodingFormat
	var keyEncodingStrategy: KeyEncodingStrategy

	@discardableResult
	func encode(
		_ value: Encodable,
		into schemas: inout [String: ReferenceOr<SchemaObject>]
	) throws -> ReferenceOr<SchemaObject> {
		let type = Swift.type(of: value)
		return try parse(
			value: TypeRevision().describeType(of: value),
			type: type,
			into: &schemas
		)
	}

	@discardableResult
	func decode(
		_ type: Decodable.Type,
		into schemas: inout [String: ReferenceOr<SchemaObject>]
	) throws -> ReferenceOr<SchemaObject> {
		try parse(
			value: TypeRevision().describe(type: type),
			type: type,
			into: &schemas
		)
	}

	func parse(
		value: @autoclosure () throws -> CodableContainerValue,
		type: Any.Type,
		into schemas: inout [String: ReferenceOr<SchemaObject>]
	) throws -> ReferenceOr<SchemaObject> {
		let name = String.typeName(type)
		var result: ReferenceOr<SchemaObject>

		switch type {
		case is Date.Type:
			result = .value(dateFormat.schema)

		case let openAPI as OpenAPIType.Type:
			result = .value(openAPI.openAPISchema)

		default:
			switch try value() {
			case let .single(codableValues):
				let (dataType, format) = try parse(value: codableValues)
				if let iterable = type as? any CaseIterable.Type {
					let allCases = iterable.allCases as any Collection
					result = .value(.enum(of: dataType, cases: allCases.map { "\($0)" }))
				} else {
					result = .value(.primitive(dataType, format: format))
				}

			case let .keyed(keyedInfo):
				switch keyedInfo.isFixed {
				case true:
					let schema = try SchemaObject.object(
						properties: keyedInfo.fields.mapKeys {
							keyEncodingStrategy.encode($0)
						}.mapValues {
							try parse(value: $0.container, type: $0.type, into: &schemas)
						},
						required: Set(keyedInfo.fields.filter { !$0.value.isOptional }.keys)
					)
					result = .value(schema)

				case false:
					let schema = try SchemaObject.dictionary(
						of: (keyedInfo.fields.first?.value).map {
							try parse(value: $0.container, type: $0.type, into: &schemas)
						} ?? .any
					)
					result = .value(schema)
				}

			case let .unkeyed(typeInfo):
				let schema = try SchemaObject.array(
					of: parse(value: typeInfo.container, type: typeInfo.type, into: &schemas)
				)
				result = .value(schema)

			case .recursive:
				result = .ref(components: \.schemas, name)
			}
		}

		if let descriptable = type as? OpenAPIDescriptable.Type {
			result = result.with(description: descriptable.openAPIDescription)
		}

		if extractReferences, result.isReferenceable {
			schemas[name] = result
			return .ref(components: \.schemas, name)
		} else {
			return result
		}
	}

	private func parse(
		value: CodableValues
	) throws -> (PrimitiveDataType, DataFormat?) {
		switch value {
		case .int8, .int16, .int32, .uint8, .uint16, .uint32:
			return (.integer, .int32)
		case .int, .int64, .uint, .uint64:
			return (.integer, .int64)
		case .double:
			return (.number, .double)
		case .float:
			return (.number, .float)
		case .bool:
			return (.boolean, nil)
		case .string, .null:
			return (.string, nil)
		}
	}
}
