import Foundation

enum EnemyRoster {
    static let all: [EnemyTemplate] = [
        EnemyTemplate(
            name: "眠気の悪魔",
            maxHP: 30,
            resistances: [.physical],
            weaknesses: [.magical],
            attackPower: 6,
            asciiArt: "  (-_-)Zzz\n  |   |\n ~~~~~"
        ),
        EnemyTemplate(
            name: "夜泣き鬼",
            maxHP: 45,
            resistances: [.magical],
            weaknesses: [.physical],
            attackPower: 9,
            asciiArt: "  (>o<) !!\n  /||\\  \n  d  b  "
        ),
        EnemyTemplate(
            name: "げっぷ竜",
            maxHP: 25,
            resistances: [],
            weaknesses: [],
            attackPower: 5,
            asciiArt: "  ~(=_=)~\n   ~~~ \n *BURP* "
        ),
        EnemyTemplate(
            name: "おむつ妖怪",
            maxHP: 35,
            resistances: [.heal],
            weaknesses: [.physical],
            attackPower: 7,
            asciiArt: "  [=_=]\n  ||||\n ~~~~~~"
        ),
        EnemyTemplate(
            name: "便秘の呪い",
            maxHP: 20,
            resistances: [],
            weaknesses: [.physical],
            attackPower: 4,
            asciiArt: "  (;_;)\n  ~~~\n  ___"
        ),
        EnemyTemplate(
            name: "コリック悪霊",
            maxHP: 60,
            resistances: [.physical, .magical, .heal],
            weaknesses: [],
            attackPower: 12,
            asciiArt: "  (o_O)!!!\n  /|\\\n >><<<"
        ),
        EnemyTemplate(
            name: "ミルク拒否の精",
            maxHP: 30,
            resistances: [.magical, .heal],
            weaknesses: [.physical],
            attackPower: 6,
            asciiArt: "  (>_<) x\n  ~~~\n  o o o "
        ),
        EnemyTemplate(
            name: "発熱怪獣",
            maxHP: 50,
            resistances: [.physical, .magical],
            weaknesses: [.heal],
            attackPower: 10,
            asciiArt: "  (*_*)\n ##|## \n  ~~~  "
        ),
    ]

    // Tutorial-friendly first enemy: no resistances, low HP
    static func firstEnemy() -> Enemy {
        Enemy(template: all[2])  // げっぷ竜
    }

    static func randomTemplate(excluding name: String? = nil, randomSource: RandomSource) -> EnemyTemplate {
        let pool: [EnemyTemplate]
        if let name {
            let candidates = all.filter { $0.name != name }
            pool = candidates.isEmpty ? all : candidates
        } else {
            pool = all
        }
        return pool[randomSource.nextInt(pool.count)]
    }
}
