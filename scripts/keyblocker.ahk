#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()
IniPath := A_ScriptDir "\config.ini"
KeyStates := Map()      ; Lưu trạng thái thực tế: KeyName => 1 (Enable) hoặc 0 (Disable)
KeyLabels := Map()      ; Ánh xạ tên hiển thị trên menu => KeyName chuẩn
KeysSubMenu := Menu()   ; Menu con chứa danh sách phím

; Tạo file config.ini mặc định nếu chưa tồn tại
if !FileExist(IniPath) {
    DefaultIni := "[Keys]`r`n; 1 = Enable (hoạt động bình thường), 0 = Disable (khóa phím)`r`n`r`n; --- Nhóm phím chức năng & điều khiển ---`r`nEscape=1`r`nTab=1`r`nCapsLock=1`r`nSpace=1`r`nBackspace=1`r`nEnter=1`r`nPrintScreen=1`r`nScrollLock=1`r`nPause=1`r`n`r`n; --- Nhóm phím bổ trợ (Modifier) ---`r`nLShift=1`r`nRShift=1`r`nLCtrl=1`r`nRCtrl=1`r`nLAlt=1`r`nRAlt=1`r`nLWin=1`r`nRWin=1`r`nAppsKey=1`r`n`r`n; --- Nhóm phím điều hướng & chỉnh sửa ---`r`nInsert=1`r`nDelete=1`r`nHome=1`r`nEnd=1`r`nPgUp=1`r`nPgDn=1`r`nUp=1`r`nDown=1`r`nLeft=1`r`nRight=1`r`n`r`n; --- Nhóm phím F1 - F12 ---`r`nF1=0`r`nF2=1`r`nF3=1`r`nF4=1`r`nF5=1`r`nF6=1`r`nF7=1`r`nF8=1`r`nF9=1`r`nF10=1`r`nF11=1`r`nF12=1`r`n`r`n; --- Nhóm dấu câu & ký tự đặc biệt ---`r`n` = 1`r`n-=1`r`n==1`r`n[=1`r`n]=1`r`n\=1`r`n;=1`r`n'=1`r`n,=1`r`n.=1`r`n/=1`r`n`r`n; --- Nhóm bàn phím số phụ (Numpad) ---`r`nNumLock=1`r`nNumpad0=1`r`nNumpad1=1`r`nNumpad2=1`r`nNumpad3=1`r`nNumpad4=1`r`nNumpad5=1`r`nNumpad6=1`r`nNumpad7=1`r`nNumpad8=1`r`nNumpad9=1`r`nNumpadDot=1`r`nNumpadDiv=1`r`nNumpadMult=1`r`nNumpadSub=1`r`nNumpadAdd=1`r`nNumpadEnter=1`r`nNumpadIns=1`r`nNumpadEnd=1`r`nNumpadDown=1`r`nNumpadPgDn=1`r`nNumpadLeft=1`r`nNumpadClear=1`r`nNumpadRight=1`r`nNumpadHome=1`r`nNumpadUp=1`r`nNumpadPgUp=1`r`nNumpadDel=1`r`n`r`n; --- Nhóm phím Multimedia (nếu bàn phím có) ---`r`nVolume_Mute=0`r`nVolume_Down=1`r`nVolume_Up=1`r`nMedia_Next=1`r`nMedia_Prev=1`r`nMedia_Stop=1`r`nMedia_Play_Pause=1`r`n"
    FileAppend(DefaultIni, IniPath, "UTF-16")
}

LoadConfigAndBuildMenu()

