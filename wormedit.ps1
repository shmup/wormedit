# wormedit.ps1 - Worms Armageddon Registry Editor
# Double-click to run, or: powershell -ExecutionPolicy Bypass -File wormedit.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Registry path
$regPath = "HKCU:\SOFTWARE\Team17SoftwareLTD\WormsArmageddon\Options"

# Layout constants
$PADDING = 103  # Left padding for centering
$LABEL_WIDTH = 120
$INPUT_WIDTH = 80
$SPACING = 15
$INPUT_HEIGHT = 20

# Get current settings
function Get-CurrentSettings {
    try {
        if (-not (Test-Path $regPath)) { return @{} }

        $props = Get-ItemProperty -Path $regPath
        return @{
            InternalWidth = if ($props.PSObject.Properties.Name -contains "DisplayXSize") { $props.DisplayXSize } else { "" }
            InternalHeight = if ($props.PSObject.Properties.Name -contains "DisplayYSize") { $props.DisplayYSize } else { "" }
            WindowWidth = if ($props.PSObject.Properties.Name -contains "WindowXSize") { $props.WindowXSize } else { "" }
            WindowHeight = if ($props.PSObject.Properties.Name -contains "WindowYSize") { $props.WindowYSize } else { "" }
        }
    }
    catch {
        return @{}
    }
}

# Helper to create label
function New-Label {
    param([int]$x, [int]$y, [int]$width, [string]$text)
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point($x, $y)
    $label.Size = New-Object System.Drawing.Size($width, $INPUT_HEIGHT)
    $label.Text = $text
    return $label
}

# Helper to create textbox
function New-TextBox {
    param([int]$x, [int]$y, [int]$width, [string]$text)
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point($x, ($y - 2))
    $textBox.Size = New-Object System.Drawing.Size($width, $INPUT_HEIGHT)
    $textBox.Text = $text
    return $textBox
}

# Set registry values
function Set-WAResolution {
    param($settings)

    try {
        if (-not (Test-Path $regPath)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Worms Armageddon registry key not found!`nMake sure the game is installed.",
                "Error", [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error)
            return $false
        }

        $mapping = @{
            InternalWidth = "DisplayXSize"; InternalHeight = "DisplayYSize"
            WindowWidth = "WindowXSize"; WindowHeight = "WindowYSize"
        }

        foreach ($key in $mapping.Keys) {
            if ($settings[$key] -ne "") {
                Set-ItemProperty -Path $regPath -Name $mapping[$key] -Value ([int]$settings[$key]) -Type DWord
            }
        }
        return $true
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error: $_", "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
}

# Remove all scaling settings
function Remove-WAScaling {
    try {
        "DisplayXSize", "DisplayYSize", "WindowXSize", "WindowYSize" | ForEach-Object {
            Remove-ItemProperty -Path $regPath -Name $_ -ErrorAction SilentlyContinue
        }
        return $true
    }
    catch { return $false }
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
$form.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { $form.Close() } })

# Description
$form.Controls.Add((New-Label 10 10 470 "Internal resolution: configurable in-game. Window resolution: new in 3.8, upscales display."))

# Calculate positions
$labelX = $PADDING
$input1X = $labelX + $LABEL_WIDTH + 5
$xLabelX = $input1X + $INPUT_WIDTH + 5
$input2X = $xLabelX + $SPACING + 5

# Internal resolution row
$y1 = 55
$form.Controls.Add((New-Label $labelX $y1 $LABEL_WIDTH "Internal (game):"))
$internalWidthBox = New-TextBox $input1X $y1 $INPUT_WIDTH $currentSettings.InternalWidth
$form.Controls.Add($internalWidthBox)
$form.Controls.Add((New-Label $xLabelX $y1 $SPACING "x"))
$internalHeightBox = New-TextBox $input2X $y1 $INPUT_WIDTH $currentSettings.InternalHeight
$form.Controls.Add($internalHeightBox)

# Window resolution row
$y2 = 90
$form.Controls.Add((New-Label $labelX $y2 $LABEL_WIDTH "Scaled (window):"))
$windowWidthBox = New-TextBox $input1X $y2 $INPUT_WIDTH $currentSettings.WindowWidth
$form.Controls.Add($windowWidthBox)
$form.Controls.Add((New-Label $xLabelX $y2 $SPACING "x"))
$windowHeightBox = New-TextBox $input2X $y2 $INPUT_WIDTH $currentSettings.WindowHeight
$form.Controls.Add($windowHeightBox)

# Buttons
$applyButton = New-Object System.Windows.Forms.Button
$applyButton.Location = New-Object System.Drawing.Point(95, 130)
$applyButton.Size = New-Object System.Drawing.Size(150, 35)
$applyButton.Text = "Apply Settings"
$applyButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$applyButton.Add_Click({
    $settings = @{
        InternalWidth = $internalWidthBox.Text; InternalHeight = $internalHeightBox.Text
        WindowWidth = $windowWidthBox.Text; WindowHeight = $windowHeightBox.Text
    }

    if (Set-WAResolution $settings) {
        [System.Windows.Forms.MessageBox]::Show("Settings applied successfully!", "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})
$form.Controls.Add($applyButton)

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Location = New-Object System.Drawing.Point(255, 130)
$removeButton.Size = New-Object System.Drawing.Size(150, 35)
$removeButton.Text = "Remove Scaling"
$removeButton.Add_Click({
    if (Remove-WAScaling) {
        [System.Windows.Forms.MessageBox]::Show("All scaling settings removed!", "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        $internalWidthBox.Text = $internalHeightBox.Text = $windowWidthBox.Text = $windowHeightBox.Text = ""
    }
})
$form.Controls.Add($removeButton)

# Show form
[void]$form.ShowDialog()
