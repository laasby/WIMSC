import MapKit
import SCData

/// Lightweight annotation for placing a Supercharger on the map.
public final class SuperchargerAnnotation: NSObject, MKAnnotation {
    public let supercharger: Supercharger
    public var coordinate: CLLocationCoordinate2D
    public var title: String?
    public var subtitle: String?

    public init(supercharger: Supercharger) {
        self.supercharger = supercharger
        self.coordinate = CLLocationCoordinate2D(
            latitude: supercharger.latitude,
            longitude: supercharger.longitude
        )
        self.title = supercharger.name
        self.subtitle = "\(supercharger.stallCount) stalls · \(supercharger.maxKilowatts) kW"
    }
}
