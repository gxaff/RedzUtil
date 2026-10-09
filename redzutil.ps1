<#
.SYNOPSIS
    RedzUtil v1.1 - Windows Toolbox (Fixed)

.USAGE
    Save as redzutil.ps1
    Run as Admin:
        cd $env:USERPROFILE\Desktop
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
        .\redzutil.ps1
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = 'Continue'

$script:LogPath = "$env:USERPROFILE\Desktop\RedzUtil_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$script:SelectedApps = New-Object System.Collections.ArrayList
$script:SelectedTweaks = New-Object System.Collections.ArrayList

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $line = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $script:LogPath -Value $line
    $color = switch ($Level) {
        'OK'    { 'Green'  }
        'WARN'  { 'Yellow' }
        'ERROR' { 'Red'    }
        default { 'Gray'   }
    }
    Write-Host $line -ForegroundColor $color
}

function New-RestorePoint {
    Write-Log "Creating restore point..."
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" `
            -Name SystemRestorePointCreationFrequency -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "RedzUtil $(Get-Date -Format 'yyyy-MM-dd HH:mm')" `
            -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Log "Restore point created" 'OK'
    } catch {
        Write-Log "Restore point skipped - $($_.Exception.Message)" 'WARN'
    }
}

# ═══════════════════════════════════════════════════════════
#  TWEAK ENGINE v1.1 — تسجيل صحيح
# ═══════════════════════════════════════════════════════════

function Invoke-Tweak {
    param([string]$Name)
    Write-Log "Applying: $Name"

    $success = $false
    $errorMsg = ""

    try {
        switch ($Name) {
            "Disable Telemetry" {
                $p1 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
                if (-not (Test-Path $p1)) { New-Item $p1 -Force | Out-Null }
                Set-ItemProperty $p1 -Name AllowTelemetry -Value 0 -Type DWord -Force

                $p2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
                if (-not (Test-Path $p2)) { New-Item $p2 -Force | Out-Null }
                Set-ItemProperty $p2 -Name AllowTelemetry -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Activity History" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name EnableActivityFeed -Value 0 -Type DWord -Force
                Set-ItemProperty $p -Name PublishUserActivities -Value 0 -Type DWord -Force
                Set-ItemProperty $p -Name UploadUserActivities -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Location Tracking" {
                $p = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name Value -Value "Deny" -Type String -Force
                Set-ItemProperty "HKLM:\SYSTEM\Maps" -Name AutoUpdateEnabled -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Advertising ID" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name Enabled -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Consumer Features" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name DisableWindowsConsumerFeatures -Value 1 -Type DWord -Force
                Set-ItemProperty $p -Name DisableSoftLanding -Value 1 -Type DWord -Force
                $success = $true
            }
            "Disable WPBT" {
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" `
                    -Name DisableWpbtExecution -Value 1 -Type DWord -Force
                $success = $true
            }
            "Disable Delivery Optimization" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name DODownloadMode -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable SysMain" {
                try { Set-Service -Name SysMain -StartupType Disabled -ErrorAction Stop; $success = $true } catch { $errorMsg = $_.Exception.Message }
            }
            "Disable Hibernation" {
                try { powercfg /hibernate off; $success = $true } catch { $errorMsg = $_.Exception.Message }
            }
            "Enable GPU Scheduling" {
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
                    -Name HwSchMode -Value 2 -Type DWord -Force
                $success = $true
            }
            "Enable End Task on Taskbar" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
                if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
                Set-ItemProperty $p -Name TaskbarEndTask -Value 1 -Type DWord -Force
                $success = $true
            }
            "Show File Extensions" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                    -Name HideFileExt -Value 0 -Type DWord -Force
                $success = $true
            }
            "Show Hidden Files" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                    -Name Hidden -Value 1 -Type DWord -Force
                $success = $true
            }
            "Dark Mode" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
                Set-ItemProperty $p -Name AppsUseLightTheme -Value 0 -Type DWord -Force
                Set-ItemProperty $p -Name SystemUsesLightTheme -Value 0 -Type DWord -Force
                $success = $true
            }
            "Enable Long Paths" {
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
                    -Name LongPathsEnabled -Value 1 -Type DWord -Force
                $success = $true
            }
            "Disable Widgets" {
                # v1.1 FIX: طريقة متعددة المستويات
                # محاولة 1: reg add (يتجاوز PowerShell permissions)
                $regResult = reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                    /v TaskbarDa /t REG_DWORD /d 0 /f 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    $success = $true
                } else {
                    # محاولة 2: إعادة تشغيل Explorer ثم المحاولة
                    try {
                        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
                        Start-Sleep -Seconds 2
                        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                            -Name TaskbarDa -Value 0 -Type DWord -Force -ErrorAction Stop
                        Start-Process explorer
                        $success = $true
                    } catch {
                        $errorMsg = $_.Exception.Message
                    }
                }
            }
            "Disable Start Recommendations" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                    -Name Start_IrisRecommendations -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Xbox Services" {
                $anySuccess = $false
                foreach ($s in 'XblAuthManager','XblGameSave','XboxNetApiSvc') {
                    try { Set-Service -Name $s -StartupType Disabled -ErrorAction Stop; $anySuccess = $true } catch {}
                }
                $success = $anySuccess
            }
            "Disable Remote Registry" {
                try { Set-Service -Name RemoteRegistry -StartupType Disabled -ErrorAction Stop; $success = $true } catch { $errorMsg = $_.Exception.Message }
            }
            "Disk Cleanup" {
                try { Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -NoNewWindow; $success = $true } catch { $errorMsg = $_.Exception.Message }
            }
            "Delete Temp Files" {
                foreach ($p in "$env:TEMP\*","$env:WINDIR\Temp\*","$env:LOCALAPPDATA\Temp\*") {
                    try { Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue } catch {}
                }
                $success = $true
            }
            "Empty Recycle Bin" {
                try { Clear-RecycleBin -Force -ErrorAction Stop; $success = $true } catch { $errorMsg = $_.Exception.Message }
            }
            default {
                Write-Log "Unknown tweak: $Name" 'WARN'
            }
        }

        # تسجيل النتيجة الصحيحة
        if ($success) {
            Write-Log "OK: $Name" 'OK'
        } else {
            Write-Log "FAILED: $Name - $errorMsg" 'ERROR'
        }
    } catch {
        Write-Log "FAILED: $Name - $($_.Exception.Message)" 'ERROR'
    }
}

