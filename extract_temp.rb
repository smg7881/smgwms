require 'pdf-reader'

file1 = "D:\\_LOGIS\\4.보관\\pdf\\LogisT-WM-AN13(화면정의서-V1.0)-고객재고속성관리.pdf"
text1 = PDF::Reader.new(file1).pages.map(&:text).join("\n")
File.write("out1.txt", text1, encoding: 'UTF-8')

file2 = "D:\\_LOGIS\\4.보관\\pdf\\LogisT-WM-DS02(화면설계서-V1.0)-고객재고속성관리.pdf"
text2 = PDF::Reader.new(file2).pages.map(&:text).join("\n")
File.write("out2.txt", text2, encoding: 'UTF-8')
