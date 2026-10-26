@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo Copiando o site para dentro do app...
robocopy "%~dp0.." "%~dp0www" /E /XD app-android node_modules /XF *.sql *.zip >nul
echo Instalando o Capacitor (precisa de internet)...
call npm install @capacitor/core @capacitor/cli @capacitor/android
if not exist android call npx cap add android
call npx cap sync android
echo.
echo Pronto. Vai abrir o Android Studio: la em cima, Build ^> Build APK(s).
call npx cap open android
pause