# ═══════════════════════════════════════════════════════════
#  APPS
# ═══════════════════════════════════════════════════════════

$script:AppMap = @{
    "Chrome"        = "Google.Chrome"
    "Firefox"       = "Mozilla.Firefox"
    "Brave"         = "Brave.Brave"
    "Discord"       = "Discord.Discord"
    "Telegram"      = "Telegram.TelegramDesktop"
    "WhatsApp"      = "WhatsApp.WhatsApp"
    "Zoom"          = "Zoom.Zoom"
    "Slack"         = "SlackTechnologies.Slack"
    "Signal"        = "OpenWhisperSystems.Signal"
    "VS Code"       = "Microsoft.VisualStudioCode"
    "Git"           = "Git.Git"
    "Docker"        = "Docker.DockerDesktop"
    "Node.js LTS"   = "OpenJS.NodeJS.LTS"
    "Python 3.12"   = "Python.Python.3.12"
    "7-Zip"         = "7zip.7zip"
    "VLC"           = "VideoLAN.VLC"
    "Notepad++"     = "Notepad++.Notepad++"
    "PowerToys"     = "Microsoft.PowerToys"
    "Steam"         = "Valve.Steam"
    "Everything"    = "voidtools.Everything"
}

function Install-App {
    param([string]$WingetId)
    Write-Log "Installing: $WingetId"
    try {
        winget install --id $WingetId --silent `
            --accept-package-agreements --accept-source-agreements `
            --disable-interactivity 2>&1 | Out-Null
        Write-Log "Installed: $WingetId" 'OK'
    } catch {
        Write-Log "Install failed: $WingetId - $($_.Exception.Message)" 'ERROR'
    }
}

# ═══════════════════════════════════════════════════════════
#  DNS
# ═══════════════════════════════════════════════════════════

