import Foundation

@objc(XpcProtocol) protocol XpcProtocol {
    func uppercase(_ string: String, withReply: ((String)->Void))
}
