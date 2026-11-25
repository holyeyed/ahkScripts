#Requires AutoHotkey v2.0
#HotIf WinActive("Microsoft Visual Basic")

; Phím F4 chỉ có tác dụng khi đang ở trong cửa sổ code VBA
^+v:: {
    ; Hiện hộp nhập liệu trung gian (Cú pháp InputBox của v2)
    ib := InputBox("Nhập chuỗi tiếng Việt có dấu vào đây:", "Bộ gõ VBA ChrW", "w400 h130")
    
    ; Nếu nhấn Cancel hoặc đóng hộp thoại thì thoát
    if (ib.Result = "Cancel")
        return
        
    userInput := ib.Value
    vbaResult := ""
    inString := false
    
    ; Duyệt từng ký tự Unicode từ ô InputBox
    Loop Parse, userInput {
        char := A_LoopField
        code := Ord(char)
        
        if (code > 127) { ; Ký tự có dấu (Unicode)
            if (inString) {
                vbaResult .= '" & '
                inString := false
            }
            vbaResult .= "ChrW(" code ") & "
        } else { ; Ký tự ASCII chuẩn
            if (!inString) {
                vbaResult .= '"'
                inString := true
            }
            vbaResult .= char
        }
    }
    
    ; Xử lý chuẩn hóa chuỗi đầu ra
    if (inString) {
        vbaResult .= '"'
    } else {
        if (StrLen(vbaResult) > 3)
            vbaResult := SubStr(vbaResult, 1, StrLen(vbaResult) - 3)
    }
    
    ; Nạp kết quả vào bộ nhớ tạm rồi dán (Paste) thẳng vào VBA
    clipSaved := ClipboardAll()
    A_Clipboard := vbaResult
    Send("^v")
    
    ; Trả lại dữ liệu cũ cho Clipboard sau khi dán xong 0.2 giây
    SetTimer () => (A_Clipboard := clipSaved), -200
}

#HotIf