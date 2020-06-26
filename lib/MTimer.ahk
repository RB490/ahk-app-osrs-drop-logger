MTimer() {
    static startTime, timerActive
 
    If !(timerActive) {
        timerActive := true
        startTime := A_TickCount
    }
    else {
        timerActive := false
        elapsedTime := A_TickCount - startTime
        msgbox, 4160, , % A_ThisFunc ": " elapsedTime " milliseconds have elapsed."
    }
}