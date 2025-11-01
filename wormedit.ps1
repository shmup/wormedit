# wormedit.ps1 - Worms Armageddon Registry Editor
# Double-click to run, or: powershell -ExecutionPolicy Bypass -File wormedit.ps1

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
                InternalWidth = if ($props.PSObject.Properties.Name -contains "DisplayXSize") { $props.DisplayXSize } else { "" }
                InternalHeight = if ($props.PSObject.Properties.Name -contains "DisplayYSize") { $props.DisplayYSize } else { "" }
                WindowWidth = if ($props.PSObject.Properties.Name -contains "WindowXSize") { $props.WindowXSize } else { "" }
                WindowHeight = if ($props.PSObject.Properties.Name -contains "WindowYSize") { $props.WindowYSize } else { "" }
            }
        }
    }
    catch {
        return @{InternalWidth=""; InternalHeight=""; WindowWidth=""; WindowHeight=""}
    }
    return @{InternalWidth=""; InternalHeight=""; WindowWidth=""; WindowHeight=""}
}

# Functions
function Set-WAResolution {
    param(
        [string]$InternalWidth,
        [string]$InternalHeight,
        [string]$WindowWidth,
        [string]$WindowHeight
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

        # Set internal resolution if provided
        if ($InternalWidth -ne "") {
            Set-ItemProperty -Path $regPath -Name "DisplayXSize" -Value ([int]$InternalWidth) -Type DWord
        }
        if ($InternalHeight -ne "") {
            Set-ItemProperty -Path $regPath -Name "DisplayYSize" -Value ([int]$InternalHeight) -Type DWord
        }

        # Set window resolution if provided
        if ($WindowWidth -ne "") {
            Set-ItemProperty -Path $regPath -Name "WindowXSize" -Value ([int]$WindowWidth) -Type DWord
        }
        if ($WindowHeight -ne "") {
            Set-ItemProperty -Path $regPath -Name "WindowYSize" -Value ([int]$WindowHeight) -Type DWord
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
        Remove-ItemProperty -Path $regPath -Name "DisplayXSize" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $regPath -Name "DisplayYSize" -ErrorAction SilentlyContinue
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
$form.Size = New-Object System.Drawing.Size(500, 250)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.KeyPreview = $true

# Escape key handler
$form.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        $form.Close()
    }
})

# Description
$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Location = New-Object System.Drawing.Point(10, 10)
$descLabel.Size = New-Object System.Drawing.Size(470, 30)
$descLabel.Text = "Internal resolution: configurable in-game. Window resolution: new in 3.8, upscales display."
$form.Controls.Add($descLabel)

# Internal resolution inputs
$internalLabel = New-Object System.Windows.Forms.Label
$internalLabel.Location = New-Object System.Drawing.Point(103, 55)
$internalLabel.Size = New-Object System.Drawing.Size(120, 20)
$internalLabel.Text = "Internal (game):"
$form.Controls.Add($internalLabel)

$internalWidthBox = New-Object System.Windows.Forms.TextBox
$internalWidthBox.Location = New-Object System.Drawing.Point(228, 53)
$internalWidthBox.Size = New-Object System.Drawing.Size(80, 20)
$internalWidthBox.Text = $currentSettings.InternalWidth
$form.Controls.Add($internalWidthBox)

$xLabel1 = New-Object System.Windows.Forms.Label
$xLabel1.Location = New-Object System.Drawing.Point(313, 55)
$xLabel1.Size = New-Object System.Drawing.Size(15, 20)
$xLabel1.Text = "x"
$form.Controls.Add($xLabel1)

$internalHeightBox = New-Object System.Windows.Forms.TextBox
$internalHeightBox.Location = New-Object System.Drawing.Point(333, 53)
$internalHeightBox.Size = New-Object System.Drawing.Size(80, 20)
$internalHeightBox.Text = $currentSettings.InternalHeight
$form.Controls.Add($internalHeightBox)

# Window resolution inputs
$windowLabel = New-Object System.Windows.Forms.Label
$windowLabel.Location = New-Object System.Drawing.Point(103, 90)
$windowLabel.Size = New-Object System.Drawing.Size(120, 20)
$windowLabel.Text = "Scaled (window):"
$form.Controls.Add($windowLabel)

$windowWidthBox = New-Object System.Windows.Forms.TextBox
$windowWidthBox.Location = New-Object System.Drawing.Point(228, 88)
$windowWidthBox.Size = New-Object System.Drawing.Size(80, 20)
$windowWidthBox.Text = $currentSettings.WindowWidth
$form.Controls.Add($windowWidthBox)

$xLabel2 = New-Object System.Windows.Forms.Label
$xLabel2.Location = New-Object System.Drawing.Point(313, 90)
$xLabel2.Size = New-Object System.Drawing.Size(15, 20)
$xLabel2.Text = "x"
$form.Controls.Add($xLabel2)

$windowHeightBox = New-Object System.Windows.Forms.TextBox
$windowHeightBox.Location = New-Object System.Drawing.Point(333, 88)
$windowHeightBox.Size = New-Object System.Drawing.Size(80, 20)
$windowHeightBox.Text = $currentSettings.WindowHeight
$form.Controls.Add($windowHeightBox)

# Apply button
$applyButton = New-Object System.Windows.Forms.Button
$applyButton.Location = New-Object System.Drawing.Point(95, 130)
$applyButton.Size = New-Object System.Drawing.Size(150, 35)
$applyButton.Text = "Apply Settings"
$applyButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$applyButton.Add_Click({
    try {
        $success = Set-WAResolution -InternalWidth $internalWidthBox.Text `
                                     -InternalHeight $internalHeightBox.Text `
                                     -WindowWidth $windowWidthBox.Text `
                                     -WindowHeight $windowHeightBox.Text

        if ($success) {
            [System.Windows.Forms.MessageBox]::Show(
                "Settings applied successfully!",
                "Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Invalid resolution values! Please enter numbers only.",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$form.Controls.Add($applyButton)

# Remove button
$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Location = New-Object System.Drawing.Point(255, 130)
$removeButton.Size = New-Object System.Drawing.Size(150, 35)
$removeButton.Text = "Remove Scaling"
$removeButton.Add_Click({
    $result = Remove-WAScaling
    if ($result) {
        [System.Windows.Forms.MessageBox]::Show(
            "All scaling settings removed!",
            "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information)

        # Clear the text boxes
        $internalWidthBox.Text = ""
        $internalHeightBox.Text = ""
        $windowWidthBox.Text = ""
        $windowHeightBox.Text = ""
    }
})
$form.Controls.Add($removeButton)

# Show form
[void]$form.ShowDialog()
