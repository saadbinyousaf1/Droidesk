# // © https://saadbinyousaf.dev/ © //
param(
  [string]$Action,
  [string]$Name      = '',
  [string]$Api       = '35',
  [string]$Tag       = 'google_apis_playstore',
  [string]$Device    = 'pixel_8',
  [string]$Ram       = '4096',
  [string]$Data      = '16',
  [switch]$Root,
  [string]$MagiskUrl = '',
  [string]$MagiskVer = ''
)
$RootAvdUrl  = 'https://gitlab.com/newbit/rootAVD/-/archive/master/rootAVD-master.zip'
$CmdToolsUrl = 'https://dl.google.com/android/repository/commandlinetools-win-13114758_latest.zip'
$JdkUrl      = 'https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse'

# // © https://saadbinyousaf.dev/ © //
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Base     = Join-Path (Split-Path $PSScriptRoot -Parent) 'data'
$Sdk      = Join-Path $Base 'sdk'
$AvdHome  = Join-Path $Base 'avd'
$UserHome = Join-Path $Base '.android'
$Jdk      = Join-Path $Base 'jdk'
$Tmp      = Join-Path $Base '_tmp'
$UiDir    = Join-Path $Base '.ui'
$TaskFile = "$UiDir\task.json"
$LogFile  = "$UiDir\task.log"
$LiveFile = "$UiDir\task.live"
$SdkMgr   = "$Sdk\cmdline-tools\latest\bin\sdkmanager.bat"
$AvdMgr   = "$Sdk\cmdline-tools\latest\bin\avdmanager.bat"
$Adb      = "$Sdk\platform-tools\adb.exe"
$Emu      = "$Sdk\emulator\emulator.exe"

$env:ANDROID_HOME      = $Sdk
$env:ANDROID_SDK_ROOT  = $Sdk
$env:ANDROID_AVD_HOME  = $AvdHome
$env:ANDROID_USER_HOME = $UserHome
$env:JAVA_HOME         = $Jdk
$env:Path = "$Jdk\bin;$Sdk\platform-tools;$Sdk\emulator;$env:Path"
New-Item -ItemType Directory -Force -Path $Tmp, $UiDir, $Sdk, $AvdHome, $UserHome | Out-Null

# // © https://saadbinyousaf.dev/ © //
$script:Steps = @()
$script:Label = ''
$script:Cur   = 0
$script:Msg   = ''
$script:Dl    = $null
$script:Live  = $false
$script:EmuProc = $null

function Log($t) { Add-Content -Path $LogFile -Value $t -Encoding UTF8 }

function Save-Progress($state) {
  @{
    label = $script:Label; steps = $script:Steps; current = $script:Cur; state = $state
    message = $script:Msg; name = $Name; action = $Action; live = $script:Live; dl = $script:Dl
    pid = $PID; ts = (Get-Date).ToString('o')
  } | ConvertTo-Json -Depth 5 | Set-Content -Path $TaskFile -Encoding UTF8
}

function Init-Progress($label, $steps) {
  $script:Label = $label; $script:Steps = $steps; $script:Cur = 0
  [IO.File]::WriteAllText($LogFile, '')
  [IO.File]::WriteAllText($LiveFile, '')
  Log "droidesk  $label"
  Log "folder     $Base"
  Save-Progress 'running'
}

function Step($i, $hint = '') {
  $script:Cur = $i; $script:Msg = $hint
  Log ''
  Log "==> $($script:Steps[$i])"
  if ($hint) { Log "    $hint" }
  Save-Progress 'running'
}

function Done($m) {
  $script:Cur = $script:Steps.Count; $script:Msg = $m
  Log ''
  Log "OK  $m"
  Save-Progress 'done'
  Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue
  exit 0
}

function Fail($m) {
  $script:Msg = $m; $script:Dl = $null; $script:Live = $false
  Log ''
  Log "ERROR  $m"
  if ($script:EmuProc -and -not $script:EmuProc.HasExited) { & taskkill.exe /T /F /PID $script:EmuProc.Id 2>$null | Out-Null }
  Save-Progress 'failed'
  exit 1
}

# // © https://saadbinyousaf.dev/ © //
function Flush-Live {
  if (Test-Path $LiveFile) {
    $t = [IO.File]::ReadAllText($LiveFile)
    if ($t) { Add-Content -Path $LogFile -Value $t.TrimEnd() -Encoding UTF8 }
    [IO.File]::WriteAllText($LiveFile, '')
  }
  $script:Live = $false
  Save-Progress 'running'
}

