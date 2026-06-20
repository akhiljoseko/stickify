/// PowerShell script definitions for Windows printing registry overrides.
abstract final class PowershellScripts {
  /// Backs up DEVMODE, applies custom paper size, broadcasts WM_DEVMODECHANGE.
  static const String devMode = r'''
param (
    [string]$Action,
    [string]$PrinterName,
    [double]$WidthMm,
    [double]$HeightMm,
    [string]$BackupBase64
)

$code = @"
using System;
using System.Runtime.InteropServices;

public class Win32Printer {
    [DllImport("winspool.drv", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int OpenPrinter(string pPrinterName, out IntPtr phPrinter, IntPtr pDefault);

    [DllImport("winspool.drv", SetLastError = true)]
    public static extern int ClosePrinter(IntPtr hPrinter);

    [DllImport("winspool.drv", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern int DocumentProperties(IntPtr hWnd, IntPtr hPrinter, string pDeviceName, IntPtr pDevModeOutput, IntPtr pDevModeInput, int fMode);

    public static byte[] GetDefaultDevMode(string printerName) {
        IntPtr hPrinter = IntPtr.Zero;
        try {
            int ret = OpenPrinter(printerName, out hPrinter, IntPtr.Zero);
            if (ret == 0) return null;

            int size = DocumentProperties(IntPtr.Zero, hPrinter, printerName, IntPtr.Zero, IntPtr.Zero, 0);
            if (size <= 0) return null;

            IntPtr pDevMode = Marshal.AllocCoTaskMem(size);
            ret = DocumentProperties(IntPtr.Zero, hPrinter, printerName, pDevMode, IntPtr.Zero, 2); // DM_OUT_BUFFER
            if (ret >= 0) {
                byte[] bytes = new byte[size];
                Marshal.Copy(pDevMode, bytes, 0, size);
                return bytes;
            }
            return null;
        } finally {
            if (hPrinter != IntPtr.Zero) ClosePrinter(hPrinter);
        }
    }
}
"@

$notifyCode = @"
using System;
using System.Runtime.InteropServices;

public class Win32Notifier {
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern bool SendNotifyMessage(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam);

    private static readonly IntPtr HWND_BROADCAST = (IntPtr)0xffff;
    private const uint WM_DEVMODECHANGE = 0x001B;

    public static void Notify(string printerName) {
        SendNotifyMessage(HWND_BROADCAST, WM_DEVMODECHANGE, IntPtr.Zero, printerName);
    }
}
"@

$regKeys = @("HKCU:\Printers\DevModes2", "HKCU:\Printers\DevModePerUser")
$backupPath = "HKCU:\Printers\DevModeBackup"

function Set-Int16($arr, $offset, $value) {
    $b = [System.BitConverter]::GetBytes([Int16]$value)
    $arr[$offset] = $b[0]
    $arr[$offset + 1] = $b[1]
}

function Get-Int32($arr, $offset) {
    return [System.BitConverter]::ToInt32($arr, $offset)
}

function Set-Int32($arr, $offset, $value) {
    $b = [System.BitConverter]::GetBytes([Int32]$value)
    $arr[$offset] = $b[0]
    $arr[$offset + 1] = $b[1]
    $arr[$offset + 2] = $b[2]
    $arr[$offset + 3] = $b[3]
}

if ($Action -eq "set") {
    $val = $null
    $valKey = $null
    
    foreach ($rk in $regKeys) {
        $v = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).$PrinterName
        if ($v -ne $null) {
            $val = $v
            $valKey = $rk
            break
        }
    }
    
    $originalBackup = "NONE"
    if ($val -eq $null) {
        if (-not ([System.Management.Automation.PSTypeName]"Win32Printer").Type) {
            Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
        }
        $val = [Win32Printer]::GetDefaultDevMode($PrinterName)
    } else {
        $originalBackup = "$valKey|$([Convert]::ToBase64String($val))"
    }

    if ($val -eq $null) {
        Write-Error "Could not retrieve DEVMODE for printer $PrinterName"
        exit 1
    }

    # Query printer paper sizes to find the matched paper size RawKind ID
    $paperSizeId = 0
    try {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
        $settings = New-Object System.Drawing.Printing.PrinterSettings
        $settings.PrinterName = $PrinterName
        
        $targetW = $WidthMm
        $targetH = $HeightMm
        $tolerance = 1.5
        
        foreach ($ps in $settings.PaperSizes) {
            $wMm = [Math]::Round($ps.Width * 0.254, 1)
            $hMm = [Math]::Round($ps.Height * 0.254, 1)
            
            $matchNormal = [Math]::Abs($wMm - $targetW) -le $tolerance -and [Math]::Abs($hMm - $targetH) -le $tolerance
            
            if ($matchNormal) {
                $paperSizeId = $ps.RawKind
                break
            }
        }
    } catch {}

    # Write backup entry in DevModeBackup key for self-healing
    if (-not (Test-Path $backupPath)) {
        New-Item -Path "HKCU:\Printers" -Name "DevModeBackup" -Force | Out-Null
    }
    Set-ItemProperty -Path $backupPath -Name $PrinterName -Value $originalBackup -Force | Out-Null

    $modifiedBytes = $val.Clone()
    $fields = Get-Int32 $modifiedBytes 72
    $fields = $fields -bor (0x1 -bor 0x2 -bor 0x4 -bor 0x8)
    Set-Int32 $modifiedBytes 72 $fields

    $w = [Int16][Math]::Round($WidthMm * 10)
    $h = [Int16][Math]::Round($HeightMm * 10)

    # Always Portrait (1) for custom paper sizes since layout coordinates/rotation are already
    # fully composed in the generated PDF bytes. This prevents driver-level double-rotation.
    $orient = [Int16]1

    Set-Int16 $modifiedBytes 76 $orient
    Set-Int16 $modifiedBytes 78 $paperSizeId
    Set-Int16 $modifiedBytes 80 $h
    Set-Int16 $modifiedBytes 82 $w

    foreach ($rk in $regKeys) {
        Set-ItemProperty -Path $rk -Name $PrinterName -Value $modifiedBytes -ErrorAction SilentlyContinue
    }
    
    # Broadcast notification to invalidate winspool cache in running apps
    if (-not ([System.Management.Automation.PSTypeName]"Win32Notifier").Type) {
        Add-Type -TypeDefinition $notifyCode -ErrorAction SilentlyContinue
    }
    [Win32Notifier]::Notify($PrinterName)
    
    Write-Output "BACKUP:$originalBackup"
}
elseif ($Action -eq "restore") {
    # Remove backup key entry since we are restoring successfully
    if (Test-Path $backupPath) {
        Remove-ItemProperty -Path $backupPath -Name $PrinterName -ErrorAction SilentlyContinue
    }

    if ($BackupBase64 -eq "NONE" -or $BackupBase64 -eq $null -or $BackupBase64 -eq "") {
        foreach ($rk in $regKeys) {
            Remove-ItemProperty -Path $rk -Name $PrinterName -ErrorAction SilentlyContinue
        }
    } else {
        $parts = $BackupBase64.Split('|')
        if ($parts.Length -eq 2) {
            $keyPath = $parts[0]
            $bytes = [Convert]::FromBase64String($parts[1])
            Set-ItemProperty -Path $keyPath -Name $PrinterName -Value $bytes -ErrorAction SilentlyContinue
            
            foreach ($rk in $regKeys) {
                if ($rk -ne $keyPath) {
                    Remove-ItemProperty -Path $rk -Name $PrinterName -ErrorAction SilentlyContinue
                }
            }
        }
    }
    
    # Broadcast notification to invalidate winspool cache in running apps after restore
    if (-not ([System.Management.Automation.PSTypeName]"Win32Notifier").Type) {
        Add-Type -TypeDefinition $notifyCode -ErrorAction SilentlyContinue
    }
    [Win32Notifier]::Notify($PrinterName)
    
    Write-Output "RESTORED"
}
''';

