// cjy--seed group structure
import Foundation


//totalSGs=[SG,SG,SG,...]
public struct SG {
    var pros: [Program]  // included seeds
    var newEdges: [ProgramAspects]  // included seeds
    var triEdges: Set<UInt32> // triggered edges
    var ages: [Int]
    var execTime: TimeInterval
    var selectedNum: Int
    var ProsNum: Int
    
    init(pros: [Program], newEdges: [ProgramAspects], triEdges: Set<UInt32>, ages: [Int], execTime: TimeInterval, selectedNum: Int, ProsNum: Int) {
        self.pros = pros
        self.newEdges = newEdges
        self.ages = ages
        self.triEdges = triEdges
        self.execTime = execTime // 初始化 execTime
        self.selectedNum = selectedNum
        self.ProsNum = ProsNum
    }
    
    init() {
        self.pros = [] // 初始化 RingBuffer
        self.newEdges = []// 初始化 RingBuffer
        self.triEdges = Set<UInt32>() // 给 triEdges 初始化一个空的集合作为默认值
        self.ages = []
        self.execTime = 0 // 初始化 execTime 为 0
        self.selectedNum = 0
        self.ProsNum = 0
    }

    // 获取改组的覆盖路径
    public mutating func settriEdgesOfGroup() -> Set<UInt32> {
        let triEdgesG = pros.flatMap { $0.triggeredEdge }
        self.triEdges = Set(triEdgesG)
        return self.triEdges
    }

     
    // 设置 pros 的函数
    public mutating func setPros(_ newPros: [Program]) {
        self.pros = newPros
    }
    
    // 获取 pros 的函数
    public func getPros() -> [Program] {
        return self.pros
    }
    
    // 设置 newEdges 的函数
    public mutating func setNewEdges(_ newNewEdges: [ProgramAspects]) {
        self.newEdges = newNewEdges
    }
    
    // 获取 newEdges 的函数
    public func getNewEdges() -> [ProgramAspects] {
        return self.newEdges
    }
    
    // 获取 triEdges 的函数
    public func getTriEdges() -> Set<UInt32> {
        return self.triEdges
    }
    
    // 设置 execTime 的函数
    public mutating func setExecTime(_ newExecTime: TimeInterval) {
        self.execTime = newExecTime
    }
    
    // 获取 execTime 的函数
    public func getExecTime() -> TimeInterval {
        return self.execTime
    }
    
    // 获取 selectedNum 的函数
    public func getSelectedNum() -> Int {
        return self.selectedNum
    }
    
    // 获取 selectedNum 的函数
    public func getProsNum() -> Int {
        return self.ProsNum
    }
    
    // 获取 ages 的函数
    public func getAges() -> [Int] {
        return self.ages
    }

    // 找到最小比率值对应的所有下标
    public func indicesOfMinRatio() -> [Int] {
        var minRatio = Double.infinity
        var minRatioIndices = [Int]()
        
        // 计算最小比率
        for i in 0..<pros.count {
            let ratio = Double(newEdges[i].count) / Double(ages[i])
            if ratio < minRatio {
                minRatio = ratio
            }
        }
        
        // 找出所有最小比率值对应的下标
        for i in 0..<pros.count {
            let ratio = Double(newEdges[i].count) / Double(ages[i])
            if ratio == minRatio {
                minRatioIndices.append(i)
            }
        }
        
        return minRatioIndices
    }
    
    // 找到最大比率值对应的所有下标
    public func indicesOfMaxRatio() -> [Int] {
        var maxRatio = -Double.infinity
        var maxRatioIndices = [Int]()
        
        // 计算最大比率
        for i in 0..<pros.count {
            if ages[i]>1{
                let ratio = Double(newEdges[i].count) / Double(ages[i])
                if ratio > maxRatio {
                    maxRatio = ratio
                }
            }
        }
        
        // 找出所有最大比率值对应的下标
        
            for i in 0..<pros.count {
                if ages[i]>1{
                let ratio = Double(newEdges[i].count) / Double(ages[i])
                if ratio == maxRatio {
                    maxRatioIndices.append(i)
                }
            }
        }
        
        return maxRatioIndices
    }

    public mutating func addPro(_ program: Program, _ aspects: ProgramAspects) {
        // var DeleteDone: Int = 0
        while ProsNum > 10 {   
            for i in (0..<pros.count).reversed() { // Reversed loop to avoid index out of range after removing element
                if ages[i] > 15 {
                    pros.remove(at: i)
                    newEdges.remove(at: i)
                    ages.remove(at: i)
                    ProsNum -= 1
                    // DeleteDone = 1
                }
            }
            // if DeleteDone == 0 {
            //     let deleteIndex = indicesOfMinRatio() // Corrected variable name
            //     for j in (0..<deleteIndex.count).reversed() { // Reversed loop
            //         pros.remove(at: deleteIndex[j])
            //         newEdges.remove(at: deleteIndex[j])
            //         ages.remove(at: deleteIndex[j]) // Corrected variable name
            //         ProsNum -= 1
            //     }
            // }
            // DeleteDone = 0 
        }
        if(program.addSGed == 0){
            pros.append(program)
            newEdges.append(aspects)
            ages.append(1)
            settriEdgesOfGroup() // Assuming this is a valid method call
            ProsNum += 1
            program.addSGed = 1
        }
              
        if ProsNum > 10 {
            let deleteIndex = indicesOfMinRatio() // Corrected variable name
            for j in (0..<deleteIndex.count).reversed() { // Reversed loop
                pros.remove(at: deleteIndex[j])
                newEdges.remove(at: deleteIndex[j])
                ages.remove(at: deleteIndex[j]) // Corrected variable name
                ProsNum -= 1
            }
        }

    }

