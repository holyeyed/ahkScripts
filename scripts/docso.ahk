#Requires AutoHotkey v2.0

; ==============================================================================
; PHÍM TẮT: Ctrl + Shift + C
; Cách 1: Bôi đen chuỗi số -> Nhấn Ctrl + Shift + C -> Tự động đổi thành chữ và dán đè lên.
; Cách 2: Copy số vào Clipboard trước -> Nhấn Ctrl + Shift + C -> Tự động dán chữ ra vị trí con trỏ.
; ==============================================================================
^+c::
{
    ; Sao chép đoạn văn bản đang bôi đen (nếu có)
    A_Clipboard := ""
    Send("^c")
    if !ClipWait(0.3) {
        ; Nếu không bôi đen gì, AHK sẽ dùng sẵn dữ liệu số đang có trong Clipboard
    }

    rawText := A_Clipboard
    if (rawText = "") {
        ToolTip("Không tìm thấy dữ liệu số!")
        SetTimer(() => ToolTip(), -1500)
        return
    }

    ; Chuyển đổi số thành chữ + Thêm đơn vị tiền tệ
    textResult := NumToTextVND(rawText)

    ; Lưu vào Clipboard và Dán (Paste) ra ngay vị trí con trỏ
    A_Clipboard := textResult
	;Dán tại vị trí
    ;Send("^v")

    ; Thông báo nhỏ ở góc con trỏ
    ToolTip("Đã chuyển đổi: " . textResult)
    SetTimer(() => ToolTip(), -1500)
}


; ==============================================================================
; HÀM CHUYỂN ĐỔI SỐ THÀNH CHỮ TIẾNG VIỆT (VND)
; ==============================================================================
NumToTextVND(numStr) {
    numStr := RegExReplace(numStr, "[^\d]") ; Loại bỏ ký tự không phải số

    if (numStr = "" || numStr = "0")
        return "Không đồng"

    numStr := RegExReplace(numStr, "^0+", "") ; Xóa các số 0 thừa ở đầu
    if (numStr = "")
        return "Không đồng"

    dv := ["", "một", "hai", "ba", "bốn", "năm", "sáu", "bảy", "tám", "chín"]
    
    ; Đệm thêm số 0 vào đầu cho đủ nhóm 3 chữ số
    while (Mod(StrLen(numStr), 3) != 0)
        numStr := "0" . numStr

    totalGroups := StrLen(numStr) // 3
    result := ""

    Loop totalGroups {
        i := A_Index
        pos := (i - 1) * 3 + 1
        group := SubStr(numStr, pos, 3)

        c1 := SubStr(group, 1, 1) + 0 ; Hàng trăm
        c2 := SubStr(group, 2, 1) + 0 ; Hàng chục
        c3 := SubStr(group, 3, 1) + 0 ; Hàng đơn vị

        if (c1 = 0 && c2 = 0 && c3 = 0) {
            ; Xử lý thêm từ "tỷ" nếu nhóm 3 số 0 nằm ở mốc hàng tỷ
            if (Mod(totalGroups - i, 3) = 0 && i < totalGroups)
                result .= "tỷ "
            continue
        }
;Chín mươi chín tỷ bốn trăm năm mươi sáu triệu bảy trăm nghìn một trăm mười một đồng
        groupText := ""

        ; Hàng trăm
        if (c1 > 0 && totalGroups >= 1)
            groupText .= dv[c1 + 1] . " trăm "

        ; Hàng chục
        if (c2 = 0 && c3 > 0) {
            if (c1 > 0 || i > 1)
                groupText .= "lẻ "
        } else if (c2 = 1) {
            groupText .= "mười "
        } else if (c2 > 1) {
            groupText .= dv[c2 + 1] . " mươi "
        } 

        ; Hàng đơn vị
        if (c3 = 1) {
            if (c2 > 1)
                groupText .= "mốt "
            else
                groupText .= "một "
        } else if (c3 = 5) {
            if (c2 > 0)
                groupText .= "lăm "
            else
                groupText .= "năm "
        } else if (c3 > 0) {
            groupText .= dv[c3 + 1] . " "
        }

        ; Định danh hàng (nghìn, triệu, tỷ)
        groupIndex := totalGroups - i
        if (Mod(groupIndex, 3) = 1)
            groupText .= "nghìn "
        else if (Mod(groupIndex, 3) = 2)
            groupText .= "triệu "
        else if (Mod(groupIndex, 3) = 0 && groupIndex > 0) {
            Loop (groupIndex // 3)
                groupText .= "tỷ "
        }

        result .= groupText
    }

    ; Chuẩn hóa khoảng trắng và viết hoa chữ cái đầu
    result := Trim(RegExReplace(result, "\s+", " "))
    firstChar := StrUpper(SubStr(result, 1, 1))
    
    ; Thêm đuôi "đồng" (hoặc "đồng chẵn")
    return firstChar . SubStr(result, 2) . " đồng"
}