import Foundation
import Combine

// MARK: - Firebase Service (Optional - requires Firebase SDK setup)
// To enable Firebase:
// 1. Add Firebase SPM package to the project
// 2. Add GoogleService-Info.plist from Firebase console
// 3. Uncomment the Firebase imports and implementation below

/*
import FirebaseCore
import FirebaseFirestore

@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private var db: Firestore?
    private var listener: ListenerRegistration?
    
    @Published var profiles: [UserProfile] = []
    @Published var isInitialized = false
    
    private init() {}
    
    func initialize() {
        guard !isInitialized else { return }
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        db = Firestore.firestore()
        isInitialized = true
        subscribeToProfiles()
    }
    
    func subscribeToProfiles() {
        guard let db = db else { return }
        
        listener?.remove()
        
        listener = db.collection(FirebaseConfig.profilesCollection)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Firebase listener error: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.profiles = []
                    return
                }
                
                self.profiles = documents.compactMap { doc in
                    try? doc.data(as: UserProfile.self)
                }
            }
    }
    
    func saveProfile(_ profile: UserProfile) async throws {
        guard let db = db else {
            throw FirebaseError.notInitialized
        }
        
        try db.collection(FirebaseConfig.profilesCollection)
            .document(profile.id)
            .setData(from: profile)
    }
    
    func deleteProfile(id: String) async throws {
        guard let db = db else {
            throw FirebaseError.notInitialized
        }
        
        try await db.collection(FirebaseConfig.profilesCollection)
            .document(id)
            .delete()
    }
    
    func updateProfile(_ profile: UserProfile) async throws {
        try await saveProfile(profile)
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    deinit {
        listener?.remove()
    }
}
*/

// MARK: - Firebase Errors

enum FirebaseError: Error, LocalizedError {
    case notInitialized
    case saveFailed(Error)
    case deleteFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Firebase is not initialized"
        case .saveFailed(let error):
            return "Failed to save profile: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete profile: \(error.localizedDescription)"
        }
    }
}

// MARK: - Local Storage (Default Profile Storage)

@MainActor
class LocalProfileStorage: ObservableObject {
    static let shared = LocalProfileStorage()
    
    private let profilesKey = "stored_profiles"
    
    @Published var profiles: [UserProfile] = []
    
    private init() {
        loadProfiles()
    }
    
    func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let decoded = try? JSONDecoder().decode([UserProfile].self, from: data) {
            profiles = decoded
        }
    }
    
    func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: profilesKey)
        }
    }
    
    func addProfile(_ profile: UserProfile) {
        // Check if profile with same email exists
        if let index = profiles.firstIndex(where: { $0.email == profile.email }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        saveProfiles()
    }
    
    func deleteProfile(id: String) {
        profiles.removeAll { $0.id == id }
        saveProfiles()
    }
    
    func updateProfile(_ profile: UserProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            saveProfiles()
        }
    }
}
