import Foundation
import CloudKit

struct TuskeAICloudProfile: Codable, Identifiable {
    let id: String
    let name: String
    let provider: String
    let endpoint: String
    let modelName: String
    let personality: String

    init(id: String, name: String, provider: String, endpoint: String, modelName: String, personality: String = "") {
        self.id = id
        self.name = name
        self.provider = provider
        self.endpoint = endpoint
        self.modelName = modelName
        self.personality = personality
    }
}

final class CloudSyncManager {
    static let shared = CloudSyncManager()

    private let container = CKContainer(identifier: "iCloud.com.szarazlorant.TuskeAI")
    private let database: CKDatabase

    private init() {
        self.database = container.privateCloudDatabase
    }

    func fetchProfiles(completion: @escaping ([TuskeAICloudProfile]) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "ModelProfile", predicate: predicate)

        database.perform(query, inZoneWith: nil) { records, _ in
            let profiles = (records ?? []).compactMap { record -> TuskeAICloudProfile? in
                guard let id = record.recordID.recordName as String?,
                      let name = record["name"] as? String,
                      let provider = record["provider"] as? String,
                      let endpoint = record["endpoint"] as? String,
                      let modelName = record["modelName"] as? String else {
                    return nil
                }

                                let personality = record["personality"] as? String ?? ""
                                return TuskeAICloudProfile(id: id, name: name, provider: provider, endpoint: endpoint, modelName: modelName, personality: personality)
            }

            DispatchQueue.main.async {
                completion(profiles)
            }
        }
    }

    func saveProfile(_ profile: TuskeAICloudProfile, completion: @escaping (Bool) -> Void) {
        let recordID = CKRecord.ID(recordName: profile.id)
        let record = CKRecord(recordType: "ModelProfile", recordID: recordID)
        record["name"] = profile.name
        record["provider"] = profile.provider
        record["endpoint"] = profile.endpoint
        record["modelName"] = profile.modelName
        record["personality"] = profile.personality

        database.save(record) { _, error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }
}
