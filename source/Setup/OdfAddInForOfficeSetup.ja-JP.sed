[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=%AdminQuietInstCmd%
UserQuietInstCmd=%UserQuietInstCmd%
SourceFiles=SourceFiles
[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=OdfAddInForOfficeSetup-ja.exe
FriendlyName=Microsoft Office 用 ODF アドイン
AppLaunched=CMD /C SetupPrepare.bat
PostInstallCmd=CMD /C ECHO FINISHED
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="setup.exe"
FILE1="OdfAddInForOfficeSetup.msi"
FILE2="extensibilityMSM.msi"
FILE3="lockbackRegKey.msi"
FILE4="office2003-kb907417sfxcab-ENU.exe"
FILE5="SetupPrepare.bat"
[SourceFiles]
SourceFiles0=ja-JP
SourceFiles1=..\..\..\..\packages\KB908002\
SourceFiles2=..\..\scripts\
[SourceFiles0]
%FILE0%=
%FILE1%=
[SourceFiles1]
%FILE2%=
%FILE3%=
%FILE4%=
[SourceFiles2]
%FILE5%=