import Foundation

/// Describes a single request body.
public struct RequestBodyObject: Codable, Equatable, SpecificationExtendable {
    
    /// A brief description of the request body. This could contain examples of use.  ```CommonMark syntax``` MAY be used for rich text representation.
    public var description: String?
    
    /// The content of the request body. The key is a media type or <a href="https://tools.ietf.org/html/rfc7231#appendix--d">media type range</a> and the value describes it.  For requests that match multiple keys, only the most specific key is applicable. e.g. text/plain overrides text/*
    public var content: ContentObject<MediaTypeObject>
    
    /// Determines if the request body is required in the request. Defaults to false.
    public var `required`: Bool?

    
    public init(
        description: String? = nil,
        content: ContentObject<MediaTypeObject>,
        `required`: Bool?
    ) {
        self.description = description
        self.content = content
        self.required = `required`
    }
}
