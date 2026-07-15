build:
	powershell -File icon.ps1
	odin build . -resource:camera.rc -out:camera.exe -subsystem:windows
