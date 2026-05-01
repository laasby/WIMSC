import Foundation
import CoreLocation
import MapKit
import SCData

@Observable
@MainActor
public final class DetailViewModel {
    public let supercharger: Supercharger
    public private(set) var eta: String?
    public private(set) var weather: WeatherInfo?
    public private(set) var isColdSoak: Bool = false
    public private(set) var distanceMetres: Double?

    private let locationService: LocationService

    public init(supercharger: Supercharger, locationService: LocationService) {
        self.supercharger = supercharger
        self.locationService = locationService
    }

    public func load() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.calculateDistance() }
            group.addTask { await self.fetchWeather() }
        }
    }

    private func calculateDistance() async {
        guard let userLoc = locationService.currentLocation else { return }
        let site = CLLocation(latitude: supercharger.latitude, longitude: supercharger.longitude)
        let metres = userLoc.distance(from: site)
        distanceMetres = metres

        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = MKMapItem(placemark: MKPlacemark(
            coordinate: CLLocationCoordinate2D(
                latitude: supercharger.latitude,
                longitude: supercharger.longitude
            )
        ))
        request.transportType = .automobile
        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculateETA()
            let minutes = Int(response.expectedTravelTime / 60)
            eta = "~\(minutes) min drive"
        } catch {
            let km = metres / 1000
            let minutes = Int(km / 80 * 60)
            eta = "~\(minutes) min drive"
        }
    }

    private func fetchWeather() async {
        let lat = supercharger.latitude
        let lon = supercharger.longitude
        guard let url = URL(string: "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=\(lat)&lon=\(lon)") else { return }
        var request = URLRequest(url: url)
        request.setValue("WIMSC/1.0 github.com/laasby/WIMSC", forHTTPHeaderField: "User-Agent")
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let forecast = try decoder.decode(MetForecastResponse.self, from: data)
            if let first = forecast.properties.timeseries.first {
                let temp = first.data.instant.details.airTemperature
                let symbol = first.data.next1Hours?.summary.symbolCode ?? "cloudy"
                let wind = first.data.instant.details.windSpeed
                weather = WeatherInfo(
                    temperatureCelsius: temp,
                    symbolCode: symbol,
                    windSpeedMs: wind,
                    timeseries: forecast.properties.timeseries.prefix(7).map {
                        WeatherHour(
                            time: $0.time,
                            tempCelsius: $0.data.instant.details.airTemperature,
                            symbolCode: $0.data.next1Hours?.summary.symbolCode ?? "cloudy"
                        )
                    }
                )
                isColdSoak = temp < 0
            }
        } catch {
            // Weather is non-critical — degrade gracefully
        }
    }
}

// MARK: - Weather models

public struct WeatherInfo {
    public var temperatureCelsius: Double
    public var symbolCode: String
    public var windSpeedMs: Double
    public var timeseries: [WeatherHour]
}

public struct WeatherHour {
    public var time: Date
    public var tempCelsius: Double
    public var symbolCode: String
}

// MARK: - MET Norway JSON models

struct MetForecastResponse: Decodable {
    struct Properties: Decodable {
        var timeseries: [Timeseries]
    }
    struct Timeseries: Decodable {
        var time: Date
        var data: TimeseriesData
    }
    struct TimeseriesData: Decodable {
        var instant: Instant
        var next1Hours: Next1Hours?
        private enum CodingKeys: String, CodingKey {
            case instant, next1Hours = "next_1_hours"
        }
    }
    struct Instant: Decodable {
        var details: Details
    }
    struct Details: Decodable {
        var airTemperature: Double
        var windSpeed: Double
        private enum CodingKeys: String, CodingKey {
            case airTemperature = "air_temperature"
            case windSpeed = "wind_speed"
        }
    }
    struct Next1Hours: Decodable {
        var summary: Summary
    }
    struct Summary: Decodable {
        var symbolCode: String
        private enum CodingKeys: String, CodingKey { case symbolCode = "symbol_code" }
    }
    var properties: Properties
}
