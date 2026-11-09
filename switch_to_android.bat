@echo off
echo Switching to Android...
ren lib lib_ios_active
ren lib_android lib
echo Done! Now run: flutter build apk --release
pause
