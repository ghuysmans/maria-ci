Option Explicit

'FIXME arguments, wsf
Dim drive, size, force
drive = "t:"
size = "256M"
force = False


Dim wsh
Set wsh = CreateObject("WScript.Shell")

'adapted from https://stackoverflow.com/a/45069476
Function IsAdmin()
	On Error Resume Next
	wsh.RegRead "HKEY_USERS\S-1-5-19\Environment\TEMP"
	IsAdmin = Err.Number = 0
End Function

Function Run(cmd)
	On Error Resume Next
	Set Run = wsh.Exec(cmd)
	If Err Then
		Set Run = Nothing
	Else
		With Run
			Dim i
			While .Status = 0 'wshRunning
				WScript.Sleep 100 'ms
				i = i + 1
				If i = 5 Then
					.Terminate
					Exit Function
				End If
			Wend
		End With
	End If
End Function

Sub Dispose(exe)
	With exe
			.StdIn.Close
			.StdErr.Close
			.StdOut.Close
	End With
End Sub

Sub TryOrQuit(Command, ExitCode)
	Dim exe
	Set exe = Run(Command)
	If exe.ExitCode Then
		WScript.Echo exe.StdErr.ReadAll()
		WScript.Quit ExitCode
	End If
	Dispose exe
End Sub

Function InstallRun(test, app)
	Set InstallRun = Run(test)
	If InstallRun Is Nothing Then
		WScript.Echo "Installing " & app & "..."
		Dim exe
		Set exe = Run("winget install -h " & app)
		Dim ok
		If exe Is Nothing Then
			ok = False
		Else
			'FIXME status?
			ok = exe.ExitCode = 0
			Dispose exe
		End If
		If Not ok Then
			WScript.Echo "Please install " & app & ". Type ""done"" when you're done."
			While WScript.StdIn.ReadLine() <> "done"
			Wend
		End If
		Set InstallRun = Run(test)
		If InstallRun is Nothing Then
			WScript.Echo "Failed:", test
			WScript.Quit 1
		End If
	End If
End Function

Dim fso
Set fso = CreateObject("Scripting.FileSystemObject")


Dim exe, e
Dim datadir, dataarg, pidfile, pidarg, logarg, addr
datadir = drive & "\data"
dataarg = " --datadir=" & datadir
pidfile = drive & "\mysqld.pid"
pidarg = " --pid-file=" & pidfile
logarg = " --log-error=" & drive & "\error.log"
addr = "127.0.0.1"

If Not fso.DriveExists(drive) Then
	Set exe = InstallRun("imdisk -l", "ImDiskApp")
	Dim disks
	While Not exe.StdOut.AtEndOfStream
		exe.StdOut.ReadLine
		disks = disks + 1
	Wend
	Dispose exe
	If disks Then WScript.Echo "There's an existing ImDisk drive."

	WScript.Echo "Creating the virtual drive..."
	If Not IsAdmin Then
		WScript.Echo "Please run this script as an administrator."
		WScript.Quit 8
	End If
	TryOrQuit "imdisk -a -t vm -s " & size & " -m " & drive, 6

	WScript.Echo "Formatting the virtual drive..."
	TryOrQuit "format.com /fs:fat32 /q /y " & drive, 7
End If

If Not fso.FolderExists(datadir) Then
	WScript.Echo "Initializing the data directory..."
	TryOrQuit "mysql_install_db" & dataarg, 3
End If

If Not fso.FileExists(pidfile) Or force Then
	'TODO let the user choose how we connect (ODBC, CLI)
	Set exe = Run("mysql -h " & addr & " -u root --password=test -e ""SELECT 1""")
	If exe Is Nothing Then
		WScript.Echo "Please install a MySQL client."
		WScript.Quit 4
	Else
		e = exe.StdErr.ReadAll()
		If InStr(e, "Access denied for user") Then
			WScript.Echo "A server is already running on the same port. Please stop it."
			WScript.Quit 9
		End If
	End If
	Dispose exe
	WScript.Echo "Starting the test server..."
	wsh.Run "mysqld" & dataarg & pidarg & logarg & " --bind-address=" & addr & " --performance_schema=0"
	Set exe = Run("mysqladmin -h " & addr & " -u root password test")
	If exe.ExitCode Then
		e = exe.StdErr.ReadAll()
		If InStr(e, "Access denied for user") Then
			WScript.Echo "Warning: can't set the password."
		Else
			WScript.Echo e
		End If
	End If
	Dispose exe
End If

Set exe = Run("mysql -h " & addr & " -u root --password=test -e ""SELECT 1""")
If exe Is Nothing Then
	WScript.Echo "Couldn't test the server, please install a MySQL client."
	WScript.Quit 4
ElseIf exe.ExitCode Then
	WScript.Echo exe.StdErr.ReadAll()
	WScript.Quit 5
Else
	WScript.Echo "Ready."
End If


If False Then
	Set exe = Run("imdisk -d -m " & drive)
	e = exe.StdErr.ReadAll()
	Dispose exe
	If InStr(e, "Fonction incorrecte") Then 'FIXME
		WScript.Echo "Couldn't unmount " & drive & "."
	End If
End If