function Set-DNS {
    param([string]$Provider)
    $map = @{
        "Cloudflare" = @("1.1.1.1","1.0.0.1")
        "Google"     = @("8.8.8.8","8.8.4.4")
        "Quad9"      = @("9.9.9.9","149.112.112.112")
        "OpenDNS"    = @("208.67.222.222","208.67.220.220")
        "AdGuard"    = @("94.140.14.14","94.140.15.15")
    }
    if ($Provider -eq "Default") {
        Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {
            Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses
        }
        Write-Log "DNS: Default (DHCP)" 'OK'
        return
    }
    if ($map.ContainsKey($Provider)) {
        Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {
            Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses $map[$Provider]
        }
        Write-Log "DNS: $Provider" 'OK'
    }
}

# ═══════════════════════════════════════════════════════════
#  WPF GUI
# ═══════════════════════════════════════════════════════════

Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="RedzUtil v1.1 - Windows Toolbox"
        Height="750" Width="1100"
        WindowStartupLocation="CenterScreen"
        Background="#141414" Foreground="#e0e0e0">
  <Window.Resources>
    <Style TargetType="Button">
      <Setter Property="Background" Value="#252525"/>
      <Setter Property="Foreground" Value="#e0e0e0"/>
      <Setter Property="BorderBrush" Value="#444"/>
      <Setter Property="Padding" Value="10,6"/>
      <Setter Property="Margin" Value="3"/>
      <Setter Property="Cursor" Value="Hand"/>
    </Style>
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="#e0e0e0"/>
      <Setter Property="Margin" Value="6"/>
    </Style>
    <Style TargetType="TextBlock">
      <Setter Property="Foreground" Value="#e0e0e0"/>
    </Style>
    <Style TargetType="TabItem">
      <Setter Property="Background" Value="#252525"/>
      <Setter Property="Foreground" Value="#e0e0e0"/>
      <Setter Property="Padding" Value="20,10"/>
    </Style>
  </Window.Resources>
  <Grid>
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <TabControl x:Name="MainTabs" Grid.Row="1" Background="#141414" BorderBrush="#333">
      <TabItem Header="Install">
        <Grid Margin="15">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="220"/>
            <ColumnDefinition Width="*"/>
          </Grid.ColumnDefinitions>
          <StackPanel Grid.Column="0">
            <Button x:Name="BtnInstall" Content="INSTALL SELECTED" Height="45"
                    Background="#0a5a2a" Foreground="White" FontWeight="Bold"/>
            <Button x:Name="BtnClearApps" Content="Clear Selection"/>
            <TextBlock x:Name="LblAppCount" Text="Selected: 0" Margin="5,15,0,0"/>
          </StackPanel>
          <ScrollViewer Grid.Column="1" VerticalScrollBarVisibility="Auto">
            <StackPanel x:Name="AppsList"/>
          </ScrollViewer>
        </Grid>
      </TabItem>
      <TabItem Header="Tweaks">
        <Grid Margin="15">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>
          <StackPanel Orientation="Horizontal" Grid.Row="0">
            <Button x:Name="BtnStandard" Content="Standard Preset"/>
            <Button x:Name="BtnMinimal"  Content="Minimal Preset"/>
            <Button x:Name="BtnAdvanced" Content="Advanced Preset"/>
            <Button x:Name="BtnClearTweaks" Content="Clear"/>
          </StackPanel>
          <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel x:Name="TweaksList"/>
          </ScrollViewer>
          <Button x:Name="BtnRunTweaks" Grid.Row="2"
                  Content="RUN SELECTED TWEAKS" Height="50"
                  Background="#0a5a2a" Foreground="White" FontWeight="Bold"/>
        </Grid>
      </TabItem>
      <TabItem Header="Config">
        <Grid Margin="15">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="*"/>
          </Grid.ColumnDefinitions>
          <StackPanel Grid.Column="0">
            <TextBlock Text="DNS Provider" FontSize="18" FontWeight="Bold" Margin="0,0,0,10"/>
            <StackPanel x:Name="DnsList"/>
          </StackPanel>
          <StackPanel Grid.Column="1">
            <TextBlock Text="Fixes / Tools" FontSize="18" FontWeight="Bold" Margin="0,0,0,10"/>
            <Button x:Name="BtnNetReset" Content="Network Reset"/>
            <Button x:Name="BtnSfcScan"  Content="System File Check (SFC)"/>
            <Button x:Name="BtnDismRestore" Content="DISM Restore Health"/>
            <Button x:Name="BtnRestorePoint" Content="Create Restore Point"/>
            <TextBlock Text="Legacy Panels" FontSize="18" FontWeight="Bold" Margin="0,20,0,10"/>
            <Button x:Name="BtnControlPanel" Content="Control Panel"/>
            <Button x:Name="BtnProgramsFeatures" Content="Programs and Features"/>
            <Button x:Name="BtnNetworkConns" Content="Network Connections"/>
            <Button x:Name="BtnSystemInfo" Content="System Information"/>
          </StackPanel>
        </Grid>
      </TabItem>
      <TabItem Header="Updates">
        <StackPanel Margin="30">
          <TextBlock Text="Windows Update Control" FontSize="22" FontWeight="Bold"/>
          <TextBlock Text="Choose an update policy" Margin="0,10,0,20" Foreground="#aaa"/>
          <Button x:Name="BtnUpdRecommended" Content="Recommended (Defer 365 days)"
                  Height="50" HorizontalAlignment="Left" Width="400"/>
          <Button x:Name="BtnUpdDefault" Content="Windows Default"
                  Height="50" HorizontalAlignment="Left" Width="400"/>
          <Button x:Name="BtnUpdDisable" Content="Disable Updates (Not recommended)"
                  Height="50" HorizontalAlignment="Left" Width="400"
                  Foreground="#ff6666"/>
        </StackPanel>
      </TabItem>
    </TabControl>
    <Border Grid.Row="2" Background="#0a0a0a" BorderBrush="#333" BorderThickness="0,1,0,0">
      <Grid>
        <TextBlock x:Name="StatusText" Text="Ready" Margin="10,6" Foreground="#888"/>
        <TextBlock Text="RedzUtil v1.1" HorizontalAlignment="Right" Margin="10,6" Foreground="#888"/>
      </Grid>
    </Border>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$AppsList    = $window.FindName("AppsList")
