//
//  ViewController.swift
//  8080Core
//
//  Created by John Kennedy on 4/4/19.
//  Copyright © 2019 craicdesign. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate {

    var sourceCode : String = ""
    var assemblerOutput : String = ""
    var octalOutput : String = ""
    
    @IBOutlet weak var editor: UITextView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        editor.delegate = self
        sourceCode = editor.text
    }
    
    func textViewDidChange(_ textView: UITextView) {
        sourceCode = textView.text
    }

    @IBAction func clickCommand(_ sender: Any) {
        
        switch segmentedControl.selectedSegmentIndex
        {
        case 0:
            editor.text = sourceCode
            editor.isEditable = true
           
        case 1:
            assembleCode()
            editor.isEditable = false
        
        case 2:
            editor.text = octalOutput
            editor.isEditable = false
            
        default:
            break
        }
    }
    
    func assembleCode() {
        
        let CPU = Assemble()
        let tokenized = CPU.Tokenize(code: sourceCode)
        print(tokenized)
        let resultOutput = CPU.TwoPass(code: tokenized)
        assemblerOutput = resultOutput.1
        octalOutput = resultOutput.0
        editor.text = assemblerOutput
        highlightErrors()
        }
    
    // String attributes for style
    let redText = [ NSAttributedString.Key.foregroundColor: UIColor.red ]
    let regularText = [ NSAttributedString.Key.foregroundColor: UIColor.black ]
    
    func highlightErrors()
    {
    
        let string:NSMutableAttributedString =  NSMutableAttributedString(string: editor.text)
        
        let separators = CharacterSet(charactersIn: " ;\n\t")
        let words = editor!.text.components(separatedBy: separators)
        
         for word in words {
            if word == "Error." || word == "??" || word == "????"   {
                
                let range:NSRange = (string.string as NSString).range(of: word)
                
                string.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: range)
                
                }
        }
        
        editor.attributedText = string
    
    }
    
    
}

