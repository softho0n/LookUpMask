//
//  ViewController.swift
//  MaskTableView
//
//  Created by Seunghun Shin on 2020/03/11.
//  Copyright © 2020 SeunghunShin. All rights reserved.
//

import UIKit
import AlamofireObjectMapper
import Alamofire
import CoreLocation

class CustomMask {
    var addr: String?
    var code: String?
    var created_at: String?
    var lat: Double?
    var lng: Double?
    var name: String?
    var remain_stat: String?
    var stock_at: String?
    var type: String?
    var stock_level: Int = 0
    var distance: Double = 0
//    재고 상태[100개 이상(녹색): 'plenty' / 30개 이상 100개미만(노랑색): 'some' / 2개 이상 30개 미만(빨강색): 'few' / 1개 이하(회색): 'empty']
}

class ViewController: UIViewController {

    var realData: [CustomMask] = []
    var filterData: [CustomMask] = []
    var myLocation: CLLocation!
    var searching = false
    var refreshControl = UIRefreshControl()
    
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    
    
    @IBAction func refreshData(_ sender: Any) {
        updateCurrentLocation()
    }
    
    lazy var locationManager:CLLocationManager = {
        let m = CLLocationManager()
        m.delegate = self as! CLLocationManagerDelegate
        return m
    }()
    

    @IBAction func sortByStuff(_ sender: Any) {
        searching = false
        searchBar.text = ""
        self.view.endEditing(true)
        self.realData = self.realData.sorted {
            $0.stock_level > $1.stock_level
        }
        self.tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .bottom, animated: true)
        self.tableView.reloadData()
    }
    
    @IBAction func sortByDistance(_ sender: Any) {
        searching = false
        searchBar.text = ""
        self.view.endEditing(true)
        self.realData = self.realData.sorted {
            $0.distance < $1.distance
        }
        self.tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .bottom, animated: true)
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestAPITwo()
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                updateCurrentLocation()
            case .denied, .restricted:
                break
            }
        } else {
            
        }
        setupBackButton()
        searchBar.backgroundImage = UIImage()
        refreshControl.attributedTitle = NSAttributedString(string: "데이터 업데이트 중...")
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: UIControl.Event.valueChanged)
        tableView.addSubview(refreshControl)
        
    }
    
    @objc func refresh(sender:AnyObject) {
        updateCurrentLocation()
        defer {
            self.refreshControl.endRefreshing()
        }
    }
    
    func requestAPITwo() {
        // URL 인스턴스를 생성해줍니다.
        let url = URL(string: "https://8oi9s0nnth.apigw.ntruss.com/corona19-masks/v1/storesByGeo/json")
        // 파라미터 값을 미리 세팅해줍니다.
        let params = ["lat":35.0947847,"lng":129.0179239,"m":5000]
        // Alamofire 를 이용하여 서버의 API 데이터를 요청합니다.
        AF.request(url!, method: .get, parameters: params, encoding: URLEncoding.default, headers: nil, interceptor: nil).responseObject { (response: AFDataResponse<Mask>) in // 디자인 클래스의 이름으로 설정해주세요.
                let result = response.value // result 변수에는 Mask instance가 자동으로 Mapping 되어서 저장됩니다.
                for item in (result?.stores)!{
                    print(item.addr)
                    print(item.code)
                    print(item.created_at)                
                }
        }
    }
    
    
    
    func requestMaskAPI(_ lat: Double, _ lng: Double) {
        let url = URL(string: "https://8oi9s0nnth.apigw.ntruss.com/corona19-masks/v1/storesByGeo/json")
        let params = ["lat":lat,
                      "lng":lng,
                      "m":5000]
        AF.request(url!, method: .get, parameters: params, encoding: URLEncoding.default, headers: nil, interceptor: nil).responseObject { (response: AFDataResponse<Mask>) in
            let result = response.value
            self.infoLabel.text = "총 \((result?.count)!)개의 판매 약국이 주변에 존재합니다."
            self.realData.removeAll()
            for item in (result?.stores)! {
                var instance = self.setCustomMaskInstance(item)
                instance.distance = self.myLocation.distance(from: CLLocation(latitude: item.lat!, longitude: item.lng!))
                switch (item.remain_stat) {
                    case "plenty":
                        instance.stock_level = 3
                        break
                    case "some":
                        instance.stock_level = 2
                        break
                    case "few":
                        instance.stock_level = 1
                        break
                    case "empty":
                        instance.stock_level = 0
                        break
                    default:
                        break
                }
                self.realData.append(instance)
            }
            self.realData = self.realData.sorted {
                $0.stock_level > $1.stock_level
            }
            self.tableView.reloadData()
        }
    }
    
    func setCustomMaskInstance(_ param: Mask.Stores!) -> CustomMask {
        let instance = CustomMask()
        instance.addr = param.addr
        instance.code = param.code
        instance.created_at = param.code
        instance.lat = param.lat
        instance.lng = param.lng
        instance.name = param.name
        instance.remain_stat = param.remain_stat
        return instance
    }
}

