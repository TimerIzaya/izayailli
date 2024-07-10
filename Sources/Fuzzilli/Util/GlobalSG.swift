import Foundation

// class GlobalSG {
//     static let shared = GlobalSG()
    
//     // 全局变量
//     public var sgArray: [SG] = []
    
//     private init() {}
// }
public var sgArray: [SG] = []

// public func addSG(_ sg: SG) {
//     sgArray.append(sg)
// }

// public func removeSG(at index: Int) {
//     sgArray.remove(at: index)
// }

// public func getSG(at index: Int) -> SG? {
//     guard index >= 0 && index < sgArray.count else {
//         return nil
//     }
//     return sgArray[index]
// }

// public func getAllSGs() -> [SG] {
//     return sgArray
// }

// public func clearAllSGs() {
//     sgArray.removeAll()
// }

// public func getSGArrayLength() -> Int {
//     return sgArray.count
// }