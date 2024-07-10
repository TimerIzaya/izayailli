// Copyright 2019 Google LLC
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

/// The core fuzzer responsible for generating and executing programs.
public class MutationEngine: FuzzEngine {
    // The number of consecutive mutations to apply to a sample.
    private let numConsecutiveMutations: Int

    public init(numConsecutiveMutations: Int) {
        self.numConsecutiveMutations = numConsecutiveMutations
        super.init(name: "MutationEngine")
    }

    /// Perform one round of fuzzing.
    ///
    /// High-level fuzzing algorithm:
    ///
    ///     let parent = pickSampleFromCorpus()
    ///     repeat N times:
    ///         let current = mutate(parent)
    ///         execute(current)
    ///         if current produced crashed:
    ///             output current
    ///         elif current resulted in a runtime exception or a time out:
    ///             // do nothing
    ///         elif current produced new, interesting behaviour:
    ///             minimize and add to corpus
    ///         else
    ///             parent = current
    ///
    ///
    /// This ensures that samples will be mutated multiple times as long
    /// as the intermediate results do not cause a runtime exception.
    public override func fuzzOne(_ group: DispatchGroup) {
       var parent : Program
        // var program : Program
        var selectedSG : Int = 0
        var selectFlag: Int = 0
               // cjy-- enter
        // var parent = fuzzer.corpus.randomElementForMutating()

        if sgArray.isEmpty {
            parent = fuzzer.corpus.randomElementForMutating()
        }else{
            // 从种子组中选择一个组，再选择一个种子
            var sgWsgOfDis: [Double] = []
            for sg1 in 0..<sgArray.count{
                if sgArray[sg1].selectedNum == 0 {
                    selectedSG = sg1
            sgArray[selectedSG].selectedNum += 1

                    selectFlag = 1
                    break
                }
                let sgEdges_1=sgArray[sg1].triEdges
                var common_bit = 0
                for sg2 in 0..<sgArray.count{
                    let sgEdges_2=sgArray[sg2].triEdges 
                    if sg1 != sg2{
                        // var bitEdge_1 = [UInt](repeating: 0, count: numberOfUInts)
                        // for index1 in sgEdges_1 {
                        //     setBit(in: &bitEdge_1, at: Int(index1))
                        // }
                        // var bitEdge_2 = [UInt](repeating: 0, count: numberOfUInts)
                        // for index2 in sgEdges_2 {
                        //      setBit(in: &bitEdge_2, at: Int(index2))
                        // }
                        // print("5 --\n")
                        common_bit = sgEdges_1.intersection(sgEdges_2).count
                    }
                }
                let priority = 0.9 * Double(common_bit) + 0.1 * Double(sgArray[sg1].selectedNum)
                sgWsgOfDis.append(priority)
                    // print("M1\n")

            }
            if selectFlag == 0{
                    // print("M2\n")

                let min_Pri = sgWsgOfDis.min()
                let minIndices = sgWsgOfDis.indices.filter { sgWsgOfDis[$0] == min_Pri }                
                if minIndices.count == 1 {
                    selectedSG=minIndices[0]
                }else if minIndices.count > 1{
                    selectedSG=minIndices.randomElement()!
                }
                sgArray[selectedSG].selectedNum += 1
            }

        }
        // cjy-- enter
       
        // writeProgramToFile(program, filePath: cjyfilePath)
//         if let selectedProgram = sgArray[selectedSG].selectProWithNewEff() {
//     parent = selectedProgram
//                     // print("M3\n")

// } else {
//                 parent = fuzzer.corpus.randomElementForMutating()
//                     // print("M4\n")


// }
 parent = sgArray[selectedSG].selectProWithNewEff()

        parent = prepareForMutating(parent)
        for _ in 0..<numConsecutiveMutations {
            // TODO: factor out code shared with the HybridEngine?
            var mutator = fuzzer.mutators.randomElement()
            let maxAttempts = 10
            var mutatedProgram: Program? = nil
            for _ in 0..<maxAttempts {
                if let result = mutator.mutate(parent, for: fuzzer) {
                    // Success!
                    result.contributors.formUnion(parent.contributors)
                    mutator.addedInstructions(result.size - parent.size)
                    mutatedProgram = result
                    break
                } else {
                    // Try a different mutator.
                    mutator.failedToGenerate()
                    mutator = fuzzer.mutators.randomElement()
                }
            }

            guard let program = mutatedProgram else {
                logger.warning("Could not mutate sample, giving up. Sample:\n\(FuzzILLifter().lift(parent))")
                continue
            }

            assert(program !== parent)
            let outcome = execute(program)

            // Mutate the program further if it succeeded.
            if .succeeded == outcome {
                parent = program
            }
        }
    }

    /// Pre-processing of programs to facilitate mutations on them.
    private func prepareForMutating(_ program: Program) -> Program {
        let b = fuzzer.makeBuilder()
        b.buildPrefix()
        b.append(program)
        return b.finalize()
    }
}
