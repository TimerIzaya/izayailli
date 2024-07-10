public let numberOfBits = 80000
public let numberOfUInts = (numberOfBits + 31) / 32 // 计算所需的UInt数量


public func setBit(in binaryNumber: inout [UInt], at index: Int) {
    let uintIndex = index / 32
    let bitIndex = index % 32
    binaryNumber[uintIndex] |= 1 << bitIndex
}

public func clearBit(in binaryNumber: inout [UInt], at index: Int) {
    let uintIndex = index / 32
    let bitIndex = index % 32
    binaryNumber[uintIndex] &= ~(1 << bitIndex)
}

public func checkBit(in binaryNumber: [UInt], at index: Int) -> Bool {
    let uintIndex = index / 32
    let bitIndex = index % 32
    return (binaryNumber[uintIndex] & (1 << bitIndex)) != 0
}

public func countCommonBits(_ bitEdge_1: [UInt], _ bitEdge_2: [UInt]) -> Int {
    guard bitEdge_1.count == bitEdge_2.count else {
        fatalError("bitEdge_1 and bitEdge_2 must have the same length.")
    }

    var count = 0
    for i in 0..<bitEdge_1.count {
        let commonBits = bitEdge_1[i] & bitEdge_2[i]
        count += commonBits.nonzeroBitCount
    }

    return count
}

// // 示例用法
// var binaryNumber = [UInt](repeating: 0, count: numberOfUInts)
// setBit(in: &binaryNumber, at: 1234)
// clearBit(in: &binaryNumber, at: 5678)
// print(checkBit(in: binaryNumber, at: 1234)) // 输出: true
// print(checkBit(in: binaryNumber, at: 5678)) // 输出: false
