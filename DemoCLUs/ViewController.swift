//
//  ViewController.swift
//  DemoCLUs
//
//  Created by Tommy Rogers on 2/16/16.
//  Copyright © 2016 Tommy Rogers. All rights reserved.
//

import UIKit
import MapKit
import LoginWithClimate
import GeoFeatures
import CoreLocation


class CustomMKPolygon : MKPolygon {
    
    var color: UIColor?
}


class ViewController: UIViewController, LoginWithClimateDelegate, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {

    
    @IBOutlet weak var redScore: UILabel!
    @IBOutlet weak var blueScore: UILabel!
    @IBOutlet weak var mapView: MKMapView!

 
    
    var locationManager = CLLocationManager!()

    var loginViewController: LoginWithClimateButton!
    var currentSession: Session!
    var status=false
    var counter=0;
    var player1_score = 0.0;
    var player2_score = 0.0;
    var user1_Name="Red: ";
    var user2_Name="Blue: ";
    
    
    
    // MARK: - ViewController functions
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()


        // Set up button
        
        loginViewController = LoginWithClimateButton(clientId: "dpevoue055oob8", clientSecret: "atbrbg3baccv3epfbct02m9qn6")
        loginViewController.delegate = self
        
        view.addSubview(loginViewController.view)
        loginViewController.view.translatesAutoresizingMaskIntoConstraints = false

        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[button]-|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: ["button":loginViewController.view]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[button(==44)]-30-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["button":loginViewController.view]))
        
        self.addChildViewController(loginViewController)

        //set up gesture
        mapView.userInteractionEnabled = true
        
        let characterOneTapGesture = UITapGestureRecognizer(target: self, action:Selector("handleTap:"))
        characterOneTapGesture.delegate = self
        mapView.addGestureRecognizer(characterOneTapGesture)

        // Set up map

        mapView.delegate = self
        
        mapView.scrollEnabled = true
        mapView.rotateEnabled = true
        mapView.zoomEnabled = false
        
        if (CLLocationManager.locationServicesEnabled())
        {
            print("enabled")
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        let location = CLLocation(latitude: 40.4574999, longitude: -86.9937988)
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 5000, 5000)
        mapView.setRegion(region, animated: false)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        print("here")
        
        let location = locations.last! as CLLocation
        
        print(location.coordinate.latitude)
        print(location.coordinate.longitude)
    }
    // MARK: - Utility functions
    
    func getSpecificCLUs(locationCoordinate: CLLocationCoordinate2D,completion: ([String: AnyObject] -> Void))
    {
        let components: NSURLComponents = NSURLComponents(string: "https://hackillinois.climate.com/api/clus")!
        components.queryItems = [NSURLQueryItem(name: "ne_lat", value: locationCoordinate.latitude.description),
            NSURLQueryItem(name: "ne_lon", value: locationCoordinate.longitude.description),
            NSURLQueryItem(name: "sw_lat", value: locationCoordinate.latitude.description),
            NSURLQueryItem(name: "sw_lon", value: locationCoordinate.longitude.description)]
        
        let request = NSMutableURLRequest(URL: components.URL!)
        request.setValue("Bearer \(self.currentSession.accessToken)", forHTTPHeaderField: "Authorization")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) in
            
            guard error == nil && (response as? NSHTTPURLResponse)?.statusCode == 200 else {
                print(error)
                //print(response)
                //print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                return
            }
            
            let jsonObject = try! NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [String: AnyObject]
            completion(jsonObject)
           // print(jsonObject)
        }
        
        task.resume()

        
    }
    func handleTap(sender: UITapGestureRecognizer) {
        if sender.state == .Ended {
            // handling code
            let point = sender.locationInView(self.view)
            let locationCoordinate = mapView.convertPoint(point, toCoordinateFromView: mapView)
            //print("Tapped at lat: \(locationCoordinate.latitude) long: \(locationCoordinate.longitude)")
            self.counter++;
            self.getSpecificCLUs(locationCoordinate) {
                (response: [String: AnyObject]) in
                let clus = response["features"] as! [[String: AnyObject]]
                print (clus)
                if (clus.count>0)
                {
                if let score = clus[0]["properties"]?["calc-acres"]
                {
                    print (score)
                    let math_score = score as! Double
                  
                    if (self.counter % 2 == 0)
                        {
                            self.player1_score+=math_score
                    }
                    else
                    {
                        self.player2_score+=math_score
                    }
                }
                }
                print (self.player1_score)
                print (self.player2_score)
                
                
                let overlays: [[MKOverlay]] = clus.map() {
                    (clu: [String: AnyObject]) -> [MKOverlay] in
                    let geometry = GFGeometry(geoJSONGeometry: clu["geometry"] as! [String: AnyObject])
                    return geometry.mkMapOverlays() as! [MKOverlay]
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.redScore.text=self.user1_Name+(self.player1_score.description);
                    self.blueScore.text=self.user2_Name+(self.player2_score.description);
                    overlays.forEach() {
                        (os: [MKOverlay]) -> () in
                        self.mapView.addOverlays(os)
                    }
                }
            }


        }
    }

    

    
    func randomColor() -> UIColor {
        return UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
    }
    
    func clearMap() {
        dispatch_async(dispatch_get_main_queue()) {
            self.mapView.removeOverlays(self.mapView.overlays)
        }
    }

    func cornerCoordinatesForMapView(map: MKMapView) -> (CLLocationCoordinate2D, CLLocationCoordinate2D) {
        let nePoint = CGPointMake((map.bounds.origin.x + map.bounds.size.width), map.bounds.origin.y);
        let swPoint = CGPointMake(map.bounds.origin.x, (map.bounds.origin.y + map.bounds.size.height));
        
        //Then transform those point into lat,lng values
        let neCoord = map.convertPoint(nePoint, toCoordinateFromView: map)
        let swCoord = map.convertPoint(swPoint, toCoordinateFromView: map)
        
        return (neCoord, swCoord)
    }
    
    // MARK: - LoginWithClimate delegate functions
    
    func didLoginWithClimate(session: Session) {
       // print("Logged in.")
        self.user2_Name=session.userInfo.firstName+": "
        self.currentSession=session;
        self.clearMap()
        self.drawCLUs(session.accessToken)
        self.status=true;
        self.loginViewController.hidesBottomBarWhenPushed=true;
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.blueScore.text=self.user2_Name+"0";
        })
    
    }
    
    
    // MARK: - MKMapView delegate functions
    
    func mapView(mapView: MKMapView,rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if (overlay.isKindOfClass(MKPolygon)) {
            let renderer = MKPolygonRenderer(overlay: overlay)
            //print(overlay)
            var color:UIColor
            print(self.counter)
            if (self.counter==0)
            {
                return renderer
            }
            else
            if (self.counter % 2 == 0)
            {
                color = UIColor.redColor()
            }
            else
            {
                color = UIColor.blueColor()
            }
            renderer.strokeColor = color
            renderer.fillColor = color
            renderer.alpha = 0.5
            renderer.lineWidth = 1.0
            return renderer
        } else {
            print("ERROR: Found overlay of type \(overlay.dynamicType)")
            return MKOverlayRenderer()
        }
    }
    /*
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        
        print("regionDidChangeAnimated")
        if (self.status)
        {
            self.clearMap()
            self.counter=0;
            self.player1_score = 0.0;
            self.player2_score = 0.0;
            
            //self.drawCLUs(self.currentSession.accessToken)
        }

    }*/
    
    
    // MARK: - Business functions
    
    func drawCLUs(myAccessToken: String) {
        self.fetchCLUs(myAccessToken, corners: self.cornerCoordinatesForMapView(self.mapView)) {
            (response: [String: AnyObject]) in
            let clus = response["features"] as! [[String: AnyObject]]
         
            let overlays: [[MKOverlay]] = clus.map() {
                (clu: [String: AnyObject]) -> [MKOverlay] in
                let geometry = GFGeometry(geoJSONGeometry: clu["geometry"] as! [String: AnyObject])
                return geometry.mkMapOverlays() as! [MKOverlay]
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                overlays.forEach() {
                    (os: [MKOverlay]) -> () in
                    self.mapView.addOverlays(os)
                }
            }
        }
    }
    
    func fetchCLUs(myAccessToken: String, corners: (neCoord: CLLocationCoordinate2D, swCoord: CLLocationCoordinate2D), completion: ([String: AnyObject] -> Void)) {
        let (neCoord, swCoord) = corners

        let components: NSURLComponents = NSURLComponents(string: "https://hackillinois.climate.com/api/clus")!
        components.queryItems = [NSURLQueryItem(name: "ne_lat", value: neCoord.latitude.description),
                                 NSURLQueryItem(name: "ne_lon", value: neCoord.longitude.description),
                                 NSURLQueryItem(name: "sw_lat", value: swCoord.latitude.description),
                                 NSURLQueryItem(name: "sw_lon", value: swCoord.longitude.description)]
        
        let request = NSMutableURLRequest(URL: components.URL!)
        request.setValue("Bearer \(myAccessToken)", forHTTPHeaderField: "Authorization")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) in
            
            guard error == nil && (response as? NSHTTPURLResponse)?.statusCode == 200 else {
                print(error)
                print(response)
                print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                return
            }
            
            let jsonObject = try! NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [String: AnyObject]
            completion(jsonObject)
        }
        
        task.resume()
    }
}

