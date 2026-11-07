# // © https://saadbinyousaf.dev/ © //
$ErrorActionPreference = 'Continue'
$AppName    = 'Droidesk'
$AppVersion = '1.0.1'
$SiteUrl    = 'https://saadbinyousaf.dev/'
$RepoUrl    = 'https://github.com/saadbinyousaf1/Droidesk'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Core     = $PSScriptRoot
$Root     = Split-Path $Core -Parent
$Data     = Join-Path $Root 'data'
$Sdk      = Join-Path $Data 'sdk'
$AvdHome  = Join-Path $Data 'avd'
$UserHome = Join-Path $Data '.android'
$Jdk      = Join-Path $Data 'jdk'
$UiDir    = Join-Path $Data '.ui'
$AppDir   = Join-Path $Core 'app'
$Emu      = "$Sdk\emulator\emulator.exe"
$Adb      = "$Sdk\platform-tools\adb.exe"
$SdkMgr   = "$Sdk\cmdline-tools\latest\bin\sdkmanager.bat"
$AvdMgr   = "$Sdk\cmdline-tools\latest\bin\avdmanager.bat"
$TaskFile = "$UiDir\task.json"
$InfoFile = "$UiDir\server.json"

$env:ANDROID_HOME      = $Sdk
$env:ANDROID_SDK_ROOT  = $Sdk
$env:ANDROID_AVD_HOME  = $AvdHome
$env:ANDROID_USER_HOME = $UserHome
$env:JAVA_HOME         = $Jdk
$env:Path = "$Jdk\bin;$Sdk\platform-tools;$Sdk\emulator;$env:Path"
Get-ChildItem -Path $Root, $Core, $AppDir -File -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue

# // © https://saadbinyousaf.dev/ © //
$ApiNames  = @{
  '28' = '9'; '29' = '10'; '30' = '11'; '31' = '12'; '32' = '12L'; '33' = '13'; '34' = '14'
  '35' = '15'; '36' = '16'; '36.1' = '16 QPR'; '37' = '17'; '38' = '18'; '39' = '19'
}
$Codenames = @{ 'Baklava' = '16'; 'CinnamonBun' = '17' }
$DefaultDevices = @('pixel_9_pro', 'pixel_9', 'pixel_8', 'pixel_7_pro', 'pixel_7', 'pixel_6', 'pixel_tablet')

$script:SerialName   = @{}
$script:Booted       = @{}
$script:MagiskCheck  = @{}
$script:PendingStop  = @{}
$script:TaskProc     = $null
$script:VerJob       = $null
$script:DevJob       = $null
$script:MagiskCache  = $null
$script:MagiskAt     = [datetime]::MinValue
$script:RunCache     = $null
$script:RunAt        = [datetime]::MinValue

# // © https://saadbinyousaf.dev/ © //
function Find-Edge {
  @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
}

function Open-App($port, $token) {
  $url = "http://localhost:$port/#$token"
  $edge = Find-Edge
  if ($edge) {
    Start-Process -FilePath $edge -ArgumentList "--app=$url", "--user-data-dir=`"$UiDir\edge`"", '--window-size=1280,820', '--no-first-run', '--no-default-browser-check'
  } else {
    Start-Process $url
  }
}

function Set-Shortcut {
  try {
    $desk = [Environment]::GetFolderPath('Desktop')
    foreach ($o in 'Android Vault.lnk', 'DroidKeep.lnk') { $old = Join-Path $desk $o; if (Test-Path $old) { Remove-Item $old -Force -ErrorAction SilentlyContinue } }
    $lnk = Join-Path $desk "$AppName.lnk"
    $sh = New-Object -ComObject WScript.Shell
    $s = $sh.CreateShortcut($lnk)
    if ($s.Arguments -like "--headless*$Core\server.ps1*" -and $s.IconLocation -like '*icon.ico*') { return }
    $s.TargetPath       = "$env:SystemRoot\System32\conhost.exe"
    $s.Arguments        = "--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File `"$Core\server.ps1`""
    $s.WorkingDirectory = $Root
    $s.WindowStyle      = 7
    $s.Description      = "$AppName - rooted Android emulators without Android Studio"
    if (Test-Path "$AppDir\icon.ico") { $s.IconLocation = "$AppDir\icon.ico,0" }
    $s.Save()
  } catch {}
}

# // © https://saadbinyousaf.dev/ © //
function Open-External($u) {
  if ("$u" -like "$SiteUrl*" -or "$u" -like "$RepoUrl*" -or "$u" -like 'https://github.com/topjohnwu/*' -or "$u" -like 'https://gitlab.com/newbit/*') { Start-Process "$u" }
}

# // © https://saadbinyousaf.dev/ © //
function Get-WebView2 {
  $dir = Join-Path $Data 'webview2'
  if ((Test-Path "$dir\Microsoft.Web.WebView2.WinForms.dll") -and (Test-Path "$dir\WebView2Loader.dll")) { return $dir }
  try {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $tmp = Join-Path $env:TEMP ('vault_wv2_' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    & curl.exe -sL --fail -o "$tmp\wv2.zip" 'https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2'
    if ($LASTEXITCODE -ne 0) { return $null }
    Expand-Archive -Path "$tmp\wv2.zip" -DestinationPath "$tmp\x" -Force
    $lib = Get-ChildItem "$tmp\x\lib" -Directory | Where-Object { $_.Name -match '^net4\d' } | Sort-Object Name -Descending | Select-Object -First 1
    Copy-Item "$($lib.FullName)\Microsoft.Web.WebView2.Core.dll", "$($lib.FullName)\Microsoft.Web.WebView2.WinForms.dll" $dir -Force
    Copy-Item "$tmp\x\runtimes\win-x64\native\WebView2Loader.dll" $dir -Force
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path "$dir\WebView2Loader.dll") { return $dir }
  } catch {}
  $null
}

