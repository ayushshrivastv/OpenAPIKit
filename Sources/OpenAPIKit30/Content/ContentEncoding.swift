//
//  ContentEncoding.swift
//
//
//  Created by Mathew Polzin on 12/29/19.
//

import OpenAPIKitCore

extension OpenAPI.Content {
    /// OpenAPI Spec "Encoding Object"
    ///
    /// See [OpenAPI Encoding Object](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.1.0.md#encoding-object).
    public struct Encoding: Equatable {
        public typealias Style = OpenAPI.Parameter.SchemaContext.Style

        /// If an encoding object only contains 1 content type, it will be populated here.
        /// Two or more content types will result in a null value here but the `contentTypes`
        /// (plural) property will contain all content types specified.
        ///
        /// The singular `contentType` property is only provided for backwards compatibility and
        /// using the plural `contentTypes` property should be preferred.
        @available(*, deprecated, message: "use contentTypes instead")
        public var contentType: OpenAPI.ContentType? {
            guard let contentType = contentTypes.first,
                contentTypes.count == 1
            else {
                return nil
            }
            return contentType
        }

        public let contentTypes: [OpenAPI.ContentType]
        public let headers: OpenAPI.Header.Map?
        public let style: Style
        public let explode: Bool
        public let allowReserved: Bool

        /// Dictionary to store vendor extensions (e.g., x-custom-encoding)
        public let vendorExtensions: [String: AnyCodable]?

        /// The singular `contentType` argument is only provided for backwards compatibility and
        /// using the plural `contentTypes` argument should be preferred.
        public init(
            contentType: OpenAPI.ContentType? = nil,
            contentTypes: [OpenAPI.ContentType] = [],
            headers: OpenAPI.Header.Map? = nil,
            style: Style = Self.defaultStyle,
            allowReserved: Bool = false,
            vendorExtensions: [String: AnyCodable]? = nil
        ) {
            self.contentTypes = contentTypes + [contentType].compactMap { $0 }
            self.headers = headers
            self.style = style
            self.explode = style.defaultExplode
            self.allowReserved = allowReserved
            self.vendorExtensions = vendorExtensions
        }

        /// The singular `contentType` argument is only provided for backwards compatibility and
        /// using the plural `contentTypes` argument should be preferred.
        public init(
            contentType: OpenAPI.ContentType? = nil,
            contentTypes: [OpenAPI.ContentType] = [],
            headers: OpenAPI.Header.Map? = nil,
            style: Style = Self.defaultStyle,
            explode: Bool,
            allowReserved: Bool = false,
            vendorExtensions: [String: AnyCodable]? = nil
        ) {
            self.contentTypes = contentTypes + [contentType].compactMap { $0 }
            self.headers = headers
            self.style = style
            self.explode = explode
            self.allowReserved = allowReserved
            self.vendorExtensions = vendorExtensions
        }

        public static let defaultStyle: Style = .default(for: .query)
    }
}

// MARK: - Codable
extension OpenAPI.Content.Encoding: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if contentTypes.count > 0 {
            let contentTypesString =
                contentTypes
                .map(\.rawValue)
                .joined(separator: ", ")
            try container.encode(contentTypesString, forKey: .contentType)
        }
        try container.encodeIfPresent(headers, forKey: .headers)

        if style != Self.defaultStyle {
            try container.encode(style, forKey: .style)
        }

        if explode != style.defaultExplode {
            try container.encode(explode, forKey: .explode)
        }

        if allowReserved != false {
            try container.encode(allowReserved, forKey: .allowReserved)
        }

        // Encode vendor extensions
        if let vendorExtensions = vendorExtensions {
            for (key, value) in vendorExtensions {
                try container.encode(value, forKey: CodingKeys(stringValue: key)!)
            }
        }
    }
}

extension OpenAPI.Content.Encoding: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let contentTypesString = try container.decodeIfPresent(String.self, forKey: .contentType)
        if let contentTypesString = contentTypesString {
            contentTypes =
                contentTypesString
                .split(separator: ",")
                .compactMap { string in
                    OpenAPI.ContentType.init(rawValue: string.trimmingCharacters(in: .whitespaces))
                }
        } else {
            contentTypes = []
        }

        headers = try container.decodeIfPresent(OpenAPI.Header.Map.self, forKey: .headers)

        let style: Style =
            try container.decodeIfPresent(Style.self, forKey: .style) ?? Self.defaultStyle
        self.style = style

        explode = try container.decodeIfPresent(Bool.self, forKey: .explode) ?? style.defaultExplode

        allowReserved = try container.decodeIfPresent(Bool.self, forKey: .allowReserved) ?? false

        // Capture vendor extensions
        var extensions: [String: AnyCodable] = [:]
        let allKeys = container.allKeys
        for key in allKeys where key.stringValue.hasPrefix("x-") {
            if let value = try? container.decode(AnyCodable.self, forKey: key) {
                extensions[key.stringValue] = value
            }
        }
        vendorExtensions = extensions.isEmpty ? nil : extensions
    }
}

extension OpenAPI.Content.Encoding {
    private enum CodingKeys: String, CodingKey {
        case contentType
        case headers
        case style
        case explode
        case allowReserved

        // Dynamic key for vendor extensions
        case custom = ""
        init?(stringValue: String) {
            if stringValue.hasPrefix("x-") {
                self = .custom
            } else {
                switch stringValue {
                case "contentType": self = .contentType
                case "headers": self = .headers
                case "style": self = .style
                case "explode": self = .explode
                case "allowReserved": self = .allowReserved
                default: return nil
                }
            }
        }

        var stringValue: String {
            switch self {
            case .contentType: return "contentType"
            case .headers: return "headers"
            case .style: return "style"
            case .explode: return "explode"
            case .allowReserved: return "allowReserved"
            case .custom: return ""
            }
        }
    }
}

extension OpenAPI.Content.Encoding: Validatable {}
