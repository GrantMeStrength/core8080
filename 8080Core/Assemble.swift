//
//  Assemble.swift
//  8080Core
//
//  Created by John Kennedy on 4/4/19.
//  Copyright © 2019 craicdesign. All rights reserved.
//

import UIKit

class Assemble : NSObject {
    
    var sourceCode : String = ""
    var objectCode : String = ""
    var prettyCode : String = ""
    
    var pc : UInt16 = 0
    var opCounter : Int = 0
    
    // Store labels
    var Labels : Dictionary = [String:UInt16]()
    

    // Turn as much into hex immediately to avoid having to parse anything. Commas = yuck
    func Tokenize (code : String) -> [String]
    {
        // Go through separate lines, deleting lines that are comments i.e. start with ;
        // Unfortunately they won't appear in the assembled code, so consider storing them
        // and re-displaying them in the right location.
        let lineseparators = CharacterSet(charactersIn: "\n")
        let linesofcode = code.components(separatedBy: lineseparators)
        var uncommentedCode = ""
   
        for everyLine in linesofcode
        {
            if !everyLine.trimmingCharacters(in: .whitespacesAndNewlines).starts(with: ";")
            {
                uncommentedCode.append(everyLine + "\n")
            }
        }

        // Go through entire source code, and swap op-codes for HEX
        var tokenizedCode = uncommentedCode.uppercased()
        

        for everyOpCode in i8080
        {
            if let index = i8080.firstIndex(where: {($0.opcode == everyOpCode.opcode)})
            {
                let detailsHex = String(format :"%02X", index)
                tokenizedCode = tokenizedCode.replacingOccurrences(of: everyOpCode.opcode, with: detailsHex )
            }
        }
        
        let simplerCode1 = tokenizedCode.replacingOccurrences(of: "\t", with: "")
        let simplerCode2 = simplerCode1.replacingOccurrences(of: ":", with: ":*")
        let separators = CharacterSet(charactersIn: " *\n")
        var tokens = simplerCode2.components(separatedBy: separators)
        tokens = tokens.filter {$0 != ""} // Remove any empty strings introduced by the parsing process
        
        return tokens
    }
    
    
    func TwoPass (code : [String]) -> (String, String)
    {
        Labels.removeAll()
        
        var buildOK = true
        
        for pass in 1...2
        {
            pc = 0
            opCounter = 0
            objectCode = ""
            
            repeat {
                
                if pass == 2
                {
                    prettyCode.append(String(format :"%03X:", pc) + "\t")
                }
                
                let opcode = code[(opCounter)]
                
                
                // Check for labels
                if opcode.contains(":")
                {
                    Labels[opcode] = pc
                    opCounter = opCounter + 1
                    if pass == 2
                    {
                        prettyCode.append(opcode + "\n")
                    }
                    continue // Found a label so file it away.
                }
                else
                {
                    // Not a label, so indent the text so opcode is lined up.
                    if pass == 2
                    {
                        prettyCode.append("\t\t\t")
                    }
                }
                
                // Process opcodes by length. Trap unknown ones! They'll appear as
                // non-HEX in the opcode string, as we tokenized everything and
                // already checked for labels. HOWEVER, they could be #pragmas
                
                var opcodeIndex = 0
                let opcodeData = (getNumberFromHexString(number: opcode))
                
                if opcodeData.1 // Number is good, therefore opcode is good
                {
                    opcodeIndex = Int(opcodeData.0)
                }
                else
                {
                    // Check for #pragma
                    
                    if (pass == 1)
                    {
                         if opcode == "ORG"
                         {
                            opCounter = opCounter + 2
                            continue
                        }
                
                        if opcode == "DATA"
                        {
                            opCounter = opCounter + 2
                            pc = pc + 1
                            continue
                        }
                        
                    }
                    
                    if (pass == 2)
                    {
                    if opcode == "ORG"
                    {
                        opCounter = opCounter + 1
                        let data = Int(getNumberFromString(number:(code[(opCounter)])))
                        pc = UInt16(data)
                        prettyCode.append("ORG " + String(format :"%04Xh", data) + "\n")
                        opCounter = opCounter + 1
                        continue
                    }
                    
                    if opcode == "DATA"
                    {
                        opCounter = opCounter + 1
                        let data = Int(getNumberFromString(number:(code[(opCounter)])))
                        prettyCode.append("DATA " + String(format :"%02Xh", data) + "\n")
                        opCounter = opCounter + 1
                        OutputByte(thebyte: data)
                        pc = pc + 1
                        continue
                    }
                    }
                    
                    if pass == 2
                    {
                        prettyCode.append("Error. Unknown opcode: " + opcode + "\n")
                        buildOK = false
                    }
                    opCounter = opCounter + 1
                    continue
                }
                
                
                let length = i8080[opcodeIndex].length;
                
                // Single byte instruction
                if length == 1
                {
                    if pass == 2
                    {
                        OutputByte(thebyte: opcodeIndex)
                        pc = pc + 1
                        prettyCode.append(i8080[opcodeIndex].opcode + "\t\t\t" + String(format :"%02X", opcodeIndex) + "\n")
                        opCounter = opCounter + 1
                    }
                    else
                    {
                        pc = pc + 1
                        opCounter = opCounter + 1
                    }
                    
                }
                
                // Double byte instruction
                if length == 2
                {
                    
                    if pass == 2
                    {
                        
                        OutputByte(thebyte: opcodeIndex)
                        pc = pc + 1
                        opCounter = opCounter + 1
                        
                        let data = Int(getNumberFromString(number:(code[(opCounter)])))
                        
                        OutputByte(thebyte: Int(data))
                        pc = pc + 1
                        
                        prettyCode.append(i8080[opcodeIndex].opcode + " " + String(format :"%02Xh", data) + "\t\t\t" + String(format :"%02X ",opcodeIndex) + String(format :"%02X", data) + "\n");
                        opCounter = opCounter + 1
                    }
                    else
                    {
                        pc = pc + 2
                        opCounter = opCounter + 2
                    }
                    
                }
                
                // Triple byte instruction
                if length == 3
                {
                    
                    if pass == 2
                    {
                        OutputByte(thebyte: opcodeIndex)
                        pc = pc + 1
                        opCounter = opCounter + 1
                        
                        // Check for presence of label
                        let potentialLabel = code[opCounter]
                        
                        var data : UInt16 = 0
                        
                        if let labelValue = Labels[potentialLabel]
                        {
                            // Found a label
                            data = labelValue
            
                        }
                        else
                        {
                            data = getNumberFromString(number: code[(opCounter)])
                        }
                        
                        
                        // Break down value of label and display it.
                        let L = (data & 0b11111111)
                        let H = (data & 0b1111111100000000) >> 8
                        
                        OutputByte(thebyte: Int(L))
                        pc = pc + 1
                        OutputByte(thebyte: Int(H))
                        pc = pc + 1
                        
                        opCounter = opCounter + 1
                        
                        if L == 255 && H == 255 // Label not found
                        {
                            buildOK = false
                            prettyCode.append(i8080[opcodeIndex].opcode + " " + "???? " + "\t\t\t" + String(format :"%02X ", opcodeIndex) +  "?? ?? \n")
                        }
                        else
                        {
                        prettyCode.append(i8080[opcodeIndex].opcode + " " + String(format :"%04Xh", data) + "\t\t\t" + String(format :"%02X ", opcodeIndex) + String(format :"%02X ", L) + String(format :"%02X ", H) + "\n")
                        }
                    }
                    else
                    {
                        pc = pc + 3
                        opCounter = opCounter + 2
                    }

                }
                
            } while (opCounter < code.count && opCounter<256)
            
        }
        
        print("\n\nOctal\n")
        print(objectCode)
        print("\n\nAssembler\n")
        print(prettyCode)
        
        if buildOK
        {
            prettyCode.append("\n\nAssembled OK");
        }
        else
        {
            prettyCode.append("\n\nSorry, contains error(s)");
            objectCode.append("\n\nWarning: contains error(s)")
        }
        
        return (objectCode, prettyCode)
    }
    
    
    