# // © https://saadbinyousaf.dev/ © //
function Show-Window($url) {
  $wvDir = Get-WebView2
  if (-not $wvDir) { return $false }
  try {
    $env:Path = "$wvDir;$env:Path"
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    Add-Type -Path "$wvDir\Microsoft.Web.WebView2.Core.dll"
    Add-Type -Path "$wvDir\Microsoft.Web.WebView2.WinForms.dll"
    Add-Type -Namespace Vault -Name Dwm -MemberDefinition '[DllImport("dwmapi.dll")] public static extern int DwmSetWindowAttribute(IntPtr h, int a, ref int v, int s);'
  } catch { return $false }

  [System.Windows.Forms.Application]::EnableVisualStyles()
  $form = New-Object System.Windows.Forms.Form
  $form.Text          = $AppName
  $form.ClientSize    = New-Object System.Drawing.Size(1280, 820)
  $form.MinimumSize   = New-Object System.Drawing.Size(920, 640)
  $form.StartPosition = 'CenterScreen'
  $form.BackColor     = [System.Drawing.Color]::FromArgb(29, 33, 39)
  if (Test-Path "$AppDir\icon.ico") { try { $form.Icon = New-Object System.Drawing.Icon("$AppDir\icon.ico") } catch {} }
  $form.Add_HandleCreated({
    try {
      $on = 1; [void][Vault.Dwm]::DwmSetWindowAttribute($form.Handle, 20, [ref]$on, 4)
      $cap = 0x0027211D; [void][Vault.Dwm]::DwmSetWindowAttribute($form.Handle, 35, [ref]$cap, 4)
      $txt = 0x00E8EDEC; [void][Vault.Dwm]::DwmSetWindowAttribute($form.Handle, 36, [ref]$txt, 4)
    } catch {}
  })

  $wv = New-Object Microsoft.Web.WebView2.WinForms.WebView2
  $wv.Dock = 'Fill'
  try { $wv.DefaultBackgroundColor = [System.Drawing.Color]::FromArgb(29, 33, 39) } catch {}
  $cp = New-Object Microsoft.Web.WebView2.WinForms.CoreWebView2CreationProperties
  $cp.UserDataFolder = "$UiDir\webview"
  $wv.CreationProperties = $cp
  $wv.Add_CoreWebView2InitializationCompleted({
    param($sender, $e)
    if ($e.IsSuccess) {
      $st = $sender.CoreWebView2.Settings
      $st.AreDevToolsEnabled = $false
      $st.IsStatusBarEnabled = $false
      $st.AreDefaultContextMenusEnabled = $false
      $st.IsZoomControlEnabled = $false
      $st.AreBrowserAcceleratorKeysEnabled = $false
      $sender.CoreWebView2.Add_NewWindowRequested({ param($s2, $e2) $e2.Handled = $true; Open-External $e2.Uri })
    } else {
      $script:WvFailed = $true
      $form.Close()
    }
  })
  $form.Controls.Add($wv)
  $wv.Source = [Uri]$url

  $script:Hosted = $true
  $script:Form   = $form
  $script:Ar     = $listener.BeginGetContext($null, $null)
  $script:TickN  = 0
  $timer = New-Object System.Windows.Forms.Timer
  $timer.Interval = 20
  $timer.Add_Tick({
    try {
      $n = 0
      while ($script:Ar.IsCompleted -and $n -lt 10) {
        $ctx = $listener.EndGetContext($script:Ar)
        $script:Ar = $listener.BeginGetContext($null, $null)
        try { Invoke-Route $ctx } catch { try { Send $ctx 400 @{ error = $_.Exception.Message } } catch {} }
        $n++
      }
      if ((++$script:TickN % 25) -eq 0) { Invoke-PendingStops; Invoke-Jobs }
      if ($script:FocusReq) {
        $script:FocusReq = $false
        if ($script:Form.WindowState -eq 'Minimized') { $script:Form.WindowState = 'Normal' }
        $script:Form.Activate()
      }
    } catch {}
  })
  $timer.Start()
  [System.Windows.Forms.Application]::Run($form)
  $timer.Stop()
  $script:Hosted = $false
  -not $script:WvFailed
}

# // © https://saadbinyousaf.dev/ © //
if (Test-Path $InfoFile) {
  try {
    $info = Get-Content $InfoFile -Raw | ConvertFrom-Json
    $r = Invoke-RestMethod "http://localhost:$($info.port)/api/focus" -Method Post -Headers @{ 'X-Vault' = $info.token } -TimeoutSec 3
    if (-not $r.hosted) { Open-App $info.port $info.token }
    exit 0
  } catch {}
}

# // © https://saadbinyousaf.dev/ © //
function Read-Ini($p) {
  $h = @{}
  if (Test-Path $p) {
    foreach ($l in Get-Content $p) { if ($l -match '^\s*([^#=]+?)\s*=\s*(.*)$') { $h[$matches[1]] = $matches[2].Trim() } }
  }
  $h
}