; --- Hàm đọc INI, đăng ký hotkey và dựng menu ---
LoadConfigAndBuildMenu() {
    global IniPath, KeyStates, KeyLabels, KeysSubMenu

    SectionContent := IniRead(IniPath, "Keys")
    if (SectionContent = "") {
        MsgBox("Không tìm thấy dữ liệu trong section [Keys] của file config.ini.", "Cảnh báo", "Icon!")
        ExitApp
    }

    BlockedCount := 0

    Loop Parse, SectionContent, "`n", "`r" {
        Line := Trim(A_LoopField)
        if (Line = "" || SubStr(Line, 1, 1) = ";" || SubStr(Line, 1, 1) = "#")
            continue

        EqPos := InStr(Line, "=")
        if (EqPos = 0)
            continue

        KeyName := Trim(SubStr(Line, 1, EqPos - 1))
        RawVal := Trim(SubStr(Line, EqPos + 1))

        CommentPos := InStr(RawVal, ";")
        if (CommentPos > 0)
            RawVal := Trim(SubStr(RawVal, 1, CommentPos - 1))

        if (KeyName = "")
            continue

        IsEnabled := (RawVal = "0") ? 0 : 1
        KeyStates[KeyName] := IsEnabled

        ; Áp dụng trạng thái chặn ban đầu
        if (IsEnabled = 0) {
            if SetKeyBlockState(KeyName, true)
                BlockedCount++
        }

        ; Tạo mục trong menu con (dùng & để tránh lỗi ký tự đặc biệt nếu có)
        MenuLabel := KeyName
        KeyLabels[MenuLabel] := KeyName
        KeysSubMenu.Add(MenuLabel, ToggleKeyHandler)

        ; Đánh dấu tích (Check) nếu phím đang Enable (1)
        if (IsEnabled = 1)
            KeysSubMenu.Check(MenuLabel)
        else
            KeysSubMenu.Uncheck(MenuLabel)
    }

    ; Thêm các tùy chọn tiện ích vào cuối menu con
    KeysSubMenu.Add()
    KeysSubMenu.Add("Bật tất cả phím (Enable All)", (*) => SetAllKeys(1))
    KeysSubMenu.Add("Tắt tất cả phím (Disable All)", (*) => SetAllKeys(0))

    ; Gắn vào System Tray Menu
    A_TrayMenu.Add()
    A_TrayMenu.Add("Quản lý phím (config.ini)", KeysSubMenu)
    A_TrayMenu.Add("Mở file config.ini", (*) => Run('notepad.exe "' IniPath '"'))
    A_TrayMenu.Add("Reload script", (*) => Reload())
    A_TrayMenu.Default := "Reload script"

    TrayTip("KeyBlocker đã chạy", "Đang chặn " BlockedCount " / " KeyStates.Count " phím.", 2)
}

; --- Xử lý khi bấm vào một phím trên menu con ---
ToggleKeyHandler(ItemName, ItemPos, MyMenu) {
    global KeyStates, KeyLabels, IniPath

    KeyName := KeyLabels[ItemName]
    NewState := (KeyStates[KeyName] = 1) ? 0 : 1

    ; Cập nhật trạng thái Hotkey thực tế (NewState = 0 nghĩa là bật chặn)
    if !SetKeyBlockState(KeyName, NewState = 0)
        return

    KeyStates[KeyName] := NewState

    ; Cập nhật dấu tích trên menu
    if (NewState = 1)
        MyMenu.Check(ItemName)
    else
        MyMenu.Uncheck(ItemName)

    ; Ghi ngược lại vào file config.ini
    IniWrite(NewState, IniPath, "Keys", KeyName)
}

; --- Bật hoặc tắt toàn bộ danh sách phím cùng lúc ---
SetAllKeys(TargetState) {
    global KeyStates, KeyLabels, KeysSubMenu, IniPath

    for MenuLabel, KeyName in KeyLabels {
        if SetKeyBlockState(KeyName, TargetState = 0) {
            KeyStates[KeyName] := TargetState
            if (TargetState = 1)
                KeysSubMenu.Check(MenuLabel)
            else
                KeysSubMenu.Uncheck(MenuLabel)
            IniWrite(TargetState, IniPath, "Keys", KeyName)
        }
    }
}

; --- Hàm bật/tắt việc chặn 1 phím ---
SetKeyBlockState(KeyName, ShouldBlock) {
    try {
        Hotkey("*" KeyName, BlockKey, ShouldBlock ? "On" : "Off")
        return true
    } catch as err {
        MsgBox("Không thể thao tác với phím '" KeyName "':`n" err.Message, "Lỗi Hotkey", "Iconx")
        return false
    }
}

BlockKey(ThisHotkey) {
    return
}