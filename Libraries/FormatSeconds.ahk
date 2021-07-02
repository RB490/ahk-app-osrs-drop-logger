FormatSeconds(s) {
    t := A_YYYY A_MM A_DD 00 00 00
    t += s, seconds
    FormatTime, output, % t, HH:mm:ss
    return output
}