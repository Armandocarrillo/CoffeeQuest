/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import MapKit
import YelpAPI

public class ViewController: UIViewController {
  
  // MARK: - Properties
  //private var businesses: [YLPBusiness] = []
  public var businesses: [Business] = []
  private let client = YLPClient(apiKey: YelpAPIKey)
  private let locationManager = CLLocationManager()
  public let annotationFactory = AnnotationFactory()
  public var filter: Filter!
  
  
  // MARK: - Outlets
  @IBOutlet public var mapView: MKMapView! {
    didSet {
      mapView.showsUserLocation = true
    }
  }
  
  // MARK: - View Lifecycle
  public override func viewDidLoad() {
    super.viewDidLoad()

    locationManager.requestWhenInUseAuthorization()
  }
  
  // MARK: - Actions
  @IBAction func businessFilterToggleChanged(_ sender: UISwitch) {
    
    if sender.isOn {
      filter = Filter.starRating(atLeast: 4.75)
    } else {
      filter = Filter.starRating(atLeast: 0.0)
    }
    
    for business in businesses {
      filter.bussinesses.append(business)
    }
    addAnnotations()
    
  }
}

// MARK: - MKMapViewDelegate
extension ViewController: MKMapViewDelegate {
  
  public func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
    centerMap(on: userLocation.coordinate)
  }
  
  private func centerMap(on coordinate: CLLocationCoordinate2D) {
    let regionRadius: CLLocationDistance = 3000
    let coordinateRegion = MKCoordinateRegion(center: coordinate,
                                              latitudinalMeters: regionRadius,
                                              longitudinalMeters: regionRadius)
    mapView.setRegion(coordinateRegion, animated: true)
    searchForBusinesses()
  }
  
  private func searchForBusinesses() {
    let coordinate = mapView.userLocation.coordinate
    guard coordinate.latitude != 0,
      coordinate.longitude != 0 else {
        return
    }
    
    let yelpCoordinate = YLPCoordinate(latitude: coordinate.latitude,
                                       longitude: coordinate.longitude)
    
    client.search(with: yelpCoordinate,
                  term: "coffee",
                  limit: 35,
                  offset: 0,
                  sort: .bestMatched) { [weak self] (searchResult, error) in
                    guard let self = self else { return }
                    //to convert the search result into an array of Bussiness
                    guard let searchResult = searchResult?.adaptSeachResultsFromYLP(),
                      error == nil else {
                        print("Search failed: \(String(describing: error))")
                        return
                    }
                    self.businesses = searchResult.businesses
                    self.filter = Filter.identity()
                    for business in self.businesses{
                      self.filter.bussinesses.append(business)
                    }
                    DispatchQueue.main.async {
                      self.addAnnotations()
                    }
    }
  }
  
  private func addAnnotations() {
    //to remove all current annotations
    mapView.removeAnnotations(mapView.annotations)
    
    filter.bussinesses = filter.filterBussinesses()
    //to create an annotation 
    for business in filter.bussinesses {
      //guard let yelpCoordinate = business.location.coordinate else { continue }
      guard let viewModel = annotationFactory.createBussinessMapViewModel(for: business) else { continue }
      /*
      let coordinate = CLLocationCoordinate2D(latitude: yelpCoordinate.latitude,
                                              longitude: yelpCoordinate.longitude)
      let name = business.name
      let rating = business.rating
      let image: UIImage
      
      switch rating {
      case 0.0..<3.5:
        image = UIImage(named: "bad")!
      case 3.5..<4.0:
        image = UIImage(named: "meh")!
      case 4.0..<4.75:
        image = UIImage(named: "good")!
      case 4.75...5.0:
        image = UIImage(named: "great")!
      default:
        image = UIImage(named: "bad")!
        
      }
      let annotation = BussinessMapViewModel(
                              coordinate: coordinate,
                              name: name,
                              rating: rating,
                              image: image)
      mapView.addAnnotation(annotation)
    }*/
      mapView.addAnnotation(viewModel)
  }
  }
  
  //show image like pin icon
  public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard let viewModel = annotation as? BussinessMapViewModel else {
      return nil
    }
    
    let identifier = "business"
    let annotationView: MKAnnotationView
    
    if let existingView = mapView.dequeueReusableAnnotationView(
      withIdentifier: identifier){
      annotationView = existingView
    } else {
      annotationView = MKAnnotationView(annotation: viewModel, reuseIdentifier: identifier)
    }
    annotationView.image = viewModel.image
    annotationView.canShowCallout = true
    return annotationView
  }
}
