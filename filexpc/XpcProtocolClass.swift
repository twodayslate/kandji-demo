import Foundation

class XpcProtocolClass: XpcProtocol {
    // https://stackoverflow.com/a/50035059/193772
    func uppercase(_ string: String, withReply: ((String) -> Void)) {
        
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", "file '\(string)'"]
        task.launchPath = "/bin/zsh"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        withReply(output)
    }
}