function Get-TempBytes {
  $sum = 0
  foreach ($d in "$Sdk\.temp", "$Sdk\.downloadIntermediates") {
    if (Test-Path $d) { $m = (Get-ChildItem $d -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum; if ($m) { $sum += $m } }
  }
  [int64]$sum
}

function Invoke-Cmd([string]$Line, [int]$Stall = 240, [string]$What = 'This step', [string]$Label = '') {
  $f = Join-Path $Tmp 'run.cmd'
  [IO.File]::WriteAllText($LiveFile, '')
  Set-Content -Path $f -Value "@echo off`r`n($Line) < nul >> `"$LiveFile`" 2>&1" -Encoding ASCII
  $script:Live = $true
  Save-Progress 'running'
  $p = Start-Process -FilePath cmd.exe -ArgumentList '/c', "`"$f`"" -NoNewWindow -PassThru
  $null = $p.Handle
  $last = ''; $quiet = 0; $peak = [int64]0
  while (-not $p.WaitForExit(1000)) {
    $len = (Get-Item $LiveFile -ErrorAction SilentlyContinue).Length
    $tb = Get-TempBytes
    $sig = "$len|$tb"
    if ($sig -ne $last) { $last = $sig; $quiet = 0 } else { $quiet++ }
    if ($Label -and $tb -gt 0) {
      if ($tb -gt $peak) { $peak = $tb }
      $script:Dl = @{ label = $Label; bytes = $peak }
      Save-Progress 'running'
    }
    if ($quiet -ge $Stall) {
      & taskkill.exe /T /F /PID $p.Id 2>$null | Out-Null
      Flush-Live
      Fail "$What made no progress for $([math]::Round($Stall / 60)) minutes. Check your internet connection and press Retry."
    }
  }
  $script:Dl = $null
  Flush-Live
  $p.ExitCode
}

# // © https://saadbinyousaf.dev/ © //
function Test-Net {
  & curl.exe -sS -I --connect-timeout 10 --max-time 25 -o NUL 'https://dl.google.com/' 2>$null
  $LASTEXITCODE -eq 0
}

function Get-File($Url, $Dest, $Label) {
  $err = Join-Path $Tmp 'curl.err'
  for ($a = 1; $a -le 5; $a++) {
    Log $(if ($a -eq 1) { "    downloading $Label" } else { "    retrying $Label (attempt $a of 5)" })
    $cargs = @('-L', '--fail', '-sS', '--connect-timeout', '20', '--speed-limit', '1024', '--speed-time', '45', '-o', "`"$Dest`"")
    if ($a -gt 1 -and (Test-Path $Dest)) { $cargs += @('-C', '-') }
    $cargs += "`"$Url`""
    $p = Start-Process -FilePath curl.exe -ArgumentList $cargs -NoNewWindow -PassThru -RedirectStandardError $err
    $null = $p.Handle
    while (-not $p.WaitForExit(1000)) {
      $b = 0; if (Test-Path $Dest) { $b = (Get-Item $Dest).Length }
      $script:Dl = @{ label = $Label; bytes = $b }
      Save-Progress 'running'
    }
    $script:Dl = $null
    if ($p.ExitCode -eq 0) {
      $mb = [math]::Round((Get-Item $Dest).Length / 1MB, 1)
      Log "    got $Label ($mb MB)"
      Save-Progress 'running'
      return
    }
    $e = ''; if (Test-Path $err) { $e = "$(Get-Content $err -Raw)".Trim() }
    Log "    ! interrupted: $e"
    if ($p.ExitCode -in 22, 33, 36) { Remove-Item $Dest -Force -ErrorAction SilentlyContinue }
    if (-not (Test-Net)) { Log '    ! no internet right now, waiting before the next try' }
    Start-Sleep -Seconds (5 * $a)
  }
  Fail "Couldn't download $Label. Check your internet connection and press Retry."
}

function Get-Zip($Url, $Label) {
  $zip = Join-Path $Tmp ([IO.Path]::GetRandomFileName() + '.zip')
  Get-File $Url $zip $Label
  Log "    unpacking $Label"
  $out = Join-Path $Tmp ([IO.Path]::GetRandomFileName())
  try { Expand-Archive -Path $zip -DestinationPath $out -Force } catch { Remove-Item $zip -Force -ErrorAction SilentlyContinue; Fail "$Label downloaded incompletely. Press Retry." }
  Remove-Item $zip -Force
  $out
}

# // © https://saadbinyousaf.dev/ © //
function Read-Ini($p) {
  $h = @{}
  if (Test-Path $p) {
    foreach ($l in Get-Content $p) { if ($l -match '^\s*([^#=]+?)\s*=\s*(.*)$') { $h[$matches[1]] = $matches[2].Trim() } }
  }
  $h
}

function Set-Ini($Path, $Map) {
  $lines = @()
  if (Test-Path $Path) { $lines = @(Get-Content $Path) }
  foreach ($k in $Map.Keys) {
    $lines = @($lines | Where-Object { $_ -notmatch "^\s*$([regex]::Escape($k))\s*=" }) + "$k=$($Map[$k])"
  }
  Set-Content -Path $Path -Value $lines -Encoding ASCII
}

function Accept-Licenses {
  $null = Invoke-Cmd "(for /l %%i in (1,1,40) do @echo y)| call `"$SdkMgr`" --channel=3 --licenses >nul" 180 'Accepting licenses'
}

# // © https://saadbinyousaf.dev/ © //
function Start-Headless {
  $psi = New-Object System.Diagnostics.ProcessStartInfo $Emu
  $psi.Arguments        = "-avd $Name -no-snapshot -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect"
  $psi.UseShellExecute  = $false
  $psi.CreateNoWindow   = $true
  $psi.WorkingDirectory = Split-Path $Emu
  $script:EmuProc = [Diagnostics.Process]::Start($psi)
  Log "    started $Name in the background"
}

function Wait-Boot {
  & $Adb start-server *> $null
  $t = 0
  while ($true) {
    Start-Sleep 3; $t += 3
    if ($script:EmuProc.HasExited) { Fail 'The emulator closed while starting. Make sure virtualization is turned on in your BIOS.' }
    $b = "$(& $Adb shell getprop sys.boot_completed 2>$null)".Trim()
    if ($b -eq '1') { break }
    if ($t -ge 900) { Fail "$Name took too long to boot." }
    if ($t % 30 -eq 0) { Log "    still booting ($t s)" }
  }
  Log "    $Name booted in $t s"
  Start-Sleep 8
}

function Stop-Headless {
  if (-not $script:EmuProc) { return }
  if (-not $script:EmuProc.WaitForExit(30000)) {
    & $Adb emu kill *> $null
    if (-not $script:EmuProc.WaitForExit(15000)) { & taskkill.exe /T /F /PID $script:EmuProc.Id 2>$null | Out-Null }
  }
  $script:EmuProc = $null
}

# // © https://saadbinyousaf.dev/ © //
function Repair-Image($sys) {
  $full = "$Sdk\$sys\ramdisk.img"
  if (Test-Path "$full.backup") {
    Log '    ramdisk.img was missing, restoring it from the rootAVD backup'
    Copy-Item "$full.backup" $full -Force
    return
  }
  Log '    ramdisk.img was missing, downloading a fresh copy of this Android image'
  $pkg = ($sys -replace '[\\/]', ';')
  if (Test-Path "$Sdk\$sys") { Remove-Item "$Sdk\$sys" -Recurse -Force }
  Accept-Licenses
  $null = Invoke-Cmd "call `"$SdkMgr`" --channel=3 --install `"$pkg`"" 240 'The image download' 'Android image'
}

# // © https://saadbinyousaf.dev/ © //
function Invoke-Root([int]$off) {
  $dir = Join-Path $AvdHome "$Name.avd"
  $c = Read-Ini "$dir\config.ini"
  $sys = "$($c['image.sysdir.1'])".TrimEnd('\', '/')
  $ramdisk = "$sys\ramdisk.img"
  if (-not $sys) { Fail "$Name has no Android image set in its config.ini." }
  if (@(Get-Process -Name 'qemu-system-*' -ErrorAction SilentlyContinue).Count) { Fail 'Stop every running device first, then press Retry.' }

  Step $off "Magisk $MagiskVer"
  if (-not (Test-Path "$Sdk\$ramdisk")) { Repair-Image $sys }
  if (-not (Test-Path "$Sdk\$ramdisk")) { Fail "Couldn't find or restore $Sdk\$ramdisk" }
  if (-not (Test-Path "$Base\rootAVD\rootAVD.bat")) {
    $x = Get-Zip $RootAvdUrl 'rootAVD'
    $inner = Get-ChildItem $x -Directory | Select-Object -First 1
    Move-Item $inner.FullName "$Base\rootAVD"
    Remove-Item $x -Recurse -Force
  }
  if ($MagiskUrl) { Get-File $MagiskUrl "$Base\rootAVD\Magisk.zip" "Magisk $MagiskVer" }

  Step ($off + 1) 'Booting the device in the background'
  Start-Headless
  Wait-Boot

  Step ($off + 2) 'rootAVD is patching the image. This takes a minute or two.'
  $null = Invoke-Cmd "cd /d `"$Base\rootAVD`" && call rootAVD.bat $ramdisk" 300 'rootAVD'
  Stop-Headless

  if (-not (Test-Path "$Sdk\$ramdisk.backup")) { Fail 'rootAVD did not patch the image. The details are in the log above.' }
  if ($MagiskVer) { Set-Content -Path "$dir\.magisk" -Value $MagiskVer -Encoding ASCII }
  New-Item -ItemType File -Force -Path "$dir\.rooted" | Out-Null
  Done "$Name is rooted. Cold start it once, open Magisk and accept the extra setup."
}

# // © https://saadbinyousaf.dev/ © //
function Invoke-Create {
  if ($Name -notmatch '^[A-Za-z0-9._-]+$') { Fail 'Names can use letters, numbers, dot, dash and underscore.' }
  $dir = Join-Path $AvdHome "$Name.avd"
  if (Test-Path $dir) { Fail "A device called $Name already exists." }
  $image = "system-images;android-$Api;$Tag;x86_64"
  $sys   = "system-images\android-$Api\$Tag\x86_64"

  Step 0 $image
  if (Test-Path "$Sdk\$sys\source.properties") {
    Log '    already downloaded'
  } else {
    Accept-Licenses
    $null = Invoke-Cmd "call `"$SdkMgr`" --channel=3 --install `"$image`"" 240 'The image download' 'Android image'
    if (-not (Test-Path "$Sdk\$sys\source.properties")) { Fail "Google didn't provide $image. Try another image type for this version." }
  }

  Step 1
  $null = Invoke-Cmd "echo no| call `"$AvdMgr`" create avd -n $Name -k `"$image`" -d $Device -p `"$dir`"" 120 'Creating the device'
  if (-not (Test-Path "$dir\config.ini")) { Fail 'avdmanager could not create the device. The phone model may not support this Android version.' }
  Set-Ini "$dir\config.ini" ([ordered]@{
    'hw.ramSize'              = $Ram
    'vm.heapSize'             = '512'
    'hw.cpu.ncore'            = '4'
    'hw.gpu.enabled'          = 'yes'
    'hw.gpu.mode'             = 'host'
    'hw.keyboard'             = 'yes'
    'disk.dataPartition.size' = "${Data}G"
    'fastboot.forceColdBoot'  = 'no'
    'fastboot.forceFastBoot'  = 'yes'
  })
  Set-Content -Path "$AvdHome\$Name.ini" -Encoding ASCII -Value @(
    'avd.ini.encoding=UTF-8', "path=$dir", "path.rel=avd\$Name.avd", "target=android-$Api"
  )
  Log "    $Name created"

  if ($Root) { Invoke-Root 2 } else { Done "$Name is ready." }
}

# // © https://saadbinyousaf.dev/ © //
function Invoke-Setup {
  Step 0
  if (-not (Test-Net)) { Fail "Can't reach Google's download servers. Check your internet connection and press Retry." }
  Log '    online'

  Step 1
  if (Test-Path "$Jdk\bin\java.exe") { Log '    already installed' } else {
    $x = Get-Zip $JdkUrl 'Java 21'
    $inner = Get-ChildItem $x -Directory | Select-Object -First 1
    if (Test-Path $Jdk) { Remove-Item $Jdk -Recurse -Force }
    Move-Item $inner.FullName $Jdk
    Remove-Item $x -Recurse -Force
  }

  Step 2
  if (Test-Path $SdkMgr) { Log '    already installed' } else {
    $x = Get-Zip $CmdToolsUrl 'Android command-line tools'
    New-Item -ItemType Directory -Force -Path "$Sdk\cmdline-tools" | Out-Null
    if (Test-Path "$Sdk\cmdline-tools\latest") { Remove-Item "$Sdk\cmdline-tools\latest" -Recurse -Force }
    Move-Item "$x\cmdline-tools" "$Sdk\cmdline-tools\latest"
    Remove-Item $x -Recurse -Force
  }

  Step 3
  $pkgs = @()
  if (-not (Test-Path $Adb)) { $pkgs += '"platform-tools"' }
  if (-not (Test-Path $Emu)) { $pkgs += '"emulator"' }
  if ($pkgs.Count) {
    Accept-Licenses
    $null = Invoke-Cmd "call `"$SdkMgr`" --install $($pkgs -join ' ')" 240 'The emulator download' 'Android Emulator'
    if (-not (Test-Path $Emu) -or -not (Test-Path $Adb)) { Fail 'The emulator did not install completely. Press Retry.' }
  } else { Log '    already installed' }

  Step 4 'Checking that Windows can run the emulator at full speed'
  $acc = "$(& $Emu -accel-check 2>&1 | Out-String)".Trim()
  foreach ($l in ($acc -split "`r?`n")) { if ($l.Trim()) { Log "    $($l.Trim())" } }
  $reboot = $false
  if ($acc -notmatch 'usable') {
    $script:Msg = 'Accept the Windows admin prompt to turn on Windows Hypervisor Platform.'
    Log "    $($script:Msg)"
    Save-Progress 'running'
    try {
      $p = Start-Process -FilePath powershell.exe -Verb RunAs -WindowStyle Hidden -Wait -PassThru -ArgumentList `
        '-NoProfile', '-Command', 'Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart | Out-Null'
    } catch {
      Fail 'Droidesk needs Windows Hypervisor Platform turned on. Press Retry and accept the admin prompt.'
    }
    Set-Content -Path "$UiDir\reboot.flag" -Value (Get-Date).ToString('o') -Encoding ASCII
    Log '    Windows Hypervisor Platform turned on'
    $reboot = $true
  }

  Step 5
  foreach ($kv in @(@('ANDROID_HOME', $Sdk), @('ANDROID_SDK_ROOT', $Sdk), @('ANDROID_AVD_HOME', $AvdHome), @('ANDROID_USER_HOME', $UserHome))) {
    [Environment]::SetEnvironmentVariable($kv[0], $kv[1], 'User')
  }
  Set-Content -Path "$UiDir\setup.done" -Value (Get-Date).ToString('o') -Encoding ASCII
  Remove-Item "$UiDir\accel.missing" -Force -ErrorAction SilentlyContinue
  if ($reboot) { Done 'Restart Windows to finish. Then open Droidesk and create your first device.' }
  Done 'Droidesk is ready. Create your first device.'
}

# // © https://saadbinyousaf.dev/ © //
try {
  switch ($Action) {
    'Setup' {
      Init-Progress 'Setting up Droidesk' @('Check the connection', 'Portable Java 21', 'Android command-line tools', 'Emulator and platform tools', 'Hardware acceleration', 'Finish')
      Invoke-Setup
    }
    'Create' {
      $steps = @('Get the Android image', 'Build the device')
      if ($Root) { $steps += @('Get Magisk and rootAVD', 'First boot', 'Patch with Magisk') }
      Init-Progress "Creating $Name" $steps
      Invoke-Create
    }
    'Root' {
      Init-Progress "Rooting $Name" @('Get Magisk and rootAVD', 'First boot', 'Patch with Magisk')
      Invoke-Root 0
    }
    'Update' {
      Init-Progress 'Updating the emulator' @('Check the connection', 'Update emulator and adb')
      Step 0
      if (-not (Test-Net)) { Fail "Can't reach Google's download servers. Check your internet connection and press Retry." }
      Step 1
      Accept-Licenses
      $rc = Invoke-Cmd "call `"$SdkMgr`" --install `"emulator`" `"platform-tools`"" 240 'The update' 'Emulator update'
      if ($rc -ne 0) { Fail 'sdkmanager could not finish the update. Press Retry.' }
      Done 'The emulator and adb are up to date. Your Android images and root were not touched.'
    }
    default { Fail "Unknown action: $Action" }
  }
} catch {
  Fail $_.Exception.Message
}
# // © https://saadbinyousaf.dev/ © //