function Get-AndroidOf($key) {
  if ($ApiNames.ContainsKey("$key")) { return @{ android = $ApiNames["$key"]; preview = $false; rank = [double]("$key" -replace '[^\d.]', '') } }
  if ($Codenames.ContainsKey("$key")) { $n = $Codenames["$key"]; return @{ android = $n; preview = $true; rank = 20 + [double]$n + 0.5 } }
  if ("$key" -match '^\d+(\.\d+)?$') { return @{ android = "API $key"; preview = $false; rank = [double]$key } }
  @{ android = "$key"; preview = $true; rank = 999 }
}

function Get-TagLabel($tag) {
  $l = switch -Wildcard ($tag) {
    'google_apis_playstore*' { 'Google Play'; break }
    'google_apis*'           { 'Google APIs'; break }
    default                  { $tag }
  }
  if ($tag -like '*ps16k') { $l += ', 16 KB pages' }
  $l
}

function Get-DevName($id) {
  if (-not $id) { return 'Custom' }
  (($id -split '_') | ForEach-Object {
    if ($_ -eq 'xl') { 'XL' } elseif ($_ -match '^\d') { $_ } else { $_.Substring(0, 1).ToUpper() + $_.Substring(1) }
  }) -join ' '
}

function Get-AvdName($dirInfo) { $dirInfo.Name -replace '\.avd$', '' }

# // © https://saadbinyousaf.dev/ © //
function Repair-Avds {
  Get-ChildItem $AvdHome -Filter '*.avd.ini' -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
  foreach ($d in Get-ChildItem $AvdHome -Directory -Filter '*.avd' -ErrorAction SilentlyContinue) {
    $name = Get-AvdName $d
    $c = Read-Ini "$($d.FullName)\config.ini"
    $key = '34'
    if ($c['image.sysdir.1'] -match 'android-([^\\/]+)') { $key = $matches[1] }
    Set-Content -Path (Join-Path $AvdHome "$name.ini") -Encoding ASCII -Value @(
      'avd.ini.encoding=UTF-8', "path=$($d.FullName)", "path.rel=avd\$name.avd", "target=android-$key"
    )
  }
}

# // © https://saadbinyousaf.dev/ © //
function Get-Running {
  if ($script:RunCache -and ((Get-Date) - $script:RunAt).TotalMilliseconds -lt 1200) { return $script:RunCache }
  $h = @{}
  $procs = Get-CimInstance Win32_Process -Filter "Name='emulator.exe' OR Name LIKE 'qemu-system-%'" -ErrorAction SilentlyContinue
  foreach ($p in $procs) {
    if ("$($p.CommandLine)" -match '-avd\s+"?([^"\s]+)') {
      $n = $matches[1]
      if (-not $h.ContainsKey($n)) { $h[$n] = @() }
      $h[$n] += [int]$p.ProcessId
    }
  }
  $script:RunCache = $h
  $script:RunAt = Get-Date
  $h
}

function Get-Serials {
  $out = @{}
  $lines = @(& $Adb devices 2>$null)
  $alive = @{}
  foreach ($l in $lines) {
    if ($l -match '^(emulator-\d+)\s+(\S+)') {
      $s = $matches[1]; $st = $matches[2]; $alive[$s] = $true
      if (-not $script:SerialName[$s] -and $st -eq 'device') {
        $n = "$(& $Adb -s $s emu avd name 2>$null | Select-Object -First 1)".Trim()
        if ($n -and $n -ne 'KO') { $script:SerialName[$s] = $n }
      }
      if ($script:SerialName[$s]) { $out[$script:SerialName[$s]] = @{ serial = $s; status = $st } }
    }
  }
  foreach ($k in @($script:SerialName.Keys)) { if (-not $alive[$k]) { $script:SerialName.Remove($k) } }
  $out
}