  /// PowerShell script that lists all paper sizes (forms) supported by the printer,
  /// returning their names, width, and height in millimeters as a JSON array.
  static const String listPapers = r'''
param (
    [string]$PrinterName
)
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
$settings = New-Object System.Drawing.Printing.PrinterSettings
$settings.PrinterName = $PrinterName
$settings.PaperSizes | ForEach-Object {
    [PSCustomObject]@{
        Name = $_.PaperName
        Width = [Math]::Round($_.Width * 0.254, 1)
        Height = [Math]::Round($_.Height * 0.254, 1)
    }
} | ConvertTo-Json
''';

  /// PowerShell script that scans HKCU:\Printers\DevModeBackup and restores any leftover
  /// settings, then invalidates the caches, cleaning up the registry.
  static const String healRegistry = r'''
$notifyCode = @"
using System;
using System.Runtime.InteropServices;

public class Win32Notifier {
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern bool SendNotifyMessage(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam);

    private static readonly IntPtr HWND_BROADCAST = (IntPtr)0xffff;
    private const uint WM_DEVMODECHANGE = 0x001B;

    public static void Notify(string printerName) {
        SendNotifyMessage(HWND_BROADCAST, WM_DEVMODECHANGE, IntPtr.Zero, printerName);
    }
}
"@

$backupPath = "HKCU:\Printers\DevModeBackup"
$regKeys = @("HKCU:\Printers\DevModes2", "HKCU:\Printers\DevModePerUser")

if (Test-Path $backupPath) {
    $item = Get-Item -Path $backupPath -ErrorAction SilentlyContinue
    if ($item -ne $null) {
        foreach ($prop in $item.Property) {
            $val = $item.GetValue($prop)
            if ($val -ne $null -and $val -ne "") {
                $parts = $val.Split('|')
                if ($parts.Length -eq 2) {
                    $keyPath = $parts[0]
                    $bytes = [Convert]::FromBase64String($parts[1])
                    
                    # Restore backup bytes to the correct key
                    Set-ItemProperty -Path $keyPath -Name $prop -Value $bytes -ErrorAction SilentlyContinue
                    
                    # Clean up the other registry keys
                    foreach ($rk in $regKeys) {
                        if ($rk -ne $keyPath) {
                            Remove-ItemProperty -Path $rk -Name $prop -ErrorAction SilentlyContinue
                        }
                    }
                }
            }
            # Remove from backup registry key
            Remove-ItemProperty -Path $backupPath -Name $prop -ErrorAction SilentlyContinue
            
            # Broadcast notification
            if (-not ([System.Management.Automation.PSTypeName]"Win32Notifier").Type) {
                Add-Type -TypeDefinition $notifyCode -ErrorAction SilentlyContinue
            }
            [Win32Notifier]::Notify($prop)
        }
    }
}
''';
}
