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
TargetName=OdfAddInForWordSetup-fr.exe
FriendlyName=ODF Add-In for Word
AppLaunched=CMD /C SetupPrepare.bat
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="setup.exe"
FILE1="OdfAddInForWordSetup.msi"
FILE2="extensibilityMSM.msi"
FILE3="lockbackRegKey.msi"
FILE4="office2003-kb907417sfxcab-ENU.exe"
FILE5="SetupPrepare.bat"
FILE6="o2003pia.msi"
FILE7="o2003pia_eula.txt"
[SourceFiles]
SourceFiles0=
SourceFiles1=KB908002\
SourceFiles2=..\
SourceFiles3=PIA2003\
[SourceFiles0]
%FILE0%=
%FILE1%=
[SourceFiles1]
%FILE2%=
%FILE3%=
%FILE4%=
[SourceFiles2]
%FILE5%=
[SourceFiles3]
%FILE6%=
%FILE7%=