// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

public class FuzzEngine: ComponentBase {
    private var postProcessor: FuzzingPostProcessor? = nil

    override init(name: String) {
        super.init(name: name)
    }

    // Install a post-processor that is executed for every generated program and can modify it (by returning a different program).
    public func registerPostProcessor(_ postProcessor: FuzzingPostProcessor) {
        assert(self.postProcessor == nil)
        self.postProcessor = postProcessor
    }

    // Performs a single round of fuzzing using the engine.
    public func fuzzOne(_ group: DispatchGroup) {
        fatalError("Must be implemented by child classes")
    }

    final func execute(_ program: Program, withTimeout timeout: UInt32? = nil) -> ExecutionOutcome {
        let program = postProcessor?.process(program, for: fuzzer) ?? program

          // cjy--get old and new edge hit count to compute current program's triggered edges 
        // cjy--define 
        var oldedgeArray: [UInt32] = []
        var curedgeArray: [UInt32] = []
        // cjy--define

        // cjy--get old edge hit count
        // 在使用 evaluator 之前，先检查它的类型
        if let oldcoverageEvaluator = fuzzer.evaluator as? ProgramCoverageEvaluator {
            oldedgeArray = oldcoverageEvaluator.getEdgeHitCounts()
         } 
        // cjy--get old edge hit count
        fuzzer.dispatchEvent(fuzzer.events.ProgramGenerated, data: program)

        let execution = fuzzer.execute(program, withTimeout: timeout, purpose: .fuzzing)

        switch execution.outcome {
            case .crashed(let termsig):
                fuzzer.processCrash(program, withSignal: termsig, withStderr: execution.stderr, withStdout: execution.stdout, origin: .local, withExectime: execution.execTime)
                program.contributors.generatedCrashingSample()
                   // cjy--case 1: get new edge hit count and compute current program's triggered edges
                if let curcoverageEvaluator = fuzzer.evaluator as? ProgramCoverageEvaluator {
                    curedgeArray = curcoverageEvaluator.getEdgeHitCounts()
                }
                program.triggeredEdge = Set(calHitCountDiff(oldedgeArray, curedgeArray))
                // cjy--case 1: get new edge hit count and compute current program's triggered edges 
            case .succeeded:
                fuzzer.dispatchEvent(fuzzer.events.ValidProgramFound, data: program)
                var isInteresting = false
                if let aspects = fuzzer.evaluator.evaluate(execution) {
                    if fuzzer.config.enableInspection {
                        program.comments.add("Program may be interesting due to \(aspects)", at: .footer)
                        program.comments.add("RUNNER ARGS: \(fuzzer.runner.processArguments.joined(separator: " "))", at: .header)
                    }
                     // cjy--case 2: get new edge hit count and compute current program's triggered edges
                if let curcoverageEvaluator = fuzzer.evaluator as? ProgramCoverageEvaluator {
                    curedgeArray = curcoverageEvaluator.getEdgeHitCounts()
                }
                program.triggeredEdge = Set(calHitCountDiff(oldedgeArray, curedgeArray))
                    isInteresting = fuzzer.processMaybeInteresting(program, havingAspects: aspects, origin: .local)
                }

                if isInteresting {
                    program.contributors.generatedInterestingSample()
                } else {
                    program.contributors.generatedValidSample()
                }

            case .failed(_):
                if fuzzer.config.enableDiagnostics {
                    program.comments.add("Stdout:\n" + execution.stdout, at: .footer)
                }
                fuzzer.dispatchEvent(fuzzer.events.InvalidProgramFound, data: program)
                program.contributors.generatedInvalidSample()

            case .timedOut:
                fuzzer.dispatchEvent(fuzzer.events.TimeOutFound, data: program)
                program.contributors.generatedTimeOutSample()
        }

        if fuzzer.config.enableDiagnostics {
            // Ensure deterministic execution behaviour. This can for example help detect and debug REPRL issues.
            ensureDeterministicExecutionOutcomeForDiagnostic(of: program)
        }

        return execution.outcome
    }

