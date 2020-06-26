AddCommas(n)

{

	StringSplit, d, n, .

	Loop, % StrLen(d1)

		x := SubStr(d1, 1-A_Index, 1), c := x . (A_Index>1 && !Mod(A_Index-1,3) ? "," : "") . c

	return c . (d0=2 ? "." d2 : "")

}