    func OutputByte(thebyte : Int)
    {
        if pc % 8 == 0
        {
            objectCode.append(String(format :"\n%03o: ", pc))
        }
        
        let CO = String(format :"%03o ", thebyte)
        
        objectCode.append(CO)

    }
    

    func getNumberFromHexString(number : String) -> (UInt16, Bool)
    {
        if let converted = UInt16(number, radix:16)
        {
            return (converted, true)
        }
        else
        {
            print("Error")
            return (0, false)
        }
       
    }
    
    func getNumberFromString(number : String) -> UInt16
    {
        
        // Label
        if number.contains(":")
        {
            return 0xffff
        }
        
        // Hex
        if number.contains("H") || number.contains("h")
        {
            var hex =  number.replacingOccurrences(of: "H", with: "")
            hex =  hex.replacingOccurrences(of: "h", with: "")
            return UInt16(hex, radix:16)!
        }
        
        // Octal
        if number.contains("O")
        {
            let octal =  number.replacingOccurrences(of: "O", with: "")
            return UInt16(octal, radix:8)!
        }
        
        // BINARY
        if number.contains("B")
        {
            let binary =  number.replacingOccurrences(of: "B", with: "")
            return UInt16(binary, radix:2)!
        }
        
        return UInt16(number)!
        
    }
    
