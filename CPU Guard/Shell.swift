//
//  Shell.swift
//  CPU Guard
//
//  Created by Cenk Altı on 2021-11-13.
//

import Foundation

func runPs() -> [Int:MyProcessInfo] {
    var currentProcesses = [Int:MyProcessInfo]()
    
    let output: String! = shell(launchPath: "/bin/ps", arguments:["-opid=,%cpu=,args=", "-e"])
    if output == nil {
        return currentProcesses
    }
    
    // Collect current processes
    for line in output.components(separatedBy: "\n") {
        let words = line.components(separatedBy: " ").filter({ $0 != "" })
        if words.count < 3 {
            continue
        }
        
        let pid = NSString(string: words[0]).integerValue
        if pid == 0 {
            continue
        }
        
        let cpu = NSString(string: words[1]).doubleValue
        let command = words[2].components(separatedBy: "/").last!
        let arguments = Array(words[2..<words.count])
        
        currentProcesses[pid] = MyProcessInfo(pid: pid, cpu: cpu, command: command, arguments: arguments)
    }
    
    return currentProcesses
}

func shell(launchPath: String, arguments: [String] = []) -> String? {
    let task = Process()
    task.currentDirectoryPath = "/"
    task.launchPath = launchPath
    task.arguments = arguments
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    
    var output: String?
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let s = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
        output = String(s)
    }
    
    task.waitUntilExit()
    if task.terminationStatus != 0 {
        return nil
    }
    
    return output
}
