@echo off
echo -
echo Iniciando Servidor
echo -
start ..\CitizenFX\FXServer.exe +exec core.cfg +set onesync on +set sv_enforceGameBuild 2189
exit