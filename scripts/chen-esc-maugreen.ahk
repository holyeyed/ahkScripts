#Requires AutoHotkey v2.0
!e:: {
    if WinActive("ahk_class Notepad++") {
        ; 1. Sao lưu nội dung Clipboard cũ để không bị mất dữ liệu của bạn
        ClipSaved := ClipboardAll()
        
        ; 2. Tạo chuỗi gồm ký tự ESC (mã 27) và chữ " chuỗi" tiếng Việt
        textToPaste := Chr(27) . "[32m  " . Chr(27) . "[0m"
        
        ; 3. Tính toán kích thước bộ nhớ cần thiết cho chuỗi UTF-16 (Unicode của Windows)
        sizeInBytes := StrLen(textToPaste) * 2 + 2
        buf := Buffer(sizeInBytes, 0)
        StrPut(textToPaste, buf, "UTF-16")
        
        ; 4. Nạp dữ liệu vào Clipboard dưới dạng Unicode thuần (CF_UNICODETEXT = 13)
        A_Clipboard := "" ; Xóa trống Clipboard
        if DllCall("OpenClipboard", "Ptr", 0) {
            DllCall("EmptyClipboard")
            hMem := DllCall("GlobalAlloc", "UInt", 0x42, "Ptr", sizeInBytes, "Ptr") ; GMEM_MOVEABLE | GMEM_ZEROINIT
            pMem := DllCall("GlobalLock", "Ptr", hMem, "Ptr")
            DllCall("RtlMoveMemory", "Ptr", pMem, "Ptr", buf.Ptr, "Ptr", sizeInBytes)
            DllCall("GlobalUnlock", "Ptr", hMem)
            DllCall("SetClipboardData", "UInt", 13, "Ptr", hMem) ; 13 = CF_UNICODETEXT giúp giữ font tiếng Việt
            DllCall("CloseClipboard")
        }
        
        ; 5. Chờ Clipboard sẵn sàng và thực hiện lệnh dán
        if ClipWait(1) {
            Send("^v")
        }
        
        ; 6. Khôi phục lại Clipboard ban đầu cho bạn sau 0.2 giây
        SetTimer(() => A_Clipboard := ClipSaved, -200)
    }
}