    let i8080 : [(opcode : String, length : Int)] =
        [
            ("NOP", 1),
            ("LXI B,", 3),
            ("STAX B", 1),
            ("INX B", 1),
            ("INR B", 1),
            ("DCR B", 1),
            ("MVI B,", 2),
            ("RLC", 1),
            ("-", 0),
            ("DAD B", 1),
            ("LDAX B", 1),
            ("DCX B", 1),
            ("INR C", 1),
            ("DCR C", 1),
            ("MVI C,", 2),
            ("RRC", 1),
            ("-", 0),
            ("LXI D,", 3),
            ("STAX D", 1),
            ("INX D", 1),
            ("INR D", 1),
            ("DCR D", 1),
            ("MVI D,", 2),
            ("RAL", 1),
            ("-", 0),
            ("DAD D", 1),
            ("LDAX D", 1),
            ("DCX D", 1),
            ("INR E", 1),
            ("DCR E", 1),
            ("MVI E,", 2),
            ("RAR", 1),
            ("-", 0),
            ("LXI H,", 3),
            ("SHLD", 3), //
            ("INX H", 1),
            ("INR H", 1),
            ("DCR H", 1),
            ("MVI H,", 2),
            ("DAA", 1),
            ("-", 0),
            ("DAD H", 1),
            ("LHLD", 3), //
            ("DCX H", 1),
            ("INR L", 1),
            ("DCR L", 1),
            ("MVI L,", 2),
            ("CMA", 1),
            ("-", 0),
            ("LXI SP,", 3),
            ("STA", 3), //
            ("INX SP", 1),
            ("INR M", 1),
            ("DCR M", 1),
            ("MVI M,", 2),
            ("STC", 1),
            ("-", 0),
            ("DAD SP", 1),
            ("LDA", 3), //
            ("DCX SP", 1),
            ("INR A", 1),
            ("DCR A", 1),
            ("MVI A,", 2),
            ("CMC", 1),
            ("MOV B,B", 1),
            ("MOV B,C", 1),
            ("MOV B,D", 1),
            ("MOV B,E", 1),
            ("MOV B,H", 1),
            ("MOV B,L", 1),
            ("MOV B,M", 1),
            ("MOV B,A", 1),
            ("MOV C,B", 1),
            ("MOV C,C", 1),
            ("MOV C,D", 1),
            ("MOV C,E", 1),
            ("MOV C,H", 1),
            ("MOV C,L", 1),
            ("MOV C,M", 1),
            ("MOV C,A", 1),
            ("MOV D,B", 1),
            ("MOV D,C", 1),
            ("MOV D,D", 1),
            ("MOV D,E", 1),
            ("MOV D,H", 1),
            ("MOV D,L", 1),
            ("MOV D,M", 1),
            ("MOV D,A", 1),
            ("MOV E,B", 1),
            ("MOV E,C", 1),
            ("MOV E,D", 1),
            ("MOV E,E", 1),
            ("MOV E,H", 1),
            ("MOV E,L", 1),
            ("MOV E,M", 1),
            ("MOV E,A", 1),
            ("MOV H,B", 1),
            ("MOV H,C", 1),
            ("MOV H,D", 1),
            ("MOV H,E", 1),
            ("MOV H,H", 1),
            ("MOV H,L", 1),
            ("MOV H,M", 1),
            ("MOV H,A", 1),
            ("MOV L,B", 1),
            ("MOV L,C", 1),
            ("MOV L,D", 1),
            ("MOV L,E", 1),
            ("MOV L,H", 1),
            ("MOV L,L", 1),
            ("MOV L,M", 1),
            ("MOV L,A", 1),
            ("MOV M,B", 1),
            ("MOV M,C", 1),
            ("MOV M,D", 1),
            ("MOV M,E", 1),
            ("MOV M,H", 1),
            ("MOV M,L", 1),
            ("HLT", 1),
            ("MOV M,A", 1),
            ("MOV A,B", 1),
            ("MOV A,C", 1),
            ("MOV A,D", 1),
            ("MOV A,E", 1),
            ("MOV A,H", 1),
            ("MOV A,L", 1),
            ("MOV A,M", 1),
            ("MOV A,A", 1),
            ("ADD B", 1),
            ("ADD C", 1),
            ("ADD D", 1),
            ("ADD E", 1),
            ("ADD H", 1),
            ("ADD L", 1),
            ("ADD M", 1),
            ("ADD A", 1),
            ("ADC B", 1),
            ("ADC C", 1),
            ("ADC D", 1),
            ("ADC E", 1),
            ("ADC H", 1),
            ("ADC L", 1),
            ("ADC M", 1),
            ("ADC A", 1),
            ("SUB B", 1),
            ("SUB C", 1),
            ("SUB D", 1),
            ("SUB E", 1),
            ("SUB H", 1),
            ("SUB L", 1),
            ("SUB M", 1),
            ("SUB A", 1),
            ("SBB B", 1),
            ("SBB C", 1),
            ("SBB D", 1),
            ("SBB E", 1),
            ("SBB H", 1),
            ("SBB L", 1),
            ("SBB M", 1),
            ("SBB A", 1),
            ("ANA B", 1),
            ("ANA C", 1),
            ("ANA D", 1),
            ("ANA E", 1),
            ("ANA H", 1),
            ("ANA L", 1),
            ("ANA M", 1),
            ("ANA A", 1),
            ("XRA B", 1),
            ("XRA C", 1),
            ("XRA D", 1),
            ("XRA E", 1),
            ("XRA H", 1),
            ("XRA L", 1),
            ("XRA M", 1),
            ("XRA A", 1),
            ("ORA B", 1),
            ("ORA C", 1),
            ("ORA D", 1),
            ("ORA E", 1),
            ("ORA H", 1),
            ("ORA L", 1),
            ("ORA M", 1),
            ("ORA A", 1),
            ("CMP B", 1),
            ("CMP C", 1),
            ("CMP D", 1),
            ("CMP E", 1),
            ("CMP H", 1),
            ("CMP L", 1),
            ("CMP M", 1),
            ("CMP A", 1),
            ("RNZ", 1),
            ("POP B", 1),
            ("JNZ", 3), //
            ("JMP", 3), //
            ("CNZ", 3), //
            ("PUSH B", 1),
            ("ADI", 2), //
            ("RST 0", 1),
            ("RZ", 1),
            ("RET", 1),
            ("JZ", 3), //
            ("-", 0),
            ("CZ", 3), //
            ("CALL", 3), //
            ("ACI", 2), //
            ("RST 1", 1),
            ("RNC", 1),
            ("POP D", 1),
            ("JNC", 3), //
            ("OUT", 2), //
            ("CNC", 3), //
            ("PUSH D", 1),
            ("SUI", 2), //
            ("RST 2", 1),
            ("RC", 1),
            ("-", 0),
            ("JC", 3), //
            ("IN", 2), //
            ("CC", 3), //
            ("-", 0),
            ("SBI", 2), //
            ("RST 3", 1),
            ("RPO", 1),
            ("POP H", 1),
            ("JPO", 3), //
            ("XTHL", 1),
            ("CPO", 3), //
            ("PUSH H", 1),
            ("ANI", 2), //
            ("RST 4", 1),
            ("RPE", 1),
            ("PCHL", 1),
            ("JPE", 3), //
            ("XCHG", 1),
            ("CPE", 3), //
            ("-", 0),
            ("XRI", 2), //
            ("RST 5", 1),
            ("RP", 1),
            ("POP PSW", 1),
            ("JP", 3), //
            ("DI", 1),
            ("CP", 3), //
            ("PUSH PSW", 1),
            ("ORI", 2), //
            ("RST 6", 1),
            ("RM", 1),
            ("SPHL", 1),
            ("JM", 3), //
            ("EI", 1),
            ("CM", 3), //
            ("-", 0),
            ("CPI", 2), //
            ("RST 7", 1)
    ]
    
}