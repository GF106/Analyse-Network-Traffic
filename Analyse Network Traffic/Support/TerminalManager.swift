//
//  TerminalManager.swift
//  Analyse Network Traffic
//
//  Created by Andrey on 20.01.2021.
//

import Foundation


class TerminalManager{
    
    private var task: Process?
    
    func valueFromTerminal(withCommand command: String,
                                   withArguments arguments: String,
                                   complitedHeader: @escaping (_ output: String?,_ error: String?) -> () = { _,_ in }){
        if task != nil{
            task?.terminate()
            task = nil
        }
        
        task = Process()
        let pipeOutput = Pipe()
        let pipeError = Pipe()
        
        task?.launchPath = command
        task?.arguments = ["-c", arguments]
        
        task?.standardOutput = pipeOutput
        task?.standardError = pipeError
        
        task?.terminationHandler = { process in
            let outputData = pipeOutput.fileHandleForReading.readDataToEndOfFile()
            let errorData = pipeError.fileHandleForReading.readDataToEndOfFile()
            let error = String(data: errorData, encoding: .utf8)
            let output = String(data: outputData, encoding: .utf8)
            complitedHeader(output, error?.isEmpty == true ? nil : error)
        }
        
        task?.launch()
    }
}
