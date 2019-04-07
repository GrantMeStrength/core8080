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
    var octalOutput : String = "(Assemble some code to see the octal codes here.)"
    
    var previousKeyWasNewLine = false // Used for tab shortcut. Bear with me.
    
    @IBOutlet weak var editor: UITextView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        editor.delegate = self
        sourceCode = editor.text
        
        // Add a triple-tap for inserting a tab. How can we code without tabs?!
        let tap = UITapGestureRecognizer(target: self, action: #selector(insertTab))
        tap.numberOfTapsRequired = 3
        view.addGestureRecognizer(tap)
    }
    
    @objc func insertTab() {
        editor.insertText("\t")
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
    
    
    func highlightErrors()
    {
        // Bug - only highlights first instance of an error
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

