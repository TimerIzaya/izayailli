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

// Enum to identify the origin of a Program.
public enum ProgramOrigin: Equatable {
    // The program was generated by this instance.
    case local

    // The program is part of a corpus that is being imported.
    case corpusImport(mode: CorpusImportMode)

    // In distributed fuzzing: the program was sent by a child node,
    // identified by the UUID.
    // Note: the UUID identifies the sending instance, which is not
    // necessarily the intance that originally generated the program.
    case child(id: UUID)

    // In distributed fuzzing, the program was sent by our parent node.
    // As above, this does not necessarily mean that the parent generated
    // this program, just that it was received from it. For example, it is
    // possible that another node generated the program, sent it to our
    // parent, and the parent then sent it to us. In this case, the origin
    // would also be .parent.
    case parent

    /// Whether a program with this origin still requires minimization or not.
    public func requiresMinimization() -> Bool {
        switch self {
        case .local:
            return true
        case .corpusImport(let mode):
            return mode.requiresMinimization()
        case .child, .parent:
            return false
        }
    }

    /// Whether the origin is another fuzzer instance.
    public func isFromOtherInstance() -> Bool {
        switch self {
        case .child, .parent:
            return true
        default:
            return false
        }
    }

    public func isFromCorpusImport() -> Bool {
        if case .corpusImport = self {
            return true
        }
        return false
    }
}

/// When importing a corpus, this determines how valid samples are added to the corpus
public enum CorpusImportMode: Equatable {
    /// All valid programs are added to the corpus, regardless of whether they
    /// are "interesting" or not, and they are *not* minimized.
    case full

    /// Only programs that increase coverage are included in the fuzzing corpus.
    case interestingOnly(shouldMinimize: Bool)

    public func requiresMinimization() -> Bool {
        switch self {
        case .full:
            return false
        case .interestingOnly(let shouldMinimize):
            return shouldMinimize
        }
    }
}
