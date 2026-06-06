import SwiftUI

struct PartyView: View {
    let todayCounts: DailyCounts
    let attackingType: EventType?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(EventType.allCases, id: \.self) { eventType in
                PartyMemberCard(
                    member: eventType.partyMember,
                    count: todayCounts[eventType],
                    isAttacking: attackingType == eventType
                )
            }
        }
    }
}

private struct PartyMemberCard: View {
    let member: PartyMember
    let count: Int
    let isAttacking: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(member.name)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
            Text(member.role)
                .font(.system(size: 9, design: .monospaced))
                .opacity(0.6)
            Text("\(count)回")
                .font(.system(size: 10, design: .monospaced))
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .foregroundColor(isAttacking ? .black : .crtAmber)
        .background(isAttacking ? Color.crtAmber : Color.black)
        .overlay(Rectangle().stroke(Color.crtAmber.opacity(0.5), lineWidth: 1))
        .animation(.easeOut(duration: 0.15), value: isAttacking)
    }
}
