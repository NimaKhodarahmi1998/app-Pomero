import Foundation
import SwiftData

// `NudgeType` now lives in Shared/Models/NudgeType.swift (shared with the iOS app).
// The relationship-aware suggestion list stays here because it depends on RelationshipType.

extension NudgeType {
    static func nudges(for relationship: RelationshipType) -> [NudgeType] {
        switch relationship {
        case .partner, .spouse:
            return [.thinkingOfYou, .loveYou, .missYou, .cantWaitToSeeYou, .youMakeMeSmile, .dreamingOfYou, .sendingHug]
        case .crush:
            return [.thinkingOfYou, .youMakeMeSmile, .sendingGoodVibes, .missYou, .howAreYou, .dreamingOfYou]
        case .bestFriend:
            return [.thinkingOfYou, .missYou, .letsHangOut, .youreTheBest, .youGotThis, .sendingGoodVibes, .sendingHug]
        case .closeFriend:
            return [.thinkingOfYou, .checkIn, .missYou, .letsHangOut, .sendingGoodVibes, .youGotThis]
        case .friend:
            return [.thinkingOfYou, .checkIn, .howAreYou, .letsHangOut, .sendingGoodVibes]
        case .sibling:
            return [.thinkingOfYou, .missYou, .checkIn, .sendingHug, .proudOfYou, .alwaysHere, .youGotThis]
        case .parent:
            return [.thinkingOfYou, .missYou, .sendingLove, .sendingHug, .alwaysHere, .proudOfYou]
        case .child:
            return [.thinkingOfYou, .missYou, .proudOfYou, .sendingLove, .sendingHug, .alwaysHere, .youGotThis]
        case .family:
            return [.thinkingOfYou, .missYou, .sendingLove, .checkIn, .alwaysHere, .sendingHug]
        case .mentor:
            return [.thinkingOfYou, .checkIn, .proudOfYou, .believeInYou, .keepGrowing]
        case .mentee:
            return [.thinkingOfYou, .checkIn, .youGotThis, .believeInYou, .keepGrowing, .sendingGoodVibes]
        case .coworker, .colleague:
            return [.checkIn, .greatWork, .keepItUp, .nailedIt, .letsCatchUp, .youGotThis]
        case .teammate:
            return [.youGotThis, .greatWork, .nailedIt, .keepItUp, .checkIn, .thinkingOfYou]
        case .neighbor:
            return [.checkIn, .thinkingOfYou, .howAreYou, .letsCatchUp, .sendingGoodVibes]
        }
    }
}

@Model
final class NudgeEntry {
    var type: NudgeType
    var timestamp: Date
    var isSent: Bool
    var contactName: String
    /// CloudKit record name when this nudge came from / was pushed to a connection. Used to dedupe on sync.
    var cloudRecordName: String? = nil

    init(type: NudgeType, timestamp: Date = .now, isSent: Bool, contactName: String, cloudRecordName: String? = nil) {
        self.type = type
        self.timestamp = timestamp
        self.isSent = isSent
        self.contactName = contactName
        self.cloudRecordName = cloudRecordName
    }
}