extension ViewController: CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching {
            return filterData.count
        } else {
            return realData.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RowCell", for: indexPath) as! CustomCell
        
        if searching {
            cell.name.text = filterData[indexPath.row].name!
            cell.addr.text = filterData[indexPath.row].addr!

            cell.distance.text = String(format: "%.01fkm", filterData[indexPath.row].distance / 1000)
            
                switch filterData[indexPath.row].stock_level {
                case 3:
                    cell.status.textColor = UIColor.blue
                    cell.status.text = "100개 이상"
                    cell.statusImage.image = UIImage(named: "100.png")
                    break
                case 2:
                    cell.status.textColor = UIColor(hex: "#5b8c85")
                    cell.status.text = "30개 이상"
                    cell.statusImage.image = UIImage(named: "30.png")
                    break
                case 1:
                    cell.status.textColor = UIColor.red
                    cell.status.text = "2개 이상"
                    cell.statusImage.image = UIImage(named: "2.png")
                    break
                case 0:
                    cell.status.textColor = UIColor.black
                    cell.status.text = "재고 없음"
                    cell.statusImage.image = UIImage(named: "0.png")
                    break
                default:
                    cell.status.text = "Error"
                }
        } else {
            cell.name.text = realData[indexPath.row].name!
            cell.addr.text = realData[indexPath.row].addr!

            cell.distance.text = String(format: "%.01fkm", realData[indexPath.row].distance / 1000)
            
                switch realData[indexPath.row].stock_level {
                case 3:
                    cell.status.textColor = UIColor.blue
                    cell.status.text = "100개 이상"
                    cell.statusImage.image = UIImage(named: "100.png")
                    break
                case 2:
                    cell.status.textColor = UIColor(hex: "#5b8c85")
                    cell.status.text = "30개 이상"
                    cell.statusImage.image = UIImage(named: "30.png")
                    break
                case 1:
                    cell.status.textColor = UIColor.red
                    cell.status.text = "2개 이상"
                    cell.statusImage.image = UIImage(named: "2.png")
                    break
                case 0:
                    cell.status.textColor = UIColor.black
                    cell.status.text = "재고 없음"
                    cell.statusImage.image = UIImage(named: "0.png")
                    break
                default:
                    cell.status.text = "Error"
                }
        }
        
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! CustomCell
        UIPasteboard.general.string = cell.addr.text
        print(UIPasteboard.general.string)
        
        let alert = UIAlertController(title: "\((cell.name.text)!)", message: "주소: \((UIPasteboard.general.string)!) 이/가 복사되었습니다.", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "확인", style: .default, handler: nil)
        
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    

    func updateCurrentLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.first {
            self.myLocation = loc
            self.requestMaskAPI(loc.coordinate.latitude, loc.coordinate.longitude)
            let decoder = CLGeocoder()
            decoder.reverseGeocodeLocation(loc) { (placemarks, error) in
                if let place = placemarks?.first {
                    if let country = place.administrativeArea, let gu = place.locality, let dong = place.subLocality {
                        print("\(country) \(gu) \(dong)")
                        self.navigationItem.title = "\(country) \(gu) \(dong)"
                    } else {
                        self.navigationItem.title = place.name
                        print(place.name)
                    }
                }
            }
        }
        manager.stopUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            updateCurrentLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        manager.stopUpdatingLocation()
    }
}

extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        return nil
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterData = realData.filter({$0.name!.prefix(searchText.count) == searchText})
        searching = true
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        searching = false
        searchBar.text = ""
        tableView.reloadData()
    }
}

class CustomCell: UITableViewCell {
    @IBOutlet var name: UILabel!
    @IBOutlet var addr: UILabel!
    @IBOutlet var distance: UILabel!
    @IBOutlet var status: UILabel!
    @IBOutlet var statusImage: UIImageView!
}

extension UIViewController {
    func setupBackButton() {
        let customBackButton = UIBarButtonItem(title: "뒤로 가기", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = customBackButton
    }
}