    private final func ensureDeterministicExecutionOutcomeForDiagnostic(of program: Program) {
        let execution1 = fuzzer.execute(program, purpose: .other)
        let stdout1 = execution1.stdout, stderr1 = execution1.stderr
        let execution2 = fuzzer.execute(program, purpose: .other)
        switch (execution1.outcome, execution2.outcome) {
        case (.succeeded, .failed(_)),
             (.failed(_), .succeeded):
            let stdout2 = execution2.stdout, stderr2 = execution2.stderr
            logger.warning("""
                Non-deterministic execution detected for program
                \(fuzzer.lifter.lift(program))
                // Stdout of first execution
                \(stdout1)
                // Stderr of first execution
                \(stderr1)
                // Stdout of second execution
                \(stdout2)
                // Stderr of second execution
                \(stderr2)
                """)
        default:
            break
        }
    }

    // cjy--get array(triggered edges of the current seed)
    public func calHitCountDiff(_ array1: [UInt32], _ array2: [UInt32]) -> [UInt32] {
        var resultTriggerEdge: [UInt32] = []
        // print(array1.count)
        // 判断长度是否相等
        if array1.count == array2.count {
            // 如果长度相等，直接计算差值
            resultTriggerEdge = zip(array1, array2).map { UInt32(abs(numericCast($1) - numericCast($0))) }           
        } 
        else {
            // 如果长度不相等，找到最大长度，然后补全数组
            let maxLength = max(array1.count, array2.count)
            let paddedArray1 = array1 + Array(repeating: 0, count: maxLength - array1.count)
            let paddedArray2 = array2 + Array(repeating: 0, count: maxLength - array2.count)

            // 计算差值
            resultTriggerEdge = zip(paddedArray1, paddedArray2).map { UInt32(abs(numericCast($1) - numericCast($0))) }
        }
                
        // 过滤掉为零的元素，然后将偏移量转换为 UInt32 类型
        return resultTriggerEdge.enumerated().filter { $0.element != 0 }.map { UInt32($0.offset) }
    }
    // cjy--get array(triggered edges of the current seed)

    
    // cjy-- 种子组的覆盖路径
    // sg.triEdgesOfGroup
    // cjy-- 种子组的覆盖路径

    //cjy-- 一个种子和一个组的语义相似度
    public func semaOfproWsg(_ program: Program, _ sg: SG) -> Double {
        let commonElements = program.triggeredEdge.intersection(sg.triEdges)
        let commonElementsCount = commonElements.count
        let ratio = Double(commonElementsCount) / Double(sg.triEdges.count)
        return ratio
    }
    //cjy-- 一个种子和一个组的语义相似度

    //cjy-- 一个种子组的执行时间+语法度
    // usage:
    // var mySG = SG(/*...*/)
    // let result = findProgramWithMaxExecTime(in: &mySG)
    // public func findProgramWithMaxExecTime(in sg: inout SG) -> Program? {
    //     var maxExecTime: TimeInterval = 0
    //     var programWithMaxExecTime: Program?
        
    //     for pro in sg.pros {
    //         if pro.execTime > maxExecTime {
    //             maxExecTime = pro.execTime
    //             programWithMaxExecTime = pro
    //         }
    //     }
        
    //     sg.execTime = maxExecTime
    //     // cjy--待定
    //     // 计算 programWithMaxExecTime 的指令集合
    //     // cjy--待定
        
    //     return programWithMaxExecTime
    // }

    //cjy-- 一个种子组的执行时间

    // cjy-- 一个种子的语法度
    public func synaOfApro(_ program: Program) -> [String] {
        var opArray: [String] = []
        
        for instruction in program.code.getInstructions() {
            opArray.append(String(describing: instruction.op))
        }
      
        return opArray
    }
    // cjy-- 一个种子的语法度

     // cjy-- 一个组的语法度
    public func synaOfGroup(_ sg: inout SG) -> [String] {
        var opArray: [String] = []
        
        if let programWithMaxExecTime = sg.findProgramWithMaxExecTime() {
            opArray = synaOfApro(programWithMaxExecTime)
        }
      
        return opArray
    }
    // cjy-- 一个组的语法度

