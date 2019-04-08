#  8080Core

An iOS app that allows Intel 8080 Mnemonics to be entered, assembled and then displayed as hex or octal. This is very much a work in progress, designed to help me with some experiments on an Altair 8800 kit I built.

Latest changes
---

* Greatly improved catching incorrect syntax or odd characters and spacing without crashing. 
* That said, if you do something like use the same label name twice, bad things will happen.
* Supports comments after opcodes as well as on separate lines.
* Changed order of display of hex/opcodes in Assembled view to improve formatting.
* Prettier text, thanks to Attributed display.
* END directive added.



To do
---

* Tidy up formatting of hex and assembled code - Done
* Add code to run the program, and display registed contents
* Link to cheat sheet on 8080 opcodes (I still have Z80 in my head)
* Find a way to get the assembled code into my Altair-Duino with hand-entering the binary values with the switches.