$TweaksList  = $window.FindName("TweaksList")
$DnsList     = $window.FindName("DnsList")
$StatusText  = $window.FindName("StatusText")
$LblAppCount = $window.FindName("LblAppCount")

foreach ($appName in $script:AppMap.Keys | Sort-Object) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $appName
    $cb.Tag = $appName
    $cb.Add_Checked({
        [void]$script:SelectedApps.Add($this.Tag)
        $LblAppCount.Text = "Selected: $($script:SelectedApps.Count)"
    })
    $cb.Add_Unchecked({
        $script:SelectedApps.Remove($this.Tag) | Out-Null
        $LblAppCount.Text = "Selected: $($script:SelectedApps.Count)"
    })
    $AppsList.Children.Add($cb) | Out-Null
}

$tweakNames = @(
    "Disable Telemetry","Disable Activity History","Disable Location Tracking",
    "Disable Advertising ID","Disable Consumer Features","Disable WPBT",
    "Disable Delivery Optimization","Disable SysMain","Disable Hibernation",
    "Enable GPU Scheduling","Enable End Task on Taskbar","Show File Extensions",
    "Show Hidden Files","Dark Mode","Enable Long Paths","Disable Widgets",
    "Disable Start Recommendations","Disable Xbox Services","Disable Remote Registry",
    "Disk Cleanup","Delete Temp Files","Empty Recycle Bin"
)
foreach ($t in $tweakNames) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $t
    $cb.Tag = $t
    $cb.Add_Checked({   [void]$script:SelectedTweaks.Add($this.Tag) })
    $cb.Add_Unchecked({ $script:SelectedTweaks.Remove($this.Tag) | Out-Null })
    $TweaksList.Children.Add($cb) | Out-Null
}

foreach ($dns in @("Cloudflare","Google","Quad9","OpenDNS","AdGuard","Default")) {
    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = $dns
    $btn.Tag = $dns
    $btn.Add_Click({
        Set-DNS -Provider $this.Tag
        $StatusText.Text = "DNS: $($this.Tag)"
    })
    $DnsList.Children.Add($btn) | Out-Null
}

