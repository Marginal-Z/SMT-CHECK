param([Parameter(Mandatory)][string]$InstallDir)
$ErrorActionPreference = 'Stop'
$exe = Join-Path $InstallDir 'SMT-CHECK.exe'
$icon = Join-Path $InstallDir 'smt-fusion-20261017.ico'
$source = Join-Path $PSScriptRoot '../windows/runner/resources/app_icon.ico'
if ((Get-FileHash $icon).Hash -ne (Get-FileHash $source).Hash) { throw 'Installed standalone icon differs from approved artwork' }
# Inspect executable resources without loading its code. Compare every icon size.
Add-Type -TypeDefinition @'
using System; using System.IO; using System.Runtime.InteropServices;
public static class FusionIconCheck {
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode)] static extern IntPtr LoadLibraryEx(string path,IntPtr reserved,uint flags);
 [DllImport("kernel32.dll")] static extern IntPtr FindResource(IntPtr module,IntPtr name,IntPtr type);
 [DllImport("kernel32.dll")] static extern uint SizeofResource(IntPtr module,IntPtr info);
 [DllImport("kernel32.dll")] static extern IntPtr LoadResource(IntPtr module,IntPtr info);
 [DllImport("kernel32.dll")] static extern IntPtr LockResource(IntPtr data);
 [DllImport("kernel32.dll")] static extern bool FreeLibrary(IntPtr module);
 static byte[] Read(IntPtr module,int id,int type) { var info=FindResource(module,(IntPtr)id,(IntPtr)type); if(info==IntPtr.Zero)throw new IOException("Missing icon resource");var data=new byte[SizeofResource(module,info)];Marshal.Copy(LockResource(LoadResource(module,info)),data,0,data.Length);return data; }
 public static void Verify(string exe,string ico) {
  var module=LoadLibraryEx(exe,IntPtr.Zero,0x22);if(module==IntPtr.Zero)throw new IOException("Cannot map PE resources");
  try {var source=File.ReadAllBytes(ico);var group=Read(module,101,14);int count=BitConverter.ToUInt16(source,4);if(BitConverter.ToUInt16(group,4)!=count)throw new IOException("Icon size count mismatch");
   for(int i=0;i<count;i++){int a=6+i*16,b=6+i*14;var data=Read(module,BitConverter.ToUInt16(group,b+12),3);int offset=BitConverter.ToInt32(source,a+12),size=BitConverter.ToInt32(source,a+8);if(data.Length!=size)throw new IOException("Icon frame length differs");for(int j=0;j<size;j++)if(data[j]!=source[offset+j])throw new IOException("Embedded icon artwork differs");}
  }finally{FreeLibrary(module);}
 }
}
'@
[FusionIconCheck]::Verify($exe, $icon)
$desktop = [Environment]::GetFolderPath('Desktop')
$programs = [Environment]::GetFolderPath('Programs')
$shell = New-Object -ComObject WScript.Shell
$explorer = New-Object -ComObject Shell.Application
function Assert-FusionLink([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "Missing shortcut: $Path" }
    $link = $shell.CreateShortcut($Path)
    if ($link.TargetPath -ne $exe -or $link.IconLocation -ne "$icon,0") { throw "Shortcut target/icon mismatch: $Path" }
    $item = $explorer.NameSpace((Split-Path $Path)).ParseName((Split-Path $Path -Leaf))
    if ($item.ExtendedProperty('System.AppUserModel.ID') -ne 'MarginalZ.SMTFusion.Desktop') { throw "Shortcut AppUserModelID mismatch: $Path" }
}
Assert-FusionLink (Join-Path $desktop 'SMT Fusion.lnk')
Assert-FusionLink (Join-Path $programs 'SMT Fusion/SMT Fusion.lnk')
# Seed an old own link and a similarly named unrelated link. Repair must only
# touch shortcuts targeting this exact installation, including pinned ones.
$pinned = Join-Path $env:APPDATA 'Microsoft/Internet Explorer/Quick Launch/User Pinned/TaskBar'
New-Item -ItemType Directory -Path $pinned -Force | Out-Null
$own = Join-Path $pinned 'SMT Fusion icon test.lnk'
$other = Join-Path $desktop 'SMT unrelated icon test.lnk'
try {
    $link = $shell.CreateShortcut($own); $link.TargetPath=$exe; $link.IconLocation="$exe,0"; $link.Save()
    $link = $shell.CreateShortcut($other); $link.TargetPath=Join-Path $env:WINDIR 'System32/notepad.exe'; $link.Save()
    $before = (Get-FileHash $other).Hash
    $repair = Start-Process $exe -ArgumentList '--repair-icons' -PassThru -WindowStyle Hidden
    if (-not $repair.WaitForExit(20000) -or $repair.ExitCode -ne 0) { throw 'Native icon repair failed' }
    Assert-FusionLink $own
    if ((Get-FileHash $other).Hash -ne $before) { throw 'Repair modified another application shortcut' }
} finally {
    Remove-Item -LiteralPath $own,$other -Force -ErrorAction SilentlyContinue
}
Write-Host 'Verified embedded/installed ICO, desktop, Start menu, AppUserModelID and isolated pinned-shortcut repair.'
