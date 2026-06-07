import Foundation
import WidgetKit

struct WidgetDataBridge {
    static func requestWidgetTimelineReload() {
        WidgetCenter.shared.reloadTimelines(ofKind: "JudarWidget")
    }
}