# // © https://saadbinyousaf.dev/ © //
function Get-Avds {
  $running = Get-Running
  $serials = @{}
  if ($running.Count -and (Test-Path $Adb)) { $serials = Get-Serials }
  foreach ($k in @($script:Booted.Keys)) { if (-not $running.ContainsKey($k)) { $script:Booted.Remove($k); $script:MagiskCheck.Remove($k) } }

  $list = @()
  foreach ($d in Get-ChildItem $AvdHome -Directory -Filter '*.avd' -ErrorAction SilentlyContinue | Sort-Object Name) {
    $name = Get-AvdName $d
    $c    = Read-Ini "$($d.FullName)\config.ini"
    $sys  = "$($c['image.sysdir.1'])".TrimEnd('\', '/')
    $key  = '?'; $tag = ''
    if ($sys -match 'android-([^\\/]+)[\\/]([^\\/]+)') { $key = $matches[1]; $tag = $matches[2] }
    $ver  = Get-AndroidOf $key

    $state = 'off'
    if ($running.ContainsKey($name)) {
      $state = 'booting'
      $sr = $serials[$name]
      if ($sr -and $sr.status -eq 'device') {
        if (-not $script:Booted[$name]) {
          $b = "$(& $Adb -s $sr.serial shell getprop sys.boot_completed 2>$null)".Trim()
          if ($b -eq '1') { $script:Booted[$name] = $true }
        }
        if ($script:Booted[$name]) {
          $state = 'on'
          if (-not $script:MagiskCheck[$name]) {
            $script:MagiskCheck[$name] = $true
            $mv = "$(& $Adb -s $sr.serial shell magisk -v 2>$null | Select-Object -First 1)".Trim()
            if ($mv -match '^([\d.]+)') { Set-Content -Path "$($d.FullName)\.magisk" -Value $matches[1] -Encoding ASCII }
          }
        }
      }
    }

    $magisk = $null
    if (Test-Path "$($d.FullName)\.magisk") { $magisk = "$(Get-Content "$($d.FullName)\.magisk" -TotalCount 1)".Trim() }
    $patched = [bool]($sys -and (Test-Path (Join-Path $Sdk "$sys\ramdisk.img.backup")))
    $rooted  = $patched -or [bool]$magisk -or (Test-Path "$($d.FullName)\.rooted")

    $ram = "$($c['hw.ramSize'])" -replace '[^\d]', ''
    $sto = "$($c['disk.dataPartition.size'])"
    $stoGb = $null
    if ($sto -match '^(\d+)G$') { $stoGb = [int]$matches[1] }
    elseif ($sto -match '^(\d+)M$') { $stoGb = [math]::Round([int]$matches[1] / 1024) }
    elseif ($sto -match '^\d+$') { $stoGb = [math]::Round([double]$sto / 1GB) }

    $list += @{
      name     = $name
      key      = $key
      android  = $ver.android
      preview  = $ver.preview
      device   = Get-DevName $c['hw.device.name']
      deviceId = "$($c['hw.device.name'])"
      tag      = $tag
      image    = Get-TagLabel $tag
      ramMb    = $(if ($ram) { [int]$ram } else { $null })
      storageGb= $stoGb
      rooted   = $rooted
      magisk   = $magisk
      state    = $state
      stopping = $script:PendingStop.ContainsKey($name)
    }
  }
  ,$list
}

# // © https://saadbinyousaf.dev/ © //
function Start-Avd($name, [bool]$cold) {
  if (-not (Test-Path $Emu)) { throw 'The emulator is missing. Finish setup first.' }
  if ((Get-Running).ContainsKey($name)) { throw "$name is already running." }
  Repair-Avds
  $psi = New-Object System.Diagnostics.ProcessStartInfo $Emu
  $psi.Arguments        = "-avd $name" + $(if ($cold) { ' -no-snapshot-load' } else { '' })
  $psi.UseShellExecute  = $false
  $psi.CreateNoWindow   = $true
  $psi.WorkingDirectory = Split-Path $Emu
  [Diagnostics.Process]::Start($psi) | Out-Null
  $script:RunCache = $null
}

function Stop-Avd($name) {
  $serials = Get-Serials
  if ($serials[$name]) { & $Adb -s $serials[$name].serial emu kill 2>$null | Out-Null }
  $script:PendingStop[$name] = Get-Date
  $script:RunCache = $null
}

function Invoke-PendingStops {
  if (-not $script:PendingStop.Count) { return }
  $running = Get-Running
  foreach ($n in @($script:PendingStop.Keys)) {
    if (-not $running.ContainsKey($n)) { $script:PendingStop.Remove($n); continue }
    if (((Get-Date) - $script:PendingStop[$n]).TotalSeconds -gt 8) {
      foreach ($procId in $running[$n]) { Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue }
      $script:RunCache = $null
    }
  }
}

# // © https://saadbinyousaf.dev/ © //
function Get-InstalledImages {
  $h = @{}
  foreach ($a in Get-ChildItem "$Sdk\system-images" -Directory -ErrorAction SilentlyContinue) {
    if ($a.Name -notmatch '^android-(.+)$') { continue }
    $key = $matches[1]
    foreach ($t in Get-ChildItem $a.FullName -Directory -ErrorAction SilentlyContinue) {
      if (Test-Path "$($t.FullName)\x86_64\source.properties") {
        if (-not $h.ContainsKey($key)) { $h[$key] = @() }
        $h[$key] += $t.Name
      }
    }
  }
  $h
}

function Get-Versions {
  $remote = @{}
  if (Test-Path "$UiDir\versions.json") {
    try {
      $j = Get-Content "$UiDir\versions.json" -Raw | ConvertFrom-Json
      foreach ($p in $j.PSObject.Properties) { $remote[$p.Name] = @($p.Value | ForEach-Object { "$_" }) }
    } catch {}
  }
  if (-not $remote.Count) {
    foreach ($k in '30', '31', '32', '33', '34', '35', '36') { $remote[$k] = @('google_apis_playstore', 'google_apis') }
  }
  $inst = Get-InstalledImages
  $keys = @($remote.Keys) + @($inst.Keys) | Select-Object -Unique
  $items = @()
  foreach ($k in $keys) {
    $v = Get-AndroidOf $k
    $tags = @(@($remote[$k]) + @($inst[$k]) | Where-Object { $_ -like 'google_apis*' } | Select-Object -Unique)
    if (-not $tags.Count) { continue }
    $tags = @($tags | Sort-Object { if ($_ -eq 'google_apis_playstore') { 0 } elseif ($_ -eq 'google_apis') { 1 } elseif ($_ -like '*playstore*') { 2 } else { 3 } })
    $items += @{
      key       = $k
      android   = $v.android
      preview   = $v.preview
      rank      = $v.rank
      tags      = @($tags | ForEach-Object { @{ id = $_; label = Get-TagLabel $_ } })
      installed = @($inst[$k] | Where-Object { $_ })
    }
  }
  ,@($items | Sort-Object { $_.rank } -Descending)
}

function Start-VersionJob {
  if ($script:VerJob -or -not (Test-Path $SdkMgr)) { return }
  $script:VerJob = Start-Job -ArgumentList $SdkMgr, $Jdk, $Sdk -ScriptBlock {
    param($m, $j, $s)
    $env:JAVA_HOME = $j; $env:ANDROID_HOME = $s; $env:ANDROID_SDK_ROOT = $s
    & $m --list --channel=3 2>$null
  }
}

function Start-DeviceJob {
  if ($script:DevJob -or -not (Test-Path $AvdMgr)) { return }
  $script:DevJob = Start-Job -ArgumentList $AvdMgr, $Jdk, $Sdk -ScriptBlock {
    param($m, $j, $s)
    $env:JAVA_HOME = $j; $env:ANDROID_HOME = $s; $env:ANDROID_SDK_ROOT = $s
    & $m list device -c 2>$null
  }
}

function Start-HealthCheck {
  if (-not ((Test-Path $Emu) -and (Test-Path "$UiDir\setup.done"))) { return }
  foreach ($kv in @(@('ANDROID_HOME', $Sdk), @('ANDROID_SDK_ROOT', $Sdk), @('ANDROID_AVD_HOME', $AvdHome), @('ANDROID_USER_HOME', $UserHome))) {
    if ([Environment]::GetEnvironmentVariable($kv[0], 'User') -ne $kv[1]) { [Environment]::SetEnvironmentVariable($kv[0], $kv[1], 'User') }
  }
  if (Test-Path "$UiDir\reboot.flag") { return }
  $script:AccelJob = Start-Job -ArgumentList $Emu -ScriptBlock { param($e) & $e -accel-check 2>&1 | Out-String }
}

function Invoke-Jobs {
  if ($script:AccelJob -and $script:AccelJob.State -ne 'Running') {
    $out = "$(Receive-Job $script:AccelJob -ErrorAction SilentlyContinue)"
    Remove-Job $script:AccelJob -Force; $script:AccelJob = $null
    if ($out -and $out -notmatch 'usable') { Set-Content -Path "$UiDir\accel.missing" -Value $out.Trim() -Encoding ASCII }
    else { Remove-Item "$UiDir\accel.missing" -Force -ErrorAction SilentlyContinue }
  }
  if ($script:VerJob -and $script:VerJob.State -ne 'Running') {
    $found = @{}
    foreach ($l in Receive-Job $script:VerJob -ErrorAction SilentlyContinue) {
      if ("$l" -match '^\s*system-images;android-([A-Za-z0-9.]+);(google_apis[a-z0-9_]*);x86_64\s') {
        if (-not $found.ContainsKey($matches[1])) { $found[$matches[1]] = @() }
        if ($found[$matches[1]] -notcontains $matches[2]) { $found[$matches[1]] += $matches[2] }
      }
    }
    Remove-Job $script:VerJob -Force; $script:VerJob = $null
    if ($found.Count) { $found | ConvertTo-Json -Depth 4 | Set-Content "$UiDir\versions.json" -Encoding UTF8 }
    $script:VerResult = $(if ($found.Count) { 'ok' } else { 'failed' })
  }
  if ($script:DevJob -and $script:DevJob.State -ne 'Running') {
    $ids = @(Receive-Job $script:DevJob -ErrorAction SilentlyContinue | ForEach-Object { "$_".Trim() } |
      Where-Object { $_ -match '^[a-z0-9_]+$' -and $_ -notmatch '^(automotive|wear|tv_|android_tv|desktop|xr|google_tv)' })
    Remove-Job $script:DevJob -Force; $script:DevJob = $null
    if ($ids.Count) { ConvertTo-Json -InputObject $ids | Set-Content "$UiDir\devices.json" -Encoding UTF8 }
  }
}

function Get-Devices {
  if (-not (Test-Path "$UiDir\devices.json") -and -not $script:DevJob) { Start-DeviceJob }
  $ids = $DefaultDevices
  if (Test-Path "$UiDir\devices.json") { try { $ids = @((Get-Content "$UiDir\devices.json" -Raw | ConvertFrom-Json) | ForEach-Object { "$_" } | Where-Object { $_ -match '^[A-Za-z0-9_.-]+$' }) } catch {}
  if (-not $ids.Count) { $ids = $DefaultDevices } }
  $pix = @($ids | Where-Object { $_ -like 'pixel*' } | Sort-Object -Descending)
  $oth = @($ids | Where-Object { $_ -notlike 'pixel*' })
  ,@(@($pix) + @($oth) | ForEach-Object { @{ id = $_; name = Get-DevName $_ } })
}

# // © https://saadbinyousaf.dev/ © //
function Select-MagiskApk($assets) {
  $apks = @($assets | Where-Object { $_.name -like '*.apk' -and $_.name -notmatch 'debug' })
  $pick = $apks | Where-Object { $_.name -match '^Magisk-v?[\d.]+.*\.apk$' } | Select-Object -First 1
  if (-not $pick) { $pick = $apks | Where-Object { $_.name -match 'release' } | Select-Object -First 1 }
  if (-not $pick) { $pick = $apks | Sort-Object size | Select-Object -First 1 }
  $pick
}

function Get-MagiskList([bool]$force) {
  if (-not $force -and $script:MagiskCache -and ((Get-Date) - $script:MagiskAt).TotalMinutes -lt 15) { return ,$script:MagiskCache }
  $items = @()
  $hdr = @{ 'User-Agent' = 'Droidesk' }
  try {
    $rels = Invoke-RestMethod 'https://api.github.com/repos/topjohnwu/Magisk/releases?per_page=15' -Headers $hdr -TimeoutSec 10
    foreach ($r in $rels) {
      $apk = Select-MagiskApk $r.assets
      if (-not $apk) { continue }
      $items += @{
        version = ("$($r.tag_name)" -replace '^v', '')
        channel = $(if ($r.prerelease) { 'Beta' } else { 'Stable' })
        date    = "$($r.published_at)".Substring(0, [math]::Min(10, "$($r.published_at)".Length))
        url     = "$($apk.browser_download_url)"
        sizeMb  = [math]::Round([double]$apk.size / 1MB, 1)
      }
    }
  } catch {}
  try {
    $c = Invoke-RestMethod 'https://raw.githubusercontent.com/topjohnwu/magisk-files/master/canary.json' -Headers $hdr -TimeoutSec 10
    $link = "$($c.magisk.link)"
    if ($link -and $link -notmatch 'debug' -and -not ($items | Where-Object { $_.url -eq $link })) {
      $items = @(@{ version = "$($c.magisk.version)"; channel = 'Canary'; date = ''; url = $link; sizeMb = $null }) + $items
    }
  } catch {}
  if ($items.Count) { $script:MagiskCache = $items; $script:MagiskAt = Get-Date }
  ,$items
}

# // © https://saadbinyousaf.dev/ © //
function Read-Tail($path, [int]$bytes = 48000) {
  if (-not (Test-Path $path)) { return '' }
  try {
    $fs = [IO.File]::Open($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
    $start = [math]::Max(0, $fs.Length - $bytes)
    [void]$fs.Seek($start, [IO.SeekOrigin]::Begin)
    $buf = New-Object byte[] ($fs.Length - $start)
    [void]$fs.Read($buf, 0, $buf.Length)
    $fs.Close()
    [Text.Encoding]::UTF8.GetString($buf)
  } catch { '' }
}

function Get-LogLines {
  $txt = (Read-Tail "$UiDir\task.log") + "`n" + (Read-Tail "$UiDir\task.live")
  $out = New-Object System.Collections.Generic.List[string]
  $bar = '^\s*\[[=\s>#.-]*\]'
  foreach ($l in ($txt -split "`r`n|`n|`r")) {
    $l = $l.TrimEnd().TrimStart([char]0xFEFF)
    if (-not $l) { continue }
    if ($l.Length -gt 220) { $l = $l.Substring(0, 220) }
    if ($l -match $bar -and $out.Count -and $out[$out.Count - 1] -match $bar) { $out[$out.Count - 1] = $l } else { $out.Add($l) }
  }
  ,@($out | Select-Object -Last 90)
}

function Test-TaskAlive($t) {
  if (-not $t -or -not $t.pid) { return $false }
  $p = Get-Process -Id ([int]$t.pid) -ErrorAction SilentlyContinue
  [bool]($p -and $p.ProcessName -like 'powershell*')
}

function Read-TaskFile {
  if (Test-Path $TaskFile) { try { return (Get-Content $TaskFile -Raw | ConvertFrom-Json) } catch {} }
  $null
}

function Get-Task {
  $t = Read-TaskFile
  if (-not $t) {
    if ($script:TaskProc -and -not $script:TaskProc.HasExited) {
      return [pscustomobject]@{ label = 'Starting'; steps = @(); current = 0; state = 'running'; message = ''; log = @() }
    }
    return $null
  }
  if ($t.state -eq 'running' -and -not (Test-TaskAlive $t) -and ((Get-Date) - [datetime]$t.ts).TotalSeconds -gt 4) {
    $t.state = 'failed'
    $t.message = 'The task stopped unexpectedly. Press Retry.'
  }
  $t | Add-Member -NotePropertyName log -NotePropertyValue (Get-LogLines) -Force
  $t
}

function Start-Task([string]$argLine) {
  $t = Read-TaskFile
  if (($t -and $t.state -eq 'running' -and (Test-TaskAlive $t)) -or ($script:TaskProc -and -not $script:TaskProc.HasExited)) { throw 'Another task is still running.' }
  Remove-Item $TaskFile, "$UiDir\task.log", "$UiDir\task.live" -Force -ErrorAction SilentlyContinue
  Set-Content -Path "$UiDir\task.args" -Value $argLine -Encoding UTF8
  $psi = New-Object System.Diagnostics.ProcessStartInfo "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
  $psi.Arguments        = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$Core\tasks.ps1`" $argLine"
  $psi.UseShellExecute  = $false
  $psi.CreateNoWindow   = $true
  $psi.WorkingDirectory = $Core
  $script:TaskProc = [Diagnostics.Process]::Start($psi)
}

function Stop-Task {
  $t = Read-TaskFile
  if ($t -and $t.pid) { & taskkill.exe /T /F /PID ([int]$t.pid) 2>$null | Out-Null }
  if ($script:TaskProc -and -not $script:TaskProc.HasExited) { & taskkill.exe /T /F /PID $script:TaskProc.Id 2>$null | Out-Null }
  if ($t) {
    $t.state = 'failed'; $t.message = 'Cancelled.'
    $t | ConvertTo-Json -Depth 5 | Set-Content -Path $TaskFile -Encoding UTF8
  }
  Add-Content -Path "$UiDir\task.log" -Value "`nERROR  Cancelled." -Encoding UTF8 -ErrorAction SilentlyContinue
  $script:RunCache = $null
}

# // © https://saadbinyousaf.dev/ © //
function Get-SetupState {
  $tools = (Test-Path $Emu) -and (Test-Path $SdkMgr) -and (Test-Path "$Jdk\bin\java.exe") -and (Test-Path $Adb)
  if ($tools -and -not (Test-Path "$UiDir\setup.done")) { Set-Content -Path "$UiDir\setup.done" -Value (Get-Date).ToString('o') -Encoding ASCII }
  $flag = "$UiDir\reboot.flag"
  if (Test-Path $flag) {
    try {
      $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
      if ($boot -gt (Get-Item $flag).LastWriteTime) { Remove-Item $flag -Force }
    } catch {}
  }
  @{ done = [bool]($tools -and (Test-Path "$UiDir\setup.done") -and -not (Test-Path "$UiDir\accel.missing")); reboot = (Test-Path $flag) }
}

# // © https://saadbinyousaf.dev/ © //
function Move-OldLayout {
  if (@(Get-Process -Name 'qemu-system-*', 'emulator' -ErrorAction SilentlyContinue).Count) { return }
  foreach ($n in 'sdk', 'avd', 'jdk', '.android', '.ui', 'webview2', 'rootAVD') {
    $old = Join-Path $Root $n
    $new = Join-Path $Data $n
    if ((Test-Path $old) -and -not (Test-Path $new)) {
      New-Item -ItemType Directory -Force -Path $Data | Out-Null
      try { Move-Item -Path $old -Destination $new -Force -ErrorAction Stop } catch {}
    }
  }
  foreach ($f in 'server.ps1', 'tasks.ps1', 'setup.ps1', 'setup.bat', 'update.bat', 'launch.bat', 'launcher.ps1', 'Android Vault.bat', 'DroidKeep.bat') {
    Remove-Item (Join-Path $Root $f) -Force -ErrorAction SilentlyContinue
  }
  Remove-Item (Join-Path $Core 'setup.ps1'), (Join-Path $Core 'setup.bat') -Force -ErrorAction SilentlyContinue
  foreach ($d in 'app', '_tmp', 'docs') { Remove-Item (Join-Path $Root $d) -Recurse -Force -ErrorAction SilentlyContinue }
}

function Assert-Name($n) {
  if ("$n" -notmatch '^[A-Za-z0-9._-]+$') { throw 'Names can use letters, numbers, dot, dash and underscore.' }
}

# // © https://saadbinyousaf.dev/ © //
function Send($ctx, [int]$code, $obj, [string]$type = 'application/json') {
  $r = $ctx.Response
  $r.StatusCode = $code
  if ($obj -is [byte[]]) { $bytes = $obj }
  elseif ($type -eq 'application/json') { $bytes = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $obj -Depth 8 -Compress)) }
  else { $bytes = [Text.Encoding]::UTF8.GetBytes([string]$obj) }
  $r.ContentType = "$type; charset=utf-8"
  $r.Headers['Cache-Control'] = 'no-store'
  $r.ContentLength64 = $bytes.Length
  $r.OutputStream.Write($bytes, 0, $bytes.Length)
  $r.Close()
}

