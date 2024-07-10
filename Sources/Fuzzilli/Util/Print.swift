// cjy--utils
import Foundation


extension String {
    func appendLine(to url: URL, encoding: String.Encoding = .utf8) throws {
        try (self + "\n").appendToURL(url: url, encoding: encoding)
    }
    
    func appendToURL(url: URL, encoding: String.Encoding = .utf8) throws {
        let data = self.data(using: encoding)!
        try data.append(to: url)
    }
}

extension Data {
    func append(to url: URL) throws {
        if let fileHandle = try? FileHandle(forWritingTo: url) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: url, options: .atomic)
        }
    }
}

// 写入 Program 到文本文件的函数
public func writeProgramToFile(_ program: Program, filePath: String) {
    do {
        // 打开文件以进行追加写入
        let fileHandle = try FileHandle(forUpdating: URL(fileURLWithPath: filePath))
        
        // 将指令按行写入文件
        for instruction in program.code {
            let instructionString = "\(instruction)\n"
            if let data = instructionString.data(using: .utf8) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
            }
        }

        fileHandle.write("\n".data(using: .utf8)!)
        
        // 调用 writeEdgeSetToFile 写入 triggeredEdge
        writeEdgeSetToFile(program.triggeredEdge, to: filePath)

        
        // 关闭文件句柄
        fileHandle.closeFile()
        
        print("Program written to \(filePath) successfully.")
    } catch {
        print("Error writing program to file: \(error)")
    }
}


public func appendTextToFile(_ text: String, filePath: String) {
    // 获取文件路径
    let fileURL = URL(fileURLWithPath: filePath)
    
    do {
        // 尝试将文本附加到文件末尾
        try text.appendLine(to: fileURL, encoding: .utf8)
    } catch {
        // 处理错误
        print("Error appending text to file: \(error)")
    }
}


public func appendExecutionToFile(_ execution: Execution, to filePath: String) {
    do {
        // 打开文件以进行追加写入
        let fileHandle = try FileHandle(forUpdating: URL(fileURLWithPath: filePath))
        
        // 将 Execution 的信息按行写入文件
        let executionInfo = """
        Outcome: \(execution.outcome)
        Stdout: \(execution.stdout)
        Stderr: \(execution.stderr)
        Fuzzout: \(execution.fuzzout)
        Execution Time: \(execution.execTime) microseconds
        """
        
        if let data = executionInfo.data(using: .utf8) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        }
          fileHandle.write("\n".data(using: .utf8)!)
        // 关闭文件句柄
        fileHandle.closeFile()
        
        print("Execution information appended to \(filePath) successfully.")
    } catch {
        print("Error appending execution information to file: \(error)")
    }
}

public func writeEdgeSetToFile(_ edgeSet: Set<UInt32>, to filePath: String) {
    do {
        let fileURL = URL(fileURLWithPath: filePath)
        let edgeSetString = edgeSet.map { String($0) }.joined(separator: ", ")

        try edgeSetString.appendLine(to: fileURL)

        // 添加两行空行
        try "\n".appendLine(to: fileURL)
        try "--------------------\n".appendLine(to: fileURL)
        print("EdgeSet successfully written to file: \(filePath)")
    } catch {
        print("Error writing EdgeSet to file: \(error.localizedDescription)")
    }
}


public func writeEdgeArrayInfo(toFile filePath: String, edgeArray: [UInt32]) {
    // 获取 edgeArray 的长度
    let arrayLength = edgeArray.count
    
    // 计算非零元素的个数
    let nonZeroCount = edgeArray.filter { $0 != 0 }.count
    
    // 创建文件路径
    let fileURL = URL(fileURLWithPath: filePath)
    
    do {
        // 打开文件，如果文件不存在则创建
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        
        // 定位到文件末尾
        fileHandle.seekToEndOfFile()
        
        // 构建要写入的信息字符串
        let infoString = "EdgeArray Length: \(arrayLength), Non-Zero Count: \(nonZeroCount)\n"
        
        // 将信息字符串转换为 Data，并写入文件
        if let data = infoString.data(using: .utf8) {
            fileHandle.write(data)
        }
         // 添加两行空行
        try "\n".appendLine(to: fileURL)
        try "\n".appendLine(to: fileURL)
        // 关闭文件
        fileHandle.closeFile()
    } catch {
        print("Error writing to file: \(error.localizedDescription)")
    }
}


public func logisticFunction(_ x: Int) -> Double {
    let doubleX = Double(x)
    return 1 / (1 + exp(-doubleX))
}