$window.FindName("BtnInstall").Add_Click({
    if ($script:SelectedApps.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Select apps first")
        return
    }
    foreach ($app in $script:SelectedApps) {
        Install-App -WingetId $script:AppMap[$app]
    }
    $StatusText.Text = "Install done - check log"
})

$window.FindName("BtnClearApps").Add_Click({
    $script:SelectedApps.Clear()
    foreach ($child in $AppsList.Children) { $child.IsChecked = $false }
    $LblAppCount.Text = "Selected: 0"
})

$window.FindName("BtnStandard").Add_Click({
    $preset = @("Disable Telemetry","Disable Activity History","Disable Location Tracking",
                "Disable Advertising ID","Disable Consumer Features","Disable Delivery Optimization",
                "Disable SysMain","Enable End Task on Taskbar","Show File Extensions",
                "Show Hidden Files","Dark Mode","Disable Widgets","Disk Cleanup",
                "Delete Temp Files","Empty Recycle Bin")
    foreach ($child in $TweaksList.Children) {
        $child.IsChecked = $preset -contains $child.Tag
    }
})

$window.FindName("BtnMinimal").Add_Click({
    $preset = @("Disable Telemetry","Disable Advertising ID","Disk Cleanup","Empty Recycle Bin")
    foreach ($child in $TweaksList.Children) {
        $child.IsChecked = $preset -contains $child.Tag
    }
})

$window.FindName("BtnAdvanced").Add_Click({
    foreach ($child in $TweaksList.Children) { $child.IsChecked = $true }
})

$window.FindName("BtnClearTweaks").Add_Click({
    foreach ($child in $TweaksList.Children) { $child.IsChecked = $false }
    $script:SelectedTweaks.Clear()
})

$window.FindName("BtnRunTweaks").Add_Click({
    if ($script:SelectedTweaks.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Select tweaks first")
        return
    }
    New-RestorePoint
    $ok = 0; $fail = 0
    foreach ($t in $script:SelectedTweaks) {
        Invoke-Tweak -Name $t
    }
    [System.Windows.MessageBox]::Show("Done! Check log on Desktop")
    $StatusText.Text = "Tweaks applied - check log"
})

$window.FindName("BtnNetReset").Add_Click({
    Start-Process "netsh" -ArgumentList "int ip reset" -Wait -NoNewWindow
    $StatusText.Text = "Network reset"
})

$window.FindName("BtnSfcScan").Add_Click({
    Start-Process "sfc" -ArgumentList "/scannow" -Wait -NoNewWindow
    $StatusText.Text = "SFC done"
})

$window.FindName("BtnDismRestore").Add_Click({
    Start-Process "dism" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow
    $StatusText.Text = "DISM done"
})

$window.FindName("BtnRestorePoint").Add_Click({ New-RestorePoint })
$window.FindName("BtnControlPanel").Add_Click({     Start-Process "control" })
$window.FindName("BtnProgramsFeatures").Add_Click({ Start-Process "appwiz.cpl" })
$window.FindName("BtnNetworkConns").Add_Click({     Start-Process "ncpa.cpl" })
$window.FindName("BtnSystemInfo").Add_Click({       Start-Process "msinfo32" })

$window.FindName("BtnUpdRecommended").Add_Click({
    $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
    Set-ItemProperty $p -Name DeferFeatureUpdates -Value 1 -Type DWord -Force
    Set-ItemProperty $p -Name DeferFeatureUpdatesPeriodInDays -Value 365 -Type DWord -Force
    Set-ItemProperty $p -Name DeferQualityUpdates -Value 1 -Type DWord -Force
    Set-ItemProperty $p -Name DeferQualityUpdatesPeriodInDays -Value 4 -Type DWord -Force
    $StatusText.Text = "Updates: Recommended"
})

$window.FindName("BtnUpdDefault").Add_Click({
    Remove-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Recurse -Force -ErrorAction SilentlyContinue
    $StatusText.Text = "Updates: Default"
})

$window.FindName("BtnUpdDisable").Add_Click({
    $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
    Set-ItemProperty $p -Name NoAutoUpdate -Value 1 -Type DWord -Force
    $StatusText.Text = "Updates: Disabled"
})

Write-Log "RedzUtil v1.1 started"
$window.ShowDialog() | Out-Null
Write-Log "RedzUtil closed"