function Read-Body($ctx) {
  if (-not $ctx.Request.HasEntityBody) { return $null }
  $sr = New-Object IO.StreamReader($ctx.Request.InputStream, [Text.Encoding]::UTF8)
  $txt = $sr.ReadToEnd(); $sr.Close()
  if ($txt) { $txt | ConvertFrom-Json } else { $null }
}

# // © https://saadbinyousaf.dev/ © //
function Invoke-Route($ctx) {
  $path = $ctx.Request.Url.AbsolutePath
  if ($path -eq '/' -or $path -eq '/index.html') {
    Send $ctx 200 ([IO.File]::ReadAllBytes("$AppDir\index.html")) 'text/html'; return
  }
  if ($path -eq '/logo.svg') { Send $ctx 200 ([IO.File]::ReadAllBytes("$AppDir\logo.svg")) 'image/svg+xml'; return }
  if ($path -eq '/icon.ico') { Send $ctx 200 ([IO.File]::ReadAllBytes("$AppDir\icon.ico")) 'image/x-icon'; return }
  if ($path -notlike '/api/*') { Send $ctx 404 @{ error = 'Not found' }; return }
  if ($ctx.Request.Headers['X-Vault'] -ne $script:Token) { Send $ctx 403 @{ error = 'Forbidden' }; return }
  $script:LastSeen = Get-Date
  $b = Read-Body $ctx

  switch ($path) {
    '/api/ping'   { Send $ctx 200 @{ ok = $true } }
    '/api/focus'  { $script:FocusReq = $true; Send $ctx 200 @{ ok = $true; hosted = [bool]$script:Hosted } }
    '/api/state'  {
      Send $ctx 200 @{
        avds   = Get-Avds
        task   = Get-Task
        ready   = (Test-Path $Emu) -and (Test-Path $SdkMgr)
        setup   = Get-SetupState
        root    = $Root
        app     = $AppName
        version = $AppVersion
        site    = $SiteUrl
        repo    = $RepoUrl
      }
    }
    '/api/start'  { Assert-Name $b.name; Start-Avd $b.name ([bool]$b.cold); Send $ctx 200 @{ ok = $true } }
    '/api/stop'   { Assert-Name $b.name; Stop-Avd $b.name; Send $ctx 200 @{ ok = $true } }
    '/api/folder' { Assert-Name $b.name; Start-Process explorer.exe (Join-Path $AvdHome "$($b.name).avd"); Send $ctx 200 @{ ok = $true } }
    '/api/delete' {
      Assert-Name $b.name
      if ((Get-Running).ContainsKey($b.name)) { throw 'Stop the device before deleting it.' }
      Remove-Item (Join-Path $AvdHome "$($b.name).avd") -Recurse -Force
      Remove-Item (Join-Path $AvdHome "$($b.name).ini") -Force -ErrorAction SilentlyContinue
      Send $ctx 200 @{ ok = $true }
    }
    '/api/versions' {
      if ($ctx.Request.QueryString['refresh'] -eq '1') { $script:VerResult = $null; Start-VersionJob }
      Send $ctx 200 @{ loading = [bool]$script:VerJob; result = $script:VerResult; items = Get-Versions }
    }
    '/api/devices' { Send $ctx 200 @{ items = Get-Devices } }
    '/api/magisk'  { Send $ctx 200 @{ items = (Get-MagiskList ($ctx.Request.QueryString['refresh'] -eq '1')) } }
    '/api/root' {
      Assert-Name $b.name
      if ((Get-Running).Count) { throw 'Close every running device first. Rooting boots this one on its own.' }
      Start-Task ("-Action Root -Name `"$($b.name)`" -MagiskUrl `"$($b.url)`" -MagiskVer `"$($b.version)`"")
      Send $ctx 200 @{ ok = $true }
    }
    '/api/create' {
      Assert-Name $b.name
      if (Test-Path (Join-Path $AvdHome "$($b.name).avd")) { throw "A device called $($b.name) already exists." }
      if ("$($b.key)" -notmatch '^[A-Za-z0-9.]+$' -or "$($b.tag)" -notmatch '^[a-z0-9_]+$' -or "$($b.device)" -notmatch '^[A-Za-z0-9_.-]+$') { throw 'Invalid device settings.' }
      if ($b.root -and (Get-Running).Count) { throw 'Close every running device first, or turn off rooting.' }
      $a = "-Action Create -Name `"$($b.name)`" -Api $($b.key) -Tag $($b.tag) -Device $($b.device) -Ram $([int]$b.ram) -Data $([int]$b.storage)"
      if ($b.root) { $a += " -Root -MagiskUrl `"$($b.url)`" -MagiskVer `"$($b.version)`"" }
      Start-Task $a
      Send $ctx 200 @{ ok = $true }
    }
    '/api/openroot' { Start-Process explorer.exe $Root; Send $ctx 200 @{ ok = $true } }
    '/api/open'   { Open-External $b.url; Send $ctx 200 @{ ok = $true } }
    '/api/update' {
      if ((Get-Running).Count) { throw 'Stop every device first, then update.' }
      Start-Task '-Action Update'
      Send $ctx 200 @{ ok = $true }
    }
    '/api/setup'  { Start-Task '-Action Setup'; Send $ctx 200 @{ ok = $true } }
    '/api/cancel' { Stop-Task; Send $ctx 200 @{ ok = $true } }
    '/api/retry'  {
      $a = ''
      if (Test-Path "$UiDir\task.args") { $a = "$(Get-Content "$UiDir\task.args" -Raw)".Trim() }
      if (-not $a) { throw 'Nothing to retry.' }
      Start-Task $a
      Send $ctx 200 @{ ok = $true }
    }
    '/api/restart' { Start-Process -FilePath shutdown.exe -ArgumentList '/r', '/t', '5' -WindowStyle Hidden; Send $ctx 200 @{ ok = $true } }
    '/api/dismiss' { Remove-Item $TaskFile, "$UiDir\task.log", "$UiDir\task.live" -Force -ErrorAction SilentlyContinue; Send $ctx 200 @{ ok = $true } }
    default { Send $ctx 404 @{ error = 'Unknown endpoint' } }
  }
}

