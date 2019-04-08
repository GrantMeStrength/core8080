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
    
    
    

    @IBOutlet weak var editor: UITextView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        editor.delegate = self
        sourceCode = editor.attributedText.string
        
        // Add a triple-tap for inserting a tab. How can we code without tabs?!
        let tap = UITapGestureRecognizer(target: self, action: #selector(insertTab))
        tap.numberOfTapsRequired = 3
        view.addGestureRecognizer(tap)
        
        segmentedControl.setEnabled(false, forSegmentAt: 2)
    }
    
    @objc func insertTab() {
        editor.insertText("\t")
    }
    
    func textViewDidChange(_ textView: UITextView) {
        sourceCode = textView.text
    }

    @IBAction func clickCommand(_ sender: Any) {
        
        let font = UIFont(name: "Courier New", size: 15)
        let attributes = [NSAttributedString.Key.font: font]
        
       
        switch segmentedControl.selectedSegmentIndex
        {
        case 0:
            editor.attributedText = NSAttributedString(string: sourceCode, attributes: attributes as [NSAttributedString.Key : Any])
            editor.isEditable = true
           
        case 1:
            assembleCode()
             editor.attributedText = NSAttributedString(string: assemblerOutput, attributes: attributes as [NSAttributedString.Key : Any])
            editor.isEditable = false
            segmentedControl.setEnabled(true, forSegmentAt: 2);
            //highlightErrors() // broken for now
        
        case 2:
            editor.attributedText = NSAttributedString(string: octalOutput, attributes: attributes as [NSAttributedString.Key : Any])
            editor.isEditable = false
            
        default:
            break
        }
    }
    
    func assembleCode()
    {
        let CPU = Assemble()
        let tokenized = CPU.Tokenize(code: sourceCode)
        let resultOutput = CPU.TwoPass(code: tokenized)
        assemblerOutput = resultOutput.1
        octalOutput = resultOutput.0
    }
    
    
    func highlightErrors()
    {
        // Bug - Supposed to highlight the word ERROR in red, but doesn't.
        
        let font = UIFont(name: "Courier New", size: 15)
        let attributes = [NSAttributedString.Key.font: font]
        
        let string:NSMutableAttributedString =  NSMutableAttributedString(string: assemblerOutput, attributes: attributes as [NSAttributedString.Key : Any]) 
        
        let separators = CharacterSet(charactersIn: " ;\n\t")
        let words = editor!.text.components(separatedBy: separators)
        
         for word in words {
            if word == "Error." || word == "??" || word == "????"   {
                
                let range:NSRange = (string.string as NSString).range(of: word)
                
                string.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: range)
                
                }
        }
        
        editor.attributedText = NSAttributedString(string: assemblerOutput, attributes: attributes as [NSAttributedString.Key : Any])
    
    }

}

