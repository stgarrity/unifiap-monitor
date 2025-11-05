import Foundation

struct AccessPoint: Codable, Identifiable {
    let id: String
    let mac: String
    let name: String
    let model: String
    let state: Int
    let adopted: Bool
    
    var displayName: String {
        return name.isEmpty ? model : name
    }
    
    var isOnline: Bool {
        return state == 1
    }
    
    var normalizedMAC: String {
        return mac.replacingOccurrences(of: ":", with: "").lowercased()
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case mac
        case name
        case model
        case state
        case adopted
    }
    
    init(id: String, mac: String, name: String, model: String, state: Int, adopted: Bool) {
        self.id = id
        self.mac = mac
        self.name = name
        self.model = model
        self.state = state
        self.adopted = adopted
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        mac = try container.decode(String.self, forKey: .mac)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        model = try container.decode(String.self, forKey: .model)
        state = try container.decode(Int.self, forKey: .state)
        adopted = try container.decode(Bool.self, forKey: .adopted)
    }
}