# // © https://saadbinyousaf.dev/ © //
$listener = $null
for ($i = 0; $i -lt 20 -and -not $listener; $i++) {
  $port = Get-Random -Minimum 41000 -Maximum 49000
  try {
    $l = New-Object Net.HttpListener
    $l.Prefixes.Add("http://localhost:$port/")
    $l.Start()
    $listener = $l
  } catch { $listener = $null }
}
if (-not $listener) { exit 1 }

$script:Token = [guid]::NewGuid().ToString('N')
Move-OldLayout
New-Item -ItemType Directory -Force -Path $AvdHome, $UserHome, $UiDir | Out-Null
@{ port = $port; token = $script:Token; pid = $PID } | ConvertTo-Json | Set-Content $InfoFile -Encoding ASCII
Remove-Item "$UiDir\edge" -Recurse -Force -ErrorAction SilentlyContinue
Repair-Avds
Set-Shortcut
Start-DeviceJob
Start-HealthCheck
$script:Hosted = $false
$script:WvFailed = $false
$url = "http://localhost:$port/#$($script:Token)"

# // © https://saadbinyousaf.dev/ © //
try {
  $ok = Show-Window $url
  if (-not $ok) {
    Open-App $port $script:Token
    $script:LastSeen = (Get-Date).AddSeconds(60)
    while ($listener.IsListening) {
      $ar = $(if ($script:Ar) { $script:Ar } else { $listener.BeginGetContext($null, $null) })
      $script:Ar = $null
      while (-not $ar.AsyncWaitHandle.WaitOne(500)) {
        try { Invoke-PendingStops; Invoke-Jobs } catch {}
        if (((Get-Date) - $script:LastSeen).TotalSeconds -gt 180) { $listener.Stop(); break }
      }
      if (-not $listener.IsListening) { break }
      $ctx = $listener.EndGetContext($ar)
      try { Invoke-Route $ctx } catch { try { Send $ctx 400 @{ error = $_.Exception.Message } } catch {} }
    }
  }
} finally {
  try { $listener.Stop() } catch {}
  Remove-Item $InfoFile -Force -ErrorAction SilentlyContinue
  Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
}
# // © https://saadbinyousaf.dev/ © //
