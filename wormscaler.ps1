# wormedit.ps1 - Worms Armageddon Registry Editor
# Double-click to run, or: powershell -ExecutionPolicy Bypass -File wormedit.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Registry path
$regPath = "HKCU:\SOFTWARE\Team17SoftwareLTD\WormsArmageddon\Options"

# Layout constants
$PADDING = 10  # Left padding
$LABEL_WIDTH = 120
$INPUT_WIDTH = 80
$SPACING = 15
$INPUT_HEIGHT = 20

# Get current settings
function Get-CurrentSettings {
    try {
        if (-not (Test-Path $regPath)) { return @{} }

        $props = Get-ItemProperty -Path $regPath
        $settings = @{
            InternalWidth = if ($props.PSObject.Properties.Name -contains "DisplayXSize") { $props.DisplayXSize } else { "" }
            InternalHeight = if ($props.PSObject.Properties.Name -contains "DisplayYSize") { $props.DisplayYSize } else { "" }
            WindowWidth = if ($props.PSObject.Properties.Name -contains "WindowXSize") { $props.WindowXSize } else { "" }
            WindowHeight = if ($props.PSObject.Properties.Name -contains "WindowYSize") { $props.WindowYSize } else { "" }
        }

        # Calculate current scale if both internal and window are set
        if ($settings.InternalWidth -and $settings.WindowWidth -and $settings.InternalWidth -gt 0) {
            $scale = [Math]::Round($settings.WindowWidth / $settings.InternalWidth, 1)
            $settings.Scale = $scale
        } else {
            $settings.Scale = ""
        }

        return $settings
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

# Helper to create combobox
function New-ComboBox {
    param([int]$x, [int]$y, [int]$width)
    $comboBox = New-Object System.Windows.Forms.ComboBox
    $comboBox.Location = New-Object System.Drawing.Point($x, ($y - 2))
    $comboBox.Size = New-Object System.Drawing.Size($width, $INPUT_HEIGHT)
    $comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    return $comboBox
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
$form.Size = New-Object System.Drawing.Size(500, 270)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.KeyPreview = $true
$form.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { $form.Close() } })

# Description
$form.Controls.Add((New-Label 10 10 470 "Set internal resolution, then pick a scale multiplier."))

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

# Scale factor row
$y2 = 90
$form.Controls.Add((New-Label $labelX $y2 $LABEL_WIDTH "Scale factor:"))
$scaleCombo = New-ComboBox $input1X $y2 180
$scaleCombo.Items.AddRange(@("1.25x", "1.5x", "1.75x", "2x", "Custom"))
$form.Controls.Add($scaleCombo)

# Preview label for calculated resolution
$previewLabel = New-Object System.Windows.Forms.Label
$previewLabel.Location = New-Object System.Drawing.Point(($input1X + 190), $y2)
$previewLabel.Size = New-Object System.Drawing.Size(150, $INPUT_HEIGHT)
$previewLabel.Text = ""
$previewLabel.ForeColor = [System.Drawing.Color]::DarkGray
$form.Controls.Add($previewLabel)

# Custom resolution controls (initially hidden)
$y3 = 115
$customLabel = New-Label $labelX $y3 $LABEL_WIDTH "Custom window:"
$customLabel.Visible = $false
$form.Controls.Add($customLabel)
$windowWidthBox = New-TextBox $input1X $y3 $INPUT_WIDTH $currentSettings.WindowWidth
$windowWidthBox.Visible = $false
$form.Controls.Add($windowWidthBox)
$customXLabel = New-Label $xLabelX $y3 $SPACING "x"
$customXLabel.Visible = $false
$form.Controls.Add($customXLabel)
$windowHeightBox = New-TextBox $input2X $y3 $INPUT_WIDTH $currentSettings.WindowHeight
$windowHeightBox.Visible = $false
$form.Controls.Add($windowHeightBox)

# Function to update preview
function Update-Preview {
    $width = $internalWidthBox.Text
    $height = $internalHeightBox.Text
    $scale = $scaleCombo.SelectedItem

    if ($width -match '^\d+$' -and $height -match '^\d+$' -and $scale -and $scale -ne "Custom") {
        $multiplier = [decimal]($scale -replace 'x', '')
        $windowW = [int]([decimal]$width * $multiplier)
        $windowH = [int]([decimal]$height * $multiplier)
        $previewLabel.Text = "= ${windowW}x$windowH"
    } else {
        $previewLabel.Text = ""
    }
}

# Event handlers for real-time preview
$internalWidthBox.Add_TextChanged({ Update-Preview })
$internalHeightBox.Add_TextChanged({ Update-Preview })
$scaleCombo.Add_SelectedIndexChanged({
    $isCustom = $scaleCombo.SelectedItem -eq "Custom"
    $customLabel.Visible = $isCustom
    $windowWidthBox.Visible = $isCustom
    $customXLabel.Visible = $isCustom
    $windowHeightBox.Visible = $isCustom
    Update-Preview
})

# Initialize current settings
if ($currentSettings.Scale -ne "") {
    $scaleText = "$($currentSettings.Scale)x"
    $index = $scaleCombo.Items.IndexOf($scaleText)
    if ($index -ge 0) {
        $scaleCombo.SelectedIndex = $index
    } else {
        $scaleCombo.SelectedIndex = $scaleCombo.Items.IndexOf("Custom")
        # Show custom controls if current scale doesn't match presets
        $customLabel.Visible = $true
        $windowWidthBox.Visible = $true
        $customXLabel.Visible = $true
        $windowHeightBox.Visible = $true
    }
}

# Initial preview update
Update-Preview

# Buttons
$applyButton = New-Object System.Windows.Forms.Button
$applyButton.Location = New-Object System.Drawing.Point(95, 155)
$applyButton.Size = New-Object System.Drawing.Size(150, 35)
$applyButton.Text = "Apply Settings"
$applyButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$applyButton.Add_Click({
    $settings = @{
        InternalWidth = $internalWidthBox.Text
        InternalHeight = $internalHeightBox.Text
        WindowWidth = ""
        WindowHeight = ""
    }

    # Calculate window resolution from scale if not custom
    if ($scaleCombo.SelectedItem -and $scaleCombo.SelectedItem -ne "Custom") {
        if ($internalWidthBox.Text -match '^\d+$' -and $internalHeightBox.Text -match '^\d+$') {
            $multiplier = [decimal]($scaleCombo.SelectedItem -replace 'x', '')
            $settings.WindowWidth = [int]([decimal]$internalWidthBox.Text * $multiplier)
            $settings.WindowHeight = [int]([decimal]$internalHeightBox.Text * $multiplier)
        }
    } elseif ($scaleCombo.SelectedItem -eq "Custom") {
        $settings.WindowWidth = $windowWidthBox.Text
        $settings.WindowHeight = $windowHeightBox.Text
    }

    if (Set-WAResolution $settings) {
        [System.Windows.Forms.MessageBox]::Show("Settings applied successfully!", "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})
$form.Controls.Add($applyButton)

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Location = New-Object System.Drawing.Point(255, 155)
$removeButton.Size = New-Object System.Drawing.Size(150, 35)
$removeButton.Text = "Remove Scaling"
$removeButton.Add_Click({
    if (Remove-WAScaling) {
        [System.Windows.Forms.MessageBox]::Show("All scaling settings removed!", "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        $internalWidthBox.Text = $internalHeightBox.Text = $windowWidthBox.Text = $windowHeightBox.Text = ""
        $scaleCombo.SelectedIndex = -1
        $previewLabel.Text = ""
    }
})
$form.Controls.Add($removeButton)

# Show form
[void]$form.ShowDialog()
