//
//  ViewController.swift
//  Lab03
//
//  Created by Jaiwin Thumber on 2022-04-01.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {

    
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var weatherType: UILabel!
    
    var locationManager:CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.delegate = self
        
        let config = UIImage.SymbolConfiguration(paletteColors: [.systemBlue, .systemYellow, .systemTeal])
        weatherImage.preferredSymbolConfiguration = config
        weatherImage.image = UIImage(systemName: "cloud.moon")
        
        

    }
    
    //MARK: - location delegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation :CLLocation = locations[0] as CLLocation
//        self.getWeather(search: self.locationLabel.text)
//        self.locationManager.stopUpdatingLocation()
        
        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")

        //self.labelLat.text = "\(userLocation.coordinate.latitude)"
        //self.labelLongi.text = "\(userLocation.coordinate.longitude)"

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(userLocation) { (placemarks, error) in
            if (error != nil){
                print("error in reverseGeocode")
            }
            let placemark = placemarks! as [CLPlacemark]
            if placemark.count>0{
                let placemark = placemarks![0]
                print(placemark.locality!)
                print(placemark.administrativeArea!)
                print(placemark.country!)

                self.locationLabel.text = "\(placemark.locality!)"
                self.getWeather(search: "\(placemark.locality!)")
                
            }
            
        }
        
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error \(error)")
    }
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        print(textField.text ?? "")
        getWeather(search: textField.text)
        return true
    }
    
    
    @IBAction func onGetLocation(_ sender: UIButton) {
        //        location manager code starts.
                locationManager = CLLocationManager()
                    locationManager.delegate = self
                    locationManager.desiredAccuracy = kCLLocationAccuracyBest
                    locationManager.requestAlwaysAuthorization()

                    if CLLocationManager.locationServicesEnabled(){
                        locationManager.startUpdatingLocation()
                        
                    }
        
    }
    
    
    
    @IBAction func onSearchTapped(_ sender: UIButton) {
        searchTextField.endEditing(true)
        getWeather(search: searchTextField.text)
    }
    
    private func getWeather(search: String?) {
        guard let search = search else {
            return
        }

        //Step 1: get URL
        //let url = getUrl(search: search)
        let url = getUrl(search: search.trimmingCharacters(in: .whitespacesAndNewlines))
        
        guard let url = url else {
            print("Could not get URL")
            return
        }
        
        //step 2: create URLSession
        let session = URLSession.shared
        
        //step 3: Create task for session
        let dataTask = session.dataTask(with: url) { [self] data, response, error in
            print("network call complete")
            
            guard error == nil else {
                print("received error")
                return
            }
            
            guard let data = data else {
                print("No data found")
                return
            }
            
            
            
            if let weather = self.parseJson(data: data) {
                print(weather.location.name)
                print(weather.current.temp_c)
                print(weather.current.condition.text)
                
                DispatchQueue.main.sync {
                    self.locationLabel.text = weather.location.name
                    self.temperatureLabel.text = "\(weather.current.temp_c)\u{00B0} C"
                    self.weatherType.text = weather.current.condition.text
//                    let imageName = self.imageLoad(text: self.weatherType.text!)
                    let imageName = self.imageLoad(text: weather.current.condition.code)
                    self.weatherImage.image = UIImage(systemName: imageName)
                }
                
               
            }
            
        }
        
        //Step 4: Start the task
        dataTask.resume()
    }
    
    func imageLoad (text:Int) -> String {
        if(text == 1003) {
            return "cloud.sun"
        }
        else if (text == 1006) {
            return "cloud.fill"
        }
        else if (text == 1000) {
            return "sun.min"
        }
        else if (text == 1030) {
            return "cloud.fill.fog"
        }
        else if (text == 1135) {
            return "smoke"
        }
        else if (text == 1147) {
            return "wind.snow"
        }
        else if (text == 1153) {
            return "cloud.hail"
        }
        else if (text == 1183) {
            return "cloud.rain"
        }
        else {
            return "sun.haze"
        }
//
//        let dic:[String:String] = ["Sunny":"sun.max.fill","Cloudy":"cloud.fill","Clear":"cloud","Fog":"cloud.fog","Light drizzle":"aqi.low","Partly cloudy":"cloud.sun"]
//        return dic[text] ?? "wind"
    }
    
    
    private func parseJson(data: Data) -> WeatherResponce? {
        let decoder = JSONDecoder()
        var weatherResponse: WeatherResponce?
        
        do {
            weatherResponse = try decoder.decode(WeatherResponce.self, from: data)
        } catch {
            print("Error parsing weather")
            print(error)
        }
        
        return weatherResponse
    }
    
    
    private func getUrl(search: String) -> URL? {
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndPoint = "current.json"
        let apiKey = "/#"
        
        
        let url = "\(baseUrl)\(currentEndPoint)?key=\(apiKey)&q=\(search)"
        return URL(string: url)
    }
}

struct WeatherResponce: Decodable {
    let location: Location
    let current: Weather
}

struct Location: Decodable {
    let name:String
}


struct Weather: Decodable {
    let temp_c: Float
    let condition: WeatherCondition
    
}

struct WeatherCondition: Decodable {
    let text: String
    let code: Int
}
