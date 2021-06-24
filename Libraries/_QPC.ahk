/*
	Function: QueryPerformanceFrequency

	Example:
		_QPC("reset")
		sleep 500
		msgbox % _QPC()

		Result: 0.498

*/

_QPC(Reset := 0) ; By SKAN,  http://goo.gl/nf7O4G,  CD:01/Sep/2014 | MD:02/Sep/2014
{
	static PrvQPC := 0, FRQ := 0, QPC := 0

	if !(FRQ)
		DllCall("kernel32.dll\QueryPerformanceFrequency", "Int64P", FRQ)

	DllCall("kernel32.dll\QueryPerformanceCounter", "Int64P", QPC)

	if (Reset)
	{
		PrvQPC := QPC
		return QPC / FRQ
	}
	else
	{
		return (QPC - PrvQPC) / FRQ
	}
}