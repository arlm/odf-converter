[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=0
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
TargetName=OdfWordXPAddinSetup.exe
FriendlyName=ODF Add-In for Word XP
AppLaunched=CMD /C SetupPrepare.bat
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="setup.exe"
FILE1="OdfWordXPAddinSetup.msi"
FILE2="extensibilityMSM.msi"
FILE3="lockbackRegKey.msi"
FILE4="office2003-kb907417sfxcab-ENU.exe"
FILE5="SetupPrepare.bat"
[SourceFiles]
SourceFiles0=
SourceFiles1=KB908002\
SourceFiles2=..\
[SourceFiles0]
%FILE0%=
%FILE1%=
[SourceFiles1]
%FILE2%=
%FILE3%=
%FILE4%=
[SourceFiles2]
%FILE5%=