     // Method to select the program with the smallest size from pros
    public mutating func selectProWithMinSize() -> Program? {
        // Check if pros is empty
        guard !pros.isEmpty else {
            return nil
        }
        
        // Initialize the minimum size and the index of the program with the minimum size
        var minSize = Int.max
        var selectedIndex: Int?
        
        // Iterate through pros to find the program with the minimum size
        for (index, program) in pros.enumerated() {
            if program.size < minSize {
                minSize = program.size
                selectedIndex = index
            }
        }
        
        // Return the program with the minimum size
        if let index = selectedIndex {
        ages[index] += 1

            return pros[index]
        } else {
            return nil
        }
    }

     // Method to select the program with the minimum execTime from pros
    public mutating func selectProWithMinTime() -> Program? {
        // Check if pros is empty
        guard !pros.isEmpty else {
            return nil
        }
        
        // Initialize the minimum execTime and the index of the program with the minimum execTime
        var minExecTime = TimeInterval.greatestFiniteMagnitude
        var selectedIndex: Int?
        
        // Iterate through pros to find the program with the minimum execTime
        for (index, program) in pros.enumerated() {
            if program.execTime < minExecTime {
                minExecTime = program.execTime
                selectedIndex = index
            }
        }
        
        // Return the program with the minimum execTime
        if let index = selectedIndex {
            ages[index] += 1

            return pros[index]
        } else {
            return nil
        }
    }
    // public mutating func selectProIndexWithMinTime() -> Int? {
    //     // Check if pros is empty
    //     guard !pros.isEmpty else {
    //         return nil
    //     }
        
    //     // Initialize the minimum execTime and the index of the program with the minimum execTime
    //     var minExecTime = TimeInterval.greatestFiniteMagnitude
    //     var selectedIndex: Int?
        
    //     // Iterate through pros to find the program with the minimum execTime
    //     for (index, program) in pros.enumerated() {
    //         if program.execTime < minExecTime {
    //             minExecTime = program.execTime
    //             selectedIndex = index
    //         }
    //     }
        
    //     // Return the index of the program with the minimum execTime
    //     return selectedIndex
    // }


    public mutating func selectProWithNewEff() -> Program {
        for i in 0..<pros.count {
            let program=pros[i]
            if ages[i] == 0 {
                assert(!program.isEmpty)
                ages[i] += 1
                return program
            }
        }
        var ratioOFedgesWage : [Double] = []
        for i in 0..<pros.count {
            ratioOFedgesWage.append(Double(newEdges[i].count) / Double(ages[i]))
        }

        guard let maxRatio = ratioOFedgesWage.max() else {
            fatalError("Failed to find maximum ratio")
        }

        var maxRatioIndices: [Int] = []
        for (index, ratio) in ratioOFedgesWage.enumerated() {
            if ratio == maxRatio {
                maxRatioIndices.append(index)
            }
        }

        let sortedMaxRatioIndices = maxRatioIndices.sorted { (index1, index2) in
            if newEdges[index1].count != newEdges[index2].count {
                return newEdges[index1].count > newEdges[index2].count
            } else {
                return ages[index1] < ages[index2]
            }
        }

        let finalIndex: Int
        if let firstIndex = sortedMaxRatioIndices.first {
            finalIndex = firstIndex
        } else {
            finalIndex = maxRatioIndices.randomElement() ?? 0
        }

        let program = pros[finalIndex]
        assert(!program.isEmpty)
        ages[finalIndex] += 1
        return program
    }

    func printValues() {
        for (index, program) in pros.enumerated() {
            print("Program \(index + 1):")
            print("Program-code: \(program.code)")
            // 打印其他 program 属性...
        }
        for (index, aspects) in newEdges.enumerated() {
            print("ProgramAspects-count \(index + 1): \(aspects.count)")
        }
        print("triEdges: \(triEdges)")
        print("ages: \(ages)")
        print("execTime: \(execTime)")
        print("selectedNum: \(selectedNum)")
        print("ProsNum: \(ProsNum)")
    }
}


public extension SG {
    mutating func findProgramWithMaxExecTime() -> Program? {
        var maxExecTime: TimeInterval = 0
        var programWithMaxExecTime: Program?
        for pro in self.pros {
            if pro.execTime > maxExecTime {
                maxExecTime = pro.execTime
                programWithMaxExecTime = pro
            }
        }
       
        // execTime = maxExecTime
        // cjy--pending
        // 计算programWithMaxExecTime的指令集合
        // cjy--pending
        return programWithMaxExecTime
    }
}