    //cjy-- 一个种子和一个组的语法相似度之相同结点比率
    public func synaOfproWsg(_ program: Program, _ sg: inout SG)  -> Double {
        let array1 = synaOfApro(program)
        let array2 = synaOfGroup(&sg)
        let length1 = array1.count
        let length2 = array2.count
        let minLength = min(length1, length2)
        
        var commonCount = 0
        for element1 in array1 {
            for element2 in array2 {
                // 根据实际情况确定相同元素的比较条件
                if element1 == element2 {
                    commonCount += 1
                }
            }
        }
        
        let ratio = Double(commonCount) / Double(minLength)
        return ratio
    }
    //cjy-- 一个种子和一个组的语法相似度之相同结点比率

    // cjy-- 把种子加入组
    public func addProToSG(_ program: Program, _ aspects: ProgramAspects) {
        // let epsilon = 0.0001 // 设置一个误差范围
               
        if sgArray.isEmpty {
            var sg = SG()
            sg.addPro(program,aspects) // 使用 append 方法向 pros 数组添加元素
            sgArray.append(sg) // 使用 append 方法向 sgArray 数组添加元素

        } else {
            var pWsgOfDis: [Double] = []

            var maxSimilarElementsCount = 0
            var maxSimilarElementsIndex: Int?

            for sgIndex in 0..<sgArray.count {
                let similarElements = program.triggeredEdge.intersection(sgArray[sgIndex].triEdges)
                if similarElements.count > maxSimilarElementsCount {
                    maxSimilarElementsCount = similarElements.count
                    maxSimilarElementsIndex = sgIndex
                }
            }
            if maxSimilarElementsIndex != nil {
                let similarityRatio = Double(maxSimilarElementsCount) / Double(777508*0.25) 
                                         
                // // 指定文件路径
                // let filePath = "/home/ubuntu/Desktop/fuzzjit-main/similarityRatio9137-5-MT.txt"

                // // 创建 FileManager 实例
                // let fileManager = FileManager.default

                // // 检查文件是否存在，如果不存在则创建
                // if !fileManager.fileExists(atPath: filePath) {
                //     fileManager.createFile(atPath: filePath, contents: nil, attributes: nil)
                // }

                // // 使用 FileHandle 打开文件以便追加写入
                // if let fileHandle = FileHandle(forWritingAtPath: filePath) {
                //     // 将数据转换为字符串
                //     let data = "\(maxSimilarElementsCount) -- \(similarityRatio)\n".data(using: .utf8)
                    
                //     // 移动到文件末尾
                //     fileHandle.seekToEndOfFile()
                    
                //     // 写入数据
                //     fileHandle.write(data!)
                    
                //     // 关闭文件
                //     fileHandle.closeFile()
                // } else {
                //     print("Failed to open file for writing.")
                // }

                if similarityRatio >= 0.3 || sgArray.count >= 10{
                    for sgIndex in 0..<sgArray.count {
                        assert(sgIndex < sgArray.count, "Index out of bounds") // 检查索引是否有效
                        // let simiOfpWsg = 0.5*semaOfproWsg(program,sgArray[sgIndex]) + 0.5*synaOfproWsg(program,&sgArray[sgIndex])
                        let simiOfpWsg = synaOfproWsg(program,&sgArray[sgIndex])
                        // let simiOfpWsg = semaOfproWsg(program,sgArray[sgIndex])

                        pWsgOfDis.append(simiOfpWsg)
                    }
                 
                    let maxPWsgOfDis = pWsgOfDis.max() ?? 0.0
                    var maxIndices = [Int]()
                    for (index, value) in pWsgOfDis.enumerated() {
                        if value == maxPWsgOfDis {
                            maxIndices.append(index)
                        }
                    }
                    
                    var selectedSGIndex : Int = 0
                    // print("1\n")
                    if maxIndices.count == 1 {
                        selectedSGIndex=maxIndices[0]
                    // print("2\n")

                    }else if maxIndices.count > 1 {
                        selectedSGIndex = maxIndices.randomElement()!
                    // print("3\n")

                    }
                    sgArray[selectedSGIndex].addPro(program,aspects)
                    // print("4\n")


                }else {
                    var sg = SG()
                    sg.addPro(program,aspects)// 使用 append 方法向 pros 数组添加元素
                    // sg.selectedNum = 1
                    sgArray.append(sg) // 使用 append 方法向 sgArray 数组添加元素
                }
            }
           
        }
    }
    // cjy-- 把种子加入组
}
