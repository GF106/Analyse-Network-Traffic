//
//  ViewController.swift
//  Analyse Network Traffic
//
//  Created by Andrey on 20.01.2021.
//

import Cocoa

class ViewController: NSViewController {

    
    private let txtStart = "Start"
    private let txtStop = "Stop"
    private let txtUnits = ["bytes", "kb", "mb", "gb"]
    private let txtPackages = "pkg"
    
    @IBOutlet weak var lblInputBytes: NSTextField!
    @IBOutlet weak var lblOutputBytes: NSTextField!
    @IBOutlet weak var lblOutputPack: NSTextField!
    @IBOutlet weak var lblInputPack: NSTextField!
    @IBOutlet weak var btnStart: NSButton!
    @IBOutlet weak var segmentUnits: NSSegmentedControl!
    
    private let monitoringTraffic = MonitoringTraffic()
    
    private var isRunning = false{
        didSet{
            btnStart.title = isRunning ? txtStop : txtStart
            monitoringTraffic.isMonitoring = isRunning
        }
    }
    
    private func setupView(){
        
        for index in 0..<segmentUnits.segmentCount{
            segmentUnits.setLabel(txtUnits[index], forSegment: index)
        }
        let indexSegment = segmentUnits.indexOfSelectedItem
        
        btnStart.title = txtStart
        lblInputBytes.stringValue = "0 \(txtUnits[indexSegment])"
        lblOutputBytes.stringValue = "0 \(txtUnits[indexSegment])"
        lblInputPack.stringValue = "0 \(txtPackages)"
        lblOutputPack.stringValue = "0 \(txtPackages)"
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        monitoringTraffic.delegate = self
    }

    @IBAction func actionStart(_ sender: NSButton) {
        isRunning = !isRunning
    }
}
extension ViewController: MonitoringTrafficDelegate{
    func monitoringTrafficDidComplitedCalculate(withError error: ErrorMonitoringTraffic?) {
        DispatchQueue.main.async {
            guard error == nil else {
                print(error!.rawValue)
                self.isRunning = false
                return
            }
            let indexSegment = self.segmentUnits.indexOfSelectedItem
            self.lblInputBytes.stringValue =
                "\(String(format: "%.2f", self.monitoringTraffic.currentInputBytes.convertBytes(withIndex: indexSegment))) \(self.txtUnits[indexSegment])"
            self.lblOutputBytes.stringValue =
                "\(String(format: "%.2f", self.monitoringTraffic.currentOutputBytes.convertBytes(withIndex: indexSegment))) \(self.txtUnits[indexSegment])"
            self.lblInputPack.stringValue = "\(self.monitoringTraffic.currentInputPkg) \(self.txtPackages)"
            self.lblOutputPack.stringValue = "\(self.monitoringTraffic.currentOutputPkg) \(self.txtPackages)"
        }
    }
}
extension Double{
    func convertBytes(withIndex index: Int) -> Double{
        switch index {
        case 0:
            return self
        case 1:
            return self / 1024
        case 2:
            return self / 1024 / 1024
        case 3:
            return self / 1024 / 1024 / 1024
        default:
            return self
        }
    }
}

