import WidgetKit
import SwiftUI

@main
struct WIMSCWidgetBundle: WidgetBundle {
    var body: some Widget {
        NearestSuperchargerWidget()
        ChargingSessionLiveActivity()
    }
}
