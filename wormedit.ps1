# WA_Scaler.ps1 - Worms Armageddon Resolution Scaler
# Double-click to run, or: powershell -ExecutionPolicy Bypass -File WA_Scaler.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Registry path
$regPath = "HKCU:\SOFTWARE\Team17SoftwareLTD\WormsArmageddon\Options"

# Get current settings
function Get-CurrentSettings {
    try {
        if (Test-Path $regPath) {
            $props = Get-ItemProperty -Path $regPath
            return @{
                InternalWidth = $props.DisplayXSize
                InternalHeight = $props.DisplayYSize
                WindowWidth = if ($props.PSObject.Properties.Name -contains "WindowXSize") { $props.WindowXSize } else { 0 }
                WindowHeight = if ($props.PSObject.Properties.Name -contains "WindowYSize") { $props.WindowYSize } else { 0 }
            }
        }
    }
    catch {
        return @{InternalWidth=1920; InternalHeight=1080; WindowWidth=0; WindowHeight=0}
    }
    return @{InternalWidth=1920; InternalHeight=1080; WindowWidth=0; WindowHeight=0}
}

# Functions
function Set-WAResolution {
    param(
        [int]$InternalWidth,
        [int]$InternalHeight,
        [int]$WindowWidth = 0,
        [int]$WindowHeight = 0
    )
    
    try {
        if (-not (Test-Path $regPath)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Worms Armageddon registry key not found!`nMake sure the game is installed.",
                "Error", 
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            return $false
        }
        
        # Set internal resolution (DisplayXSize/DisplayYSize)
        Set-ItemProperty -Path $regPath -Name "DisplayXSize" -Value $InternalWidth -Type DWord
        Set-ItemProperty -Path $regPath -Name "DisplayYSize" -Value $InternalHeight -Type DWord
        
        # Set window resolution if scaling (WindowXSize/WindowYSize)
        if ($WindowWidth -gt 0 -and $WindowHeight -gt 0) {
            Set-ItemProperty -Path $regPath -Name "WindowXSize" -Value $WindowWidth -Type DWord
            Set-ItemProperty -Path $regPath -Name "WindowYSize" -Value $WindowHeight -Type DWord
        }
        
        return $true
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Error: $_",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return $false
    }
}

function Remove-WAScaling {
    try {
        Remove-ItemProperty -Path $regPath -Name "WindowXSize" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $regPath -Name "WindowYSize" -ErrorAction SilentlyContinue
        return $true
    }
    catch {
        return $false
    }
}

# Get current settings
$currentSettings = Get-CurrentSettings

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Worms Armageddon Scaler"
$form.Size = New-Object System.Drawing.Size(500, 550)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(10, 10)
$titleLabel.Size = New-Object System.Drawing.Size(470, 30)
$titleLabel.Text = "Scale Worms Armageddon for High-Resolution Displays"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($titleLabel)

# Description
$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Location = New-Object System.Drawing.Point(10, 45)
$descLabel.Size = New-Object System.Drawing.Size(470, 40)
$descLabel.Text = "Choose a preset or enter custom values. Smaller internal resolution = bigger worms!`nWindow size is what your monitor displays at."
$form.Controls.Add($descLabel)

# Current settings display
$currentLabel = New-Object System.Windows.Forms.Label
$currentLabel.Location = New-Object System.Drawing.Point(10, 90)
$currentLabel.Size = New-Object System.Drawing.Size(470, 40)
$currentLabel.Text = "Current: Internal $($currentSettings.InternalWidth)x$($currentSettings.InternalHeight)" + 
    $(if ($currentSettings.WindowWidth -gt 0) { ", Window $($currentSettings.WindowWidth)x$($currentSettings.WindowHeight)" } else { " (no scaling)" })
$currentLabel.ForeColor = [System.Drawing.Color]::Blue
$currentLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$form.Controls.Add($currentLabel)

# Group box for presets
$groupBox = New-Object System.Windows.Forms.GroupBox
$groupBox.Location = New-Object System.Drawing.Point(10, 135)
$groupBox.Size = New-Object System.Drawing.Size(470, 180)
$groupBox.Text = "Common Presets"
$form.Controls.Add($groupBox)

# Radio buttons with cleaner labels
$radioNative = New-Object System.Windows.Forms.RadioButton
$radioNative.Location = New-Object System.Drawing.Point(15, 25)
$radioNative.Size = New-Object System.Drawing.Size(440, 25)
$radioNative.Text = "3840x2160 (Native 4K, no scaling)"
$radioNative.Tag = @{Internal=@(3840,2160); Window=@(0,0)}
$groupBox.Controls.Add($radioNative)

$radio1080 = New-Object System.Windows.Forms.RadioButton
$radio1080.Location = New-Object System.Drawing.Point(15, 55)
$radio1080.Size = New-Object System.Drawing.Size(440, 25)
$radio1080.Text = "1920x1080 (scaled to 3840x2160 window)"
$radio1080.Checked = $true
$radio1080.Tag = @{Internal=@(1920,1080); Window=@(3840,2160)}
$groupBox.Controls.Add($radio1080)

$radio720 = New-Object System.Windows.Forms.RadioButton
$radio720.Location = New-Object System.Drawing.Point(15, 85)
$radio720.Size = New-Object System.Drawing.Size(440, 25)
$radio720.Text = "1280x720 (scaled to 3840x2160 window)"
$radio720.Tag = @{Internal=@(1280,720); Window=@(3840,2160)}
$groupBox.Controls.Add($radio720)

$radio1440 = New-Object System.Windows.Forms.RadioButton
$radio1440.Location = New-Object System.Drawing.Point(15, 115)
$radio1440.Size = New-Object System.Drawing.Size(440, 25)
$radio1440.Text = "1920x1080 (scaled to 2560x1440 window)"
$radio1440.Tag = @{Internal=@(1920,1080); Window=@(2560,1440)}
$groupBox.Controls.Add($radio1440)

$radioCustom = New-Object System.Windows.Forms.RadioButton
$radioCustom.Location = New-Object System.Drawing.Point(15, 145)
$radioCustom.Size = New-Object System.Drawing.Size(440, 25)
$radioCustom.Text = "Custom (use values below)"
$radioCustom.Tag = "custom"
$groupBox.Controls.Add($radioCustom)

# Custom settings group
$customBox = New-Object System.Windows.Forms.GroupBox
$customBox.Location = New-Object System.Drawing.Point(10, 325)
$customBox.Size = New-Object System.Drawing.Size(470, 110)
$customBox.Text = "Custom Resolution"
$form.Controls.Add($customBox)

# Internal resolution inputs
$internalLabel = New-Object System.Windows.Forms.Label
$internalLabel.Location = New-Object System.Drawing.Point(15, 25)
$internalLabel.Size = New-Object System.Drawing.Size(120, 20)
$internalLabel.Text = "Internal (game):"
$customBox.Controls.Add($internalLabel)

$internalWidthBox = New-Object System.Windows.Forms.TextBox
$internalWidthBox.Location = New-Object System.Drawing.Point(140, 23)
$internalWidthBox.Size = New-Object System.Drawing.Size(80, 20)
$internalWidthBox.Text = $currentSettings.InternalWidth
$customBox.Controls.Add($internalWidthBox)

$xLabel1 = New-Object System.Windows.Forms.Label
$xLabel1.Location = New-Object System.Drawing.Point(225, 25)
$xLabel1.Size = New-Object System.Drawing.Size(15, 20)
$xLabel1.Text = "x"
$customBox.Controls.Add($xLabel1)

$internalHeightBox = New-Object System.Windows.Forms.TextBox
$internalHeightBox.Location = New-Object System.Drawing.Point(245, 23)
$internalHeightBox.Size = New-Object System.Drawing.Size(80, 20)
$internalHeightBox.Text = $currentSettings.InternalHeight
$customBox.Controls.Add($internalHeightBox)

# Window resolution inputs
$windowLabel = New-Object System.Windows.Forms.Label
$windowLabel.Location = New-Object System.Drawing.Point(15, 55)
$windowLabel.Size = New-Object System.Drawing.Size(120, 20)
$windowLabel.Text = "Window (monitor):"
$customBox.Controls.Add($windowLabel)

$windowWidthBox = New-Object System.Windows.Forms.TextBox
$windowWidthBox.Location = New-Object System.Drawing.Point(140, 53)
$windowWidthBox.Size = New-Object System.Drawing.Size(80, 20)
$windowWidthBox.Text = if ($currentSettings.WindowWidth -gt 0) { $currentSettings.WindowWidth } else { "3840" }
$customBox.Controls.Add($windowWidthBox)

$xLabel2 = New-Object System.Windows.Forms.Label
$xLabel2.Location = New-Object System.Drawing.Point(225, 55)
$xLabel2.Size = New-Object System.Drawing.Size(15, 20)
$xLabel2.Text = "x"
$customBox.Controls.Add($xLabel2)

$windowHeightBox = New-Object System.Windows.Forms.TextBox
$windowHeightBox.Location = New-Object System.Drawing.Point(245, 53)
$windowHeightBox.Size = New-Object System.Drawing.Size(80, 20)
$windowHeightBox.Text = if ($currentSettings.WindowHeight -gt 0) { $currentSettings.WindowHeight } else { "2160" }
$customBox.Controls.Add($windowHeightBox)

$noScaleCheckbox = New-Object System.Windows.Forms.CheckBox
$noScaleCheckbox.Location = New-Object System.Drawing.Point(140, 80)
$noScaleCheckbox.Size = New-Object System.Drawing.Size(200, 20)
$noScaleCheckbox.Text = "No window scaling"
$noScaleCheckbox.Checked = ($currentSettings.WindowWidth -eq 0)
$customBox.Controls.Add($noScaleCheckbox)

# Apply button
$applyButton = New-Object System.Windows.Forms.Button
$applyButton.Location = New-Object System.Drawing.Point(10, 450)
$applyButton.Size = New-Object System.Drawing.Size(150, 35)
$applyButton.Text = "Apply Settings"
$applyButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$applyButton.Add_Click({
    # Check if custom is selected
    if ($radioCustom.Checked) {
        try {
            $intW = [int]$internalWidthBox.Text
            $intH = [int]$internalHeightBox.Text
            $winW = if ($noScaleCheckbox.Checked) { 0 } else { [int]$windowWidthBox.Text }
            $winH = if ($noScaleCheckbox.Checked) { 0 } else { [int]$windowHeightBox.Text }
            
            $success = Set-WAResolution -InternalWidth $intW -InternalHeight $intH -WindowWidth $winW -WindowHeight $winH
            
            if ($success) {
                $msg = "Settings applied!`n`nInternal: ${intW}x${intH}"
                if ($winW -gt 0) { $msg += "`nWindow: ${winW}x${winH}" }
                [System.Windows.Forms.MessageBox]::Show($msg, "Success", 
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information)
                
                # Update current settings display
                $currentSettings = Get-CurrentSettings
                $currentLabel.Text = "Current: Internal $($currentSettings.InternalWidth)x$($currentSettings.InternalHeight)" + 
                    $(if ($currentSettings.WindowWidth -gt 0) { ", Window $($currentSettings.WindowWidth)x$($currentSettings.WindowHeight)" } else { " (no scaling)" })
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Invalid resolution values!", "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    else {
        # Find selected preset radio button
        $selected = $null
        foreach ($control in $groupBox.Controls) {
            if ($control -is [System.Windows.Forms.RadioButton] -and $control.Checked -and $control.Tag -ne "custom") {
                $selected = $control.Tag
                break
            }
        }
        
        if ($selected) {
            $success = Set-WAResolution -InternalWidth $selected.Internal[0] `
                                         -InternalHeight $selected.Internal[1] `
                                         -WindowWidth $selected.Window[0] `
                                         -WindowHeight $selected.Window[1]
            
            if ($success) {
                $msg = "Settings applied!`n`nInternal: $($selected.Internal[0])x$($selected.Internal[1])"
                if ($selected.Window[0] -gt 0) { $msg += "`nWindow: $($selected.Window[0])x$($selected.Window[1])" }
                [System.Windows.Forms.MessageBox]::Show($msg, "Success",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information)
                
                # Update current settings display
                $currentSettings = Get-CurrentSettings
                $currentLabel.Text = "Current: Internal $($currentSettings.InternalWidth)x$($currentSettings.InternalHeight)" + 
                    $(if ($currentSettings.WindowWidth -gt 0) { ", Window $($currentSettings.WindowWidth)x$($currentSettings.WindowHeight)" } else { " (no scaling)" })
            }
        }
    }
})
$form.Controls.Add($applyButton)

# Undo button
$undoButton = New-Object System.Windows.Forms.Button
$undoButton.Location = New-Object System.Drawing.Point(170, 450)
$undoButton.Size = New-Object System.Drawing.Size(150, 35)
$undoButton.Text = "Remove Scaling"
$undoButton.Add_Click({
    $result = Remove-WAScaling
    if ($result) {
        [System.Windows.Forms.MessageBox]::Show(
            "Window scaling removed! Game will use internal resolution only.",
            "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information)
        
        # Update display
        $currentSettings = Get-CurrentSettings
        $currentLabel.Text = "Current: Internal $($currentSettings.InternalWidth)x$($currentSettings.InternalHeight) (no scaling)"
    }
})
$form.Controls.Add($undoButton)

# Exit button
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Location = New-Object System.Drawing.Point(330, 450)
$exitButton.Size = New-Object System.Drawing.Size(150, 35)
$exitButton.Text = "Exit"
$exitButton.Add_Click({ $form.Close() })
$form.Controls.Add($exitButton)

# Show form
[void]$form.ShowDialog()