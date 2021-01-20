//
//  MonitoringTraffic.swift
//  Analyse Network Traffic
//
//  Created by Andrey on 20.01.2021.
//
import Foundation


enum ErrorMonitoringTraffic: String{
    case notComplitedCommandTerminal = "Not complited command terminal"
    case notFoundSymbols = "Not found symbols"
    case notFoundInterface = "Not found interface"
    case notFoundRowWithTraffic = "Not found row with traffic"
    case countDataNotEleven = "Count data not eleven"
}
protocol MonitoringTrafficDelegate {
    func monitoringTrafficDidComplitedCalculate(withError: ErrorMonitoringTraffic?)
}

class MonitoringTraffic{
    
    private let removeSymbolsForInterface = "  interface: "
    
    var delegate: MonitoringTrafficDelegate?
    
    var isMonitoring = false {
        didSet{
            isMonitoring ? start() : stop()
        }
    }
    var interfaceName = ""
    var currentInputBytes = 0.0
    var currentOutputBytes = 0.0
    var currentInputPkg = 0
    var currentOutputPkg = 0
    
    private let queue = DispatchQueue(label: "com.Andrey.traffic.timer", attributes: .concurrent)
    private var timer: DispatchSourceTimer?
    private let terminalManager = TerminalManager()
    
    
    private func start(){
        if timer != nil{
            stop()
        }
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.setEventHandler { [weak self] in
            self?.headerTimer()
        }
        timer?.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(300))
        timer?.resume()
    }
    private func stop(){
        timer?.cancel()
        timer?.setEventHandler(handler: {})
        timer = nil
    }
    private func headerTimer(){
        terminalManager.valueFromTerminal(withCommand: "/bin/sh", withArguments: "route get example.com | grep interface") { (routeValue, error)  in
            
            guard let routeValue = routeValue, error == nil else {
                self.delegate?.monitoringTrafficDidComplitedCalculate(withError: .notComplitedCommandTerminal)
                return
            }
            guard routeValue.contains(self.removeSymbolsForInterface) else {
                self.delegate?.monitoringTrafficDidComplitedCalculate(withError: .notFoundSymbols)
                return
            }
            let foundInterface = "\(routeValue.dropFirst(self.removeSymbolsForInterface.count).dropLast())"
            
            guard let interface = NetInterface.allInterfaces().first(where: {$0.name == foundInterface})?.name ??
                    NetInterface.allInterfaces().first?.name else {
                self.delegate?.monitoringTrafficDidComplitedCalculate(withError: .notFoundInterface)
                return
            }
            
            if self.interfaceName != interface{
                self.interfaceName = interface
                self.currentInputBytes = 0
                self.currentOutputBytes = 0
            }
            
            self.terminalManager.valueFromTerminal(withCommand: "/bin/sh", withArguments: "netstat -ib -I \(interface)") { (netstatValue, error) in
                
                guard let netstatValue = netstatValue, error == nil else {
                    self.delegate?.monitoringTrafficDidComplitedCalculate(withError: .notComplitedCommandTerminal)
                    return
                }
                
                guard let row = netstatValue.split(separator: "\n").last else {
                    self.delegate?.monitoringTrafficDidComplitedCalculate(withError: .notFoundRowWithTraffic)
                    return
                }
                
                let arrayRow = row.split(separator: " ")
                
                guard arrayRow.count == 11 else {
                    self.delegate?.monitoringTrafficDidComplitedCalculate(withError: .countDataNotEleven)
                    return
                }
                
                self.currentInputBytes = ( "\(arrayRow[6])" as NSString).doubleValue
                self.currentOutputBytes = ( "\(arrayRow[9])" as NSString).doubleValue
                self.currentInputPkg = ( "\(arrayRow[4])" as NSString).integerValue
                self.currentOutputPkg = ( "\(arrayRow[7])" as NSString).integerValue
                
                
                
                self.delegate?.monitoringTrafficDidComplitedCalculate(withError: nil)
            }
        }
    }
    
    
}
