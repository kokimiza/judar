//
//  judarwidgetLiveActivity.swift
//  judarwidget
//
//  Created by 4hoe8pow on 2026/06/07.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct judarwidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct judarwidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: judarwidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension judarwidgetAttributes {
    fileprivate static var preview: judarwidgetAttributes {
        judarwidgetAttributes(name: "World")
    }
}

extension judarwidgetAttributes.ContentState {
    fileprivate static var smiley: judarwidgetAttributes.ContentState {
        judarwidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: judarwidgetAttributes.ContentState {
         judarwidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: judarwidgetAttributes.preview) {
   judarwidgetLiveActivity()
} contentStates: {
    judarwidgetAttributes.ContentState.smiley
    judarwidgetAttributes.ContentState.starEyes
}
