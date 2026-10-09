<#
.SYNOPSIS
    RedzUtil v2.0 - Premium Windows Toolbox

.DESCRIPTION
    UI محدث بالكامل:
    - بطاقات Apps مع أيقونات
    - تصميم فخم داكن
    - Rounded corners
    - ألوان neon
    - Search box
    - Hover effects
    - ترتيب أبجدي

.USAGE
    irm https://raw.githubusercontent.com/gxaff/RedzUtil/main/redzutil.ps1 | iex
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = 'Continue'

$script:Version = "2.0.0"
$script:LogPath = "$env:USERPROFILE\Desktop\RedzUtil_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$script:SelectedApps   = New-Object System.Collections.ArrayList
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
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" `
            -Name SystemRestorePointCreationFrequency -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "RedzUtil $(Get-Date -Format 'yyyy-MM-dd HH:mm')" `
            -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Log "Restore point created" 'OK'
    } catch {
        Write-Log "Restore point skipped" 'WARN'
    }
}

# ═══════════════════════════════════════════════════════════
#  TWEAKS
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
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
                    -Name AppsUseLightTheme -Value 0 -Type DWord -Force
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
                    -Name SystemUsesLightTheme -Value 0 -Type DWord -Force
                $success = $true
            }
            "Enable Long Paths" {
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
                    -Name LongPathsEnabled -Value 1 -Type DWord -Force
                $success = $true
            }
            "Disable Widgets" {
                try {
                    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                        /v TaskbarDa /t REG_DWORD /d 0 /f 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0) { $success = $true }
                } catch {
                    try {
                        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
                        Start-Sleep 2
                        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                            -Name TaskbarDa -Value 0 -Type DWord -Force -ErrorAction Stop
                        Start-Process explorer
                        $success = $true
                    } catch { $errorMsg = $_.Exception.Message }
                }
            }
            "Disable Start Recommendations" {
                Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                    -Name Start_IrisRecommendations -Value 0 -Type DWord -Force
                $success = $true
            }
            "Disable Xbox Services" {
                $any = $false
                foreach ($s in 'XblAuthManager','XblGameSave','XboxNetApiSvc') {
                    try { Set-Service -Name $s -StartupType Disabled -ErrorAction Stop; $any = $true } catch {}
                }
                $success = $any
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
        }

        if ($success) { Write-Log "OK: $Name" 'OK' }
        else { Write-Log "FAILED: $Name - $errorMsg" 'ERROR' }
    } catch {
        Write-Log "FAILED: $Name - $($_.Exception.Message)" 'ERROR'
    }
}

# ═══════════════════════════════════════════════════════════
#  APPS CATALOG — مع أيقونات
# ═══════════════════════════════════════════════════════════

$script:Apps = @(
    @{Name="Chrome";      Id="Google.Chrome";                Icon="🌐"; Category="Browsers"}
    @{Name="Firefox";     Id="Mozilla.Firefox";              Icon="🦊"; Category="Browsers"}
    @{Name="Brave";       Id="Brave.Brave";                  Icon="🦁"; Category="Browsers"}
    @{Name="Vivaldi";     Id="Vivaldi.Vivaldi";              Icon="🎵"; Category="Browsers"}
    @{Name="Discord";     Id="Discord.Discord";              Icon="💬"; Category="Communication"}
    @{Name="Telegram";    Id="Telegram.TelegramDesktop";     Icon="✈️"; Category="Communication"}
    @{Name="WhatsApp";    Id="WhatsApp.WhatsApp";            Icon="📱"; Category="Communication"}
    @{Name="Zoom";        Id="Zoom.Zoom";                    Icon="📹"; Category="Communication"}
    @{Name="Slack";       Id="SlackTechnologies.Slack";      Icon="💼"; Category="Communication"}
    @{Name="Signal";      Id="OpenWhisperSystems.Signal";    Icon="🔒"; Category="Communication"}
    @{Name="VS Code";     Id="Microsoft.VisualStudioCode";   Icon="📝"; Category="Development"}
    @{Name="Cursor";      Id="Anysphere.Cursor";             Icon="⚡"; Category="Development"}
    @{Name="Git";         Id="Git.Git";                      Icon="🔀"; Category="Development"}
    @{Name="Docker";      Id="Docker.DockerDesktop";         Icon="🐳"; Category="Development"}
    @{Name="Node.js LTS"; Id="OpenJS.NodeJS.LTS";            Icon="🟢"; Category="Development"}
    @{Name="Python 3.12"; Id="Python.Python.3.12";           Icon="🐍"; Category="Development"}
    @{Name="7-Zip";       Id="7zip.7zip";                    Icon="🗜️"; Category="Utilities"}
    @{Name="VLC";         Id="VideoLAN.VLC";                 Icon="🎬"; Category="Multimedia"}
    @{Name="Notepad++";   Id="Notepad++.Notepad++";          Icon="📄"; Category="Utilities"}
    @{Name="PowerToys";   Id="Microsoft.PowerToys";          Icon="🛠️"; Category="Utilities"}
    @{Name="Everything";  Id="voidtools.Everything";         Icon="🔍"; Category="Utilities"}
    @{Name="Steam";       Id="Valve.Steam";                  Icon="🎮"; Category="Gaming"}
)

function Install-App {
    param([string]$WingetId, [string]$AppName)
    Write-Log "Installing: $AppName ($WingetId)"
    try {
        winget install --id $WingetId --silent `
            --accept-package-agreements --accept-source-agreements `
            --disable-interactivity 2>&1 | Out-Null
        Write-Log "Installed: $AppName" 'OK'
    } catch {
        Write-Log "Install failed: $AppName" 'ERROR'
    }
}

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
        Write-Log "DNS: Default"
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
#  WPF GUI — Premium Design
# ═══════════════════════════════════════════════════════════

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="RedzUtil v2.0" Height="820" Width="1280"
        WindowStartupLocation="CenterScreen"
        Background="#0d0d12" Foreground="#e8e8f0"
        WindowStyle="None" AllowsTransparency="False"
        ResizeMode="CanResizeWithGrip">

  <Window.Resources>
    <!-- Color palette -->
    <SolidColorBrush x:Key="BgDark"     Color="#0d0d12"/>
    <SolidColorBrush x:Key="BgPanel"    Color="#16161f"/>
    <SolidColorBrush x:Key="BgCard"     Color="#1e1e2a"/>
    <SolidColorBrush x:Key="BgCardHov"  Color="#28283a"/>
    <SolidColorBrush x:Key="Accent"     Color="#00e5a0"/>
    <SolidColorBrush x:Key="Accent2"    Color="#7b5cff"/>
    <SolidColorBrush x:Key="TextDim"    Color="#8a8a9a"/>
    <SolidColorBrush x:Key="Border"     Color="#2a2a3a"/>

    <!-- Card Button Style -->
    <Style x:Key="AppCard" TargetType="ToggleButton">
      <Setter Property="Background" Value="{StaticResource BgCard}"/>
      <Setter Property="Foreground" Value="{StaticResource TextDim}"/>
      <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="0"/>
      <Setter Property="Margin" Value="6"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Height" Value="80"/>
      <Setter Property="Width" Value="200"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ToggleButton">
            <Border x:Name="bg" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    CornerRadius="10">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bg" Property="Background" Value="{StaticResource BgCardHov}"/>
                <Setter TargetName="bg" Property="BorderBrush" Value="{StaticResource Accent2}"/>
              </Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="bg" Property="Background" Value="#1a3a2a"/>
                <Setter TargetName="bg" Property="BorderBrush" Value="{StaticResource Accent}"/>
                <Setter TargetName="bg" Property="BorderThickness" Value="2"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Primary Button -->
    <Style x:Key="PrimaryBtn" TargetType="Button">
      <Setter Property="Background" Value="{StaticResource Accent}"/>
      <Setter Property="Foreground" Value="#0d0d12"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Padding" Value="20,10"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="8">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                Margin="{TemplateBinding Padding}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bg" Property="Background" Value="#00ffb0"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Secondary Button -->
    <Style x:Key="SecondaryBtn" TargetType="Button">
      <Setter Property="Background" Value="{StaticResource BgCard}"/>
      <Setter Property="Foreground" Value="#e8e8f0"/>
      <Setter Property="Padding" Value="16,9"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    CornerRadius="8">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                Margin="{TemplateBinding Padding}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bg" Property="Background" Value="{StaticResource BgCardHov}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Tweak Card -->
    <Style x:Key="TweakCard" TargetType="CheckBox">
      <Setter Property="Foreground" Value="#c8c8d8"/>
      <Setter Property="Padding" Value="12,10"/>
      <Setter Property="Margin" Value="0,3"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Border x:Name="bg" Background="{StaticResource BgCard}"
                    BorderBrush="{StaticResource Border}"
                    BorderThickness="1" CornerRadius="8" Padding="{TemplateBinding Padding}">
              <StackPanel Orientation="Horizontal">
                <Border x:Name="cb" Width="18" Height="18" CornerRadius="4"
                        Background="Transparent" BorderBrush="{StaticResource Border}"
                        BorderThickness="2" Margin="0,0,12,0">
                  <TextBlock x:Name="check" Text="✓" FontWeight="Bold"
                             Foreground="#0d0d12" HorizontalAlignment="Center"
                             VerticalAlignment="Center" Visibility="Collapsed"/>
                </Border>
                <ContentPresenter VerticalAlignment="Center"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bg" Property="Background" Value="{StaticResource BgCardHov}"/>
              </Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="bg" Property="Background" Value="#1a3a2a"/>
                <Setter TargetName="bg" Property="BorderBrush" Value="{StaticResource Accent}"/>
                <Setter TargetName="cb" Property="Background" Value="{StaticResource Accent}"/>
                <Setter TargetName="cb" Property="BorderBrush" Value="{StaticResource Accent}"/>
                <Setter TargetName="check" Property="Visibility" Value="Visible"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

  </Window.Resources>

  <Grid>
    <Grid.RowDefinitions>
      <RowDefinition Height="50"/>
      <RowDefinition Height="60"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="32"/>
    </Grid.RowDefinitions>

    <!-- ═══ TITLE BAR ═══ -->
    <Border Grid.Row="0" Background="#0a0a10">
      <Grid>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Left" Margin="20,0,0,0" VerticalAlignment="Center">
          <TextBlock Text="⚡" FontSize="20" Foreground="{StaticResource Accent}" VerticalAlignment="Center"/>
          <TextBlock Text="RedzUtil" FontSize="18" FontWeight="Bold" Margin="8,0,0,0" VerticalAlignment="Center"/>
          <TextBlock Text="v2.0" FontSize="12" Foreground="{StaticResource TextDim}" Margin="6,0,0,0" VerticalAlignment="Center"/>
        </StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,10,0">
          <Button x:Name="BtnMin" Content="—" Width="40" Height="30" Background="Transparent"
                  Foreground="#888" BorderThickness="0" FontSize="16"/>
          <Button x:Name="BtnClose" Content="✕" Width="40" Height="30" Background="Transparent"
                  Foreground="#888" BorderThickness="0" FontSize="14"/>
        </StackPanel>
      </Grid>
    </Border>

    <!-- ═══ HEADER / SEARCH ═══ -->
    <Border Grid.Row="1" Background="#0a0a10" BorderBrush="{StaticResource Border}" BorderThickness="0,1,0,1">
      <Grid Margin="20,0">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="300"/>
        </Grid.ColumnDefinitions>
        <TextBlock x:Name="HeaderText" Grid.Column="0" Text="Install Applications"
                   FontSize="20" FontWeight="Bold" VerticalAlignment="Center"/>
        <Border Grid.Column="1" Background="{StaticResource BgCard}" CornerRadius="8"
                BorderBrush="{StaticResource Border}" BorderThickness="1" VerticalAlignment="Center" Height="36">
          <Grid>
            <TextBlock Text="🔍  Search..." Foreground="{StaticResource TextDim}"
                       VerticalAlignment="Center" Margin="12,0,0,0" x:Name="SearchPlaceholder"/>
            <TextBox x:Name="SearchBox" Background="Transparent" Foreground="#e8e8f0"
                     BorderThickness="0" Padding="12,0" VerticalContentAlignment="Center"
                     FontSize="12"/>
          </Grid>
        </Border>
      </Grid>
    </Border>

    <!-- ═══ MAIN CONTENT ═══ -->
    <Grid Grid.Row="2">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="200"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>

      <!-- Sidebar -->
      <Border Grid.Column="0" Background="#0a0a10" BorderBrush="{StaticResource Border}" BorderThickness="0,0,1,0">
        <StackPanel Margin="12">
          <Button x:Name="NavInstall" Content="📦  Install" Style="{StaticResource SecondaryBtn}"
                  HorizontalContentAlignment="Left" Margin="0,4"/>
          <Button x:Name="NavTweaks"  Content="⚙️  Tweaks"  Style="{StaticResource SecondaryBtn}"
                  HorizontalContentAlignment="Left" Margin="0,4"/>
          <Button x:Name="NavConfig"  Content="🔧  Config"  Style="{StaticResource SecondaryBtn}"
                  HorizontalContentAlignment="Left" Margin="0,4"/>
          <Button x:Name="NavUpdates" Content="🔄  Updates" Style="{StaticResource SecondaryBtn}"
                  HorizontalContentAlignment="Left" Margin="0,4"/>

          <Border Height="1" Background="{StaticResource Border}" Margin="0,20"/>

          <Button x:Name="NavRun" Content="▶  RUN SELECTED" Style="{StaticResource PrimaryBtn}"
                  Margin="0,4" Height="44"/>
          <Button x:Name="NavClear" Content="✕  Clear" Style="{StaticResource SecondaryBtn}"
                  Margin="0,4"/>

          <TextBlock x:Name="StatusCount" Text="0 selected" Foreground="{StaticResource TextDim}"
                     FontSize="11" Margin="0,20,0,0" HorizontalAlignment="Center"/>
        </StackPanel>
      </Border>

      <!-- Content Area -->
      <ScrollViewer Grid.Column="1" VerticalScrollBarVisibility="Auto" Padding="20">
        <StackPanel x:Name="ContentArea"/>
      </ScrollViewer>
    </Grid>

    <!-- ═══ STATUS BAR ═══ -->
    <Border Grid.Row="3" Background="#0a0a10" BorderBrush="{StaticResource Border}" BorderThickness="0,1,0,0">
      <Grid Margin="20,0">
        <TextBlock x:Name="StatusText" Text="Ready" Foreground="{StaticResource TextDim}"
                   FontSize="11" VerticalAlignment="Center"/>
        <TextBlock Text="RedzUtil v2.0" Foreground="{StaticResource TextDim}"
                   FontSize="11" HorizontalAlignment="Right" VerticalAlignment="Center"/>
      </Grid>
    </Border>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# ═══════════════════════════════════════════════════════════
#  ELEMENTS
# ═══════════════════════════════════════════════════════════

$ContentArea  = $window.FindName("ContentArea")
$HeaderText   = $window.FindName("HeaderText")
$StatusText   = $window.FindName("StatusText")
$StatusCount  = $window.FindName("StatusCount")
$SearchBox    = $window.FindName("SearchBox")
$SearchPlaceholder = $window.FindName("SearchPlaceholder")

# ─── Title bar buttons ───
$window.FindName("BtnClose").Add_Click({ $window.Close() })
$window.FindName("BtnMin").Add_Click({ $window.WindowState = 'Minimized' })

# ─── Search placeholder ───
$SearchBox.Add_GotFocus({ $SearchPlaceholder.Visibility = 'Collapsed' })
$SearchBox.Add_LostFocus({
    if ([string]::IsNullOrEmpty($SearchBox.Text)) { $SearchPlaceholder.Visibility = 'Visible' }
})

# ═══════════════════════════════════════════════════════════
#  VIEWS
# ═══════════════════════════════════════════════════════════

function Show-InstallView {
    $ContentArea.Children.Clear()
    $HeaderText.Text = "Install Applications"

    # Group by Category
    $categories = $script:Apps | Group-Object Category | Sort-Object Name
    foreach ($cat in $categories) {
        $catTitle = New-Object System.Windows.Controls.TextBlock
        $catTitle.Text = "▸ $($cat.Name)"
        $catTitle.FontSize = 14
        $catTitle.FontWeight = "Bold"
        $catTitle.Foreground = "#7b5cff"
        $catTitle.Margin = "6,20,0,8"
        $ContentArea.Children.Add($catTitle) | Out-Null

        $wrap = New-Object System.Windows.Controls.WrapPanel
        foreach ($app in ($cat.Group | Sort-Object Name)) {
            $tile = New-Object System.Windows.Controls.Primitives.ToggleButton
            $tile.Style = $window.FindResource("AppCard")
            $tile.Tag = $app.Id

            $inner = New-Object System.Windows.Controls.StackPanel
            $inner.VerticalAlignment = "Center"
            $inner.HorizontalAlignment = "Center"

            $icon = New-Object System.Windows.Controls.TextBlock
            $icon.Text = $app.Icon
            $icon.FontSize = 28
            $icon.HorizontalAlignment = "Center"
            $inner.Children.Add($icon) | Out-Null

            $name = New-Object System.Windows.Controls.TextBlock
            $name.Text = $app.Name
            $name.FontSize = 12
            $name.FontWeight = "SemiBold"
            $name.Foreground = "#e8e8f0"
            $name.HorizontalAlignment = "Center"
            $name.Margin = "0,4,0,0"
            $inner.Children.Add($name) | Out-Null

            $tile.Content = $inner
            $tile.Add_Checked({
                if (-not $script:SelectedApps.Contains($this.Tag)) {
                    [void]$script:SelectedApps.Add($this.Tag)
                    $StatusCount.Text = "$($script:SelectedApps.Count) apps selected"
                }
            })
            $tile.Add_Unchecked({
                $script:SelectedApps.Remove($this.Tag) | Out-Null
                $StatusCount.Text = "$($script:SelectedApps.Count) apps selected"
            })
            $wrap.Children.Add($tile) | Out-Null
        }
        $ContentArea.Children.Add($wrap) | Out-Null
    }
}

function Show-TweaksView {
    $ContentArea.Children.Clear()
    $HeaderText.Text = "System Tweaks"

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
        $cb.Style = $window.FindResource("TweakCard")
        $cb.Content = "  $t"
        $cb.Tag = $t
        $cb.Add_Checked({
            if (-not $script:SelectedTweaks.Contains($this.Tag)) {
                [void]$script:SelectedTweaks.Add($this.Tag)
                $StatusCount.Text = "$($script:SelectedTweaks.Count) tweaks selected"
            }
        })
        $cb.Add_Unchecked({
            $script:SelectedTweaks.Remove($this.Tag) | Out-Null
            $StatusCount.Text = "$($script:SelectedTweaks.Count) tweaks selected"
        })
        $ContentArea.Children.Add($cb) | Out-Null
    }
}

function Show-ConfigView {
    $ContentArea.Children.Clear()
    $HeaderText.Text = "Configuration"

    $dnsTitle = New-Object System.Windows.Controls.TextBlock
    $dnsTitle.Text = "▸ DNS Provider"
    $dnsTitle.FontSize = 14; $dnsTitle.FontWeight = "Bold"
    $dnsTitle.Foreground = "#7b5cff"; $dnsTitle.Margin = "6,10,0,8"
    $ContentArea.Children.Add($dnsTitle) | Out-Null

    $dnsWrap = New-Object System.Windows.Controls.WrapPanel
    foreach ($dns in @("Cloudflare","Google","Quad9","OpenDNS","AdGuard","Default")) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Style = $window.FindResource("SecondaryBtn")
        $btn.Content = $dns
        $btn.Tag = $dns
        $btn.Width = 160
        $btn.Margin = "5"
        $btn.Add_Click({
            Set-DNS -Provider $this.Tag
            $StatusText.Text = "DNS: $($this.Tag)"
        })
        $dnsWrap.Children.Add($btn) | Out-Null
    }
    $ContentArea.Children.Add($dnsWrap) | Out-Null

    $toolsTitle = New-Object System.Windows.Controls.TextBlock
    $toolsTitle.Text = "▸ Fixes & Tools"
    $toolsTitle.FontSize = 14; $toolsTitle.FontWeight = "Bold"
    $toolsTitle.Foreground = "#7b5cff"; $toolsTitle.Margin = "6,30,0,8"
    $ContentArea.Children.Add($toolsTitle) | Out-Null

    $tools = @(
        @{Name="Network Reset";   Action={ Start-Process "netsh" -ArgumentList "int ip reset" -Wait -NoNewWindow }}
        @{Name="System File Check"; Action={ Start-Process "sfc" -ArgumentList "/scannow" -Wait -NoNewWindow }}
        @{Name="DISM Restore";    Action={ Start-Process "dism" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow }}
        @{Name="Restore Point";   Action={ New-RestorePoint }}
        @{Name="Control Panel";   Action={ Start-Process "control" }}
        @{Name="Programs";        Action={ Start-Process "appwiz.cpl" }}
        @{Name="Network";         Action={ Start-Process "ncpa.cpl" }}
        @{Name="System Info";     Action={ Start-Process "msinfo32" }}
    )
    $toolsWrap = New-Object System.Windows.Controls.WrapPanel
    foreach ($t in $tools) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Style = $window.FindResource("SecondaryBtn")
        $btn.Content = $t.Name
        $btn.Width = 160
        $btn.Margin = "5"
        $btn.Add_Click($t.Action)
        $toolsWrap.Children.Add($btn) | Out-Null
    }
    $ContentArea.Children.Add($toolsWrap) | Out-Null
}

function Show-UpdatesView {
    $ContentArea.Children.Clear()
    $HeaderText.Text = "Windows Update Control"

    $profiles = @(
        @{Name="Recommended"; Desc="Defers feature updates 365 days"; Color="#00e5a0"}
        @{Name="Windows Default"; Desc="Restore default Windows settings"; Color="#7b5cff"}
        @{Name="Disable Updates"; Desc="Not recommended"; Color="#ff5555"}
    )

    foreach ($p in $profiles) {
        $card = New-Object System.Windows.Controls.Border
        $card.Background = "#1e1e2a"
        $card.BorderBrush = $p.Color
        $card.BorderThickness = "2"
        $card.CornerRadius = "10"
        $card.Padding = "20"
        $card.Margin = "5,5,5,15"
        $card.MaxWidth = 700
        $card.HorizontalAlignment = "Left"

        $inner = New-Object System.Windows.Controls.StackPanel

        $title = New-Object System.Windows.Controls.TextBlock
        $title.Text = $p.Name
        $title.FontSize = 18
        $title.FontWeight = "Bold"
        $title.Foreground = $p.Color
        $inner.Children.Add($title) | Out-Null

        $desc = New-Object System.Windows.Controls.TextBlock
        $desc.Text = $p.Desc
        $desc.Foreground = "#8a8a9a"
        $desc.Margin = "0,6,0,12"
        $inner.Children.Add($desc) | Out-Null

        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = "Apply"
        $btn.Style = $window.FindResource("PrimaryBtn")
        $btn.HorizontalAlignment = "Left"
        $btn.Tag = $p.Name
        $btn.Add_Click({
            $updatePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
            switch ($this.Tag) {
                "Recommended" {
                    if (-not (Test-Path $updatePath)) { New-Item $updatePath -Force | Out-Null }
                    Set-ItemProperty $updatePath -Name DeferFeatureUpdates -Value 1 -Type DWord -Force
                    Set-ItemProperty $updatePath -Name DeferFeatureUpdatesPeriodInDays -Value 365 -Type DWord -Force
                    Set-ItemProperty $updatePath -Name DeferQualityUpdates -Value 1 -Type DWord -Force
                    Set-ItemProperty $updatePath -Name DeferQualityUpdatesPeriodInDays -Value 4 -Type DWord -Force
                }
                "Windows Default" {
                    Remove-Item $updatePath -Recurse -Force -ErrorAction SilentlyContinue
                }
                "Disable Updates" {
                    if (-not (Test-Path $updatePath)) { New-Item $updatePath -Force | Out-Null }
                    Set-ItemProperty $updatePath -Name NoAutoUpdate -Value 1 -Type DWord -Force
                }
            }
            $StatusText.Text = "Updates: $($this.Tag)"
        })
        $inner.Children.Add($btn) | Out-Null

        $card.Child = $inner
        $ContentArea.Children.Add($card) | Out-Null
    }
}

# ═══════════════════════════════════════════════════════════
#  NAVIGATION
# ═══════════════════════════════════════════════════════════

$window.FindName("NavInstall").Add_Click({ Show-InstallView })
$window.FindName("NavTweaks").Add_Click({  Show-TweaksView  })
$window.FindName("NavConfig").Add_Click({  Show-ConfigView  })
$window.FindName("NavUpdates").Add_Click({ Show-UpdatesView })

$window.FindName("NavClear").Add_Click({
    $script:SelectedApps.Clear()
    $script:SelectedTweaks.Clear()
    $StatusCount.Text = "0 selected"
    Show-InstallView
})

$window.FindName("NavRun").Add_Click({
    if ($script:SelectedApps.Count -gt 0) {
        New-RestorePoint
        foreach ($id in $script:SelectedApps) {
            $app = $script:Apps | Where-Object { $_.Id -eq $id } | Select-Object -First 1
            if ($app) { Install-App -WingetId $app.Id -AppName $app.Name }
        }
    }
    if ($script:SelectedTweaks.Count -gt 0) {
        New-RestorePoint
        foreach ($t in $script:SelectedTweaks) { Invoke-Tweak -Name $t }
    }
    [System.Windows.MessageBox]::Show("Done! Check log on Desktop", "RedzUtil")
    $StatusText.Text = "Complete - check log"
})

# ═══════════════════════════════════════════════════════════
#  START
# ═══════════════════════════════════════════════════════════

Show-InstallView
Write-Log "RedzUtil v2.0 started"
$window.ShowDialog() | Out-Null
Write-Log "RedzUtil closed"