# wormedit.ps1 - Worms Armageddon Registry Editor
# Double-click to run, or: powershell -ExecutionPolicy Bypass -File wormedit.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Registry path
$regPath = "HKCU:\SOFTWARE\Team17SoftwareLTD\WormsArmageddon\Options"

# Layout constants
$PADDING = 10  # Left padding
$LABEL_WIDTH = 110
$INPUT_WIDTH = 80
$SPACING = 15
$INPUT_HEIGHT = 22

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
    $label.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $label.BackColor = [System.Drawing.Color]::Transparent
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    return $label
}

# Helper to create textbox
function New-TextBox {
    param([int]$x, [int]$y, [int]$width, [string]$text)
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point($x, ($y - 2))
    $textBox.Size = New-Object System.Drawing.Size($width, $INPUT_HEIGHT)
    $textBox.Text = $text
    $textBox.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
    $textBox.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $textBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $textBox.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    return $textBox
}

# Helper to create combobox
function New-ComboBox {
    param([int]$x, [int]$y, [int]$width)
    $comboBox = New-Object System.Windows.Forms.ComboBox
    $comboBox.Location = New-Object System.Drawing.Point($x, ($y - 2))
    $comboBox.Size = New-Object System.Drawing.Size($width, $INPUT_HEIGHT)
    $comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $comboBox.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
    $comboBox.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $comboBox.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $comboBox.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
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
        "WindowXSize", "WindowYSize" | ForEach-Object {
            Remove-ItemProperty -Path $regPath -Name $_ -ErrorAction SilentlyContinue
        }
        return $true
    }
    catch { return $false }
}

# Load icon from file if it exists
function Get-FormIcon {
    param([string]$path = "icon.ico")
    if (Test-Path $path) {
        return New-Object System.Drawing.Icon($path)
    }
    return $null
}

# Create button icon from text (simple colored circle)
function New-ButtonIcon {
    param([string]$symbol, [System.Drawing.Color]$color)
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    $graphics = [System.Drawing.Graphics]::FromImage($bmp)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $brush = New-Object System.Drawing.SolidBrush($color)
    $graphics.FillEllipse($brush, 2, 2, 12, 12)
    $brush.Dispose()
    $graphics.Dispose()
    return $bmp
}

# Get current settings
$currentSettings = Get-CurrentSettings

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Worms Armageddon Scaler"
$form.Size = New-Object System.Drawing.Size(500, 300)  # Increased height for custom title bar
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "None"  # Remove Windows title bar
$form.KeyPreview = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(0, 0, 0)  # Pure black
$form.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$form.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) { $form.Close() } })

# Set form icon if available
$icon = Get-FormIcon
if ($icon) { $form.Icon = $icon }

# Set background image if available
if (Test-Path "fly.png") {
    $form.BackgroundImage = [System.Drawing.Image]::FromFile("fly.png")
    $form.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Tile
}

# Custom title bar
$titleBar = New-Object System.Windows.Forms.Panel
$titleBar.Location = New-Object System.Drawing.Point(0, 0)
$titleBar.Size = New-Object System.Drawing.Size(500, 30)
$titleBar.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)  # Slightly lighter black

# Title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(10, 7)
$titleLabel.Size = New-Object System.Drawing.Size(300, 16)
$titleLabel.Text = "Worms Armageddon Scaler"
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$titleBar.Controls.Add($titleLabel)

# Close button
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Location = New-Object System.Drawing.Point(465, 5)
$closeButton.Size = New-Object System.Drawing.Size(20, 20)
$closeButton.Text = "×"
$closeButton.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$closeButton.ForeColor = [System.Drawing.Color]::FromArgb(232, 17, 35)  # Red X
$closeButton.BackColor = [System.Drawing.Color]::Transparent
$closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$closeButton.FlatAppearance.BorderSize = 0
$closeButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)  # Slightly lighter on hover
$closeButton.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)  # Even lighter on click
$closeButton.TabStop = $false  # Prevents focus rectangle
if (Test-Path "close.png") {
    $originalImage = [System.Drawing.Image]::FromFile("close.png")
    # Resize image to fit button (16x16 for some padding)
    $resizedImage = New-Object System.Drawing.Bitmap(16, 16)
    $graphics = [System.Drawing.Graphics]::FromImage($resizedImage)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($originalImage, 0, 0, 16, 16)
    $graphics.Dispose()
    $closeButton.Image = $resizedImage
    $closeButton.Text = ""
    $closeButton.ImageAlign = [System.Drawing.ContentAlignment]::MiddleCenter
}
$closeButton.Add_Click({ $form.Close() })
$titleBar.Controls.Add($closeButton)

# Make title bar draggable
$script:dragging = $false
$script:dragOffset = New-Object System.Drawing.Point(0, 0)

$titleBar.Add_MouseDown({
    $script:dragging = $true
    $script:dragOffset = New-Object System.Drawing.Point($_.X, $_.Y)
})

$titleBar.Add_MouseMove({
    if ($script:dragging) {
        $form.Location = New-Object System.Drawing.Point(
            ($form.Location.X + $_.X - $script:dragOffset.X),
            ($form.Location.Y + $_.Y - $script:dragOffset.Y)
        )
    }
})

$titleBar.Add_MouseUp({
    $script:dragging = $false
})

# Also allow dragging from title label
$titleLabel.Add_MouseDown({
    $script:dragging = $true
    $script:dragOffset = New-Object System.Drawing.Point($_.X, $_.Y)
})

$titleLabel.Add_MouseMove({
    if ($script:dragging) {
        $form.Location = New-Object System.Drawing.Point(
            ($form.Location.X + $_.X - $script:dragOffset.X),
            ($form.Location.Y + $_.Y - $script:dragOffset.Y)
        )
    }
})

$titleLabel.Add_MouseUp({
    $script:dragging = $false
})

$form.Controls.Add($titleBar)

# Content panel with padding
$contentPanel = New-Object System.Windows.Forms.Panel
$contentPanel.Location = New-Object System.Drawing.Point(20, 50)
$contentPanel.Size = New-Object System.Drawing.Size(460, 210)
$contentPanel.BackColor = [System.Drawing.Color]::FromArgb(200, 30, 30, 30)  # Semi-transparent dark grey
$form.Controls.Add($contentPanel)

# Description
$contentPanel.Controls.Add((New-Label 10 10 380 "Set internal resolution, then pick a scale multiplier."))

# Calculate positions
$labelX = $PADDING
$input1X = $labelX + $LABEL_WIDTH + 2
$xLabelX = $input1X + $INPUT_WIDTH + 5
$input2X = $xLabelX + $SPACING + 5

# Internal resolution row
$y1 = 45
$contentPanel.Controls.Add((New-Label $labelX $y1 $LABEL_WIDTH "Internal (game):"))
$internalWidthBox = New-TextBox $input1X $y1 $INPUT_WIDTH $currentSettings.InternalWidth
$contentPanel.Controls.Add($internalWidthBox)
$contentPanel.Controls.Add((New-Label $xLabelX $y1 $SPACING "x"))
$internalHeightBox = New-TextBox $input2X $y1 $INPUT_WIDTH $currentSettings.InternalHeight
$contentPanel.Controls.Add($internalHeightBox)

# Scale factor row
$y2 = 80
$contentPanel.Controls.Add((New-Label $labelX $y2 $LABEL_WIDTH "Scale factor:"))
$scaleCombo = New-ComboBox $input1X $y2 180
$scaleCombo.Items.AddRange(@("1.25x", "1.5x", "1.75x", "2x", "Custom"))
$contentPanel.Controls.Add($scaleCombo)

# Preview label for calculated resolution
$previewLabel = New-Object System.Windows.Forms.Label
$previewLabel.Location = New-Object System.Drawing.Point(($input1X + 190), $y2)
$previewLabel.Size = New-Object System.Drawing.Size(150, $INPUT_HEIGHT)
$previewLabel.Text = ""
$previewLabel.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
$previewLabel.BackColor = [System.Drawing.Color]::Transparent
$previewLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$contentPanel.Controls.Add($previewLabel)

# Custom resolution controls (initially hidden)
$y3 = 115
$customLabel = New-Label $labelX $y3 $LABEL_WIDTH "Custom window:"
$customLabel.Visible = $false
$contentPanel.Controls.Add($customLabel)
$windowWidthBox = New-TextBox $input1X $y3 $INPUT_WIDTH $currentSettings.WindowWidth
$windowWidthBox.Visible = $false
$contentPanel.Controls.Add($windowWidthBox)
$customXLabel = New-Label $xLabelX $y3 $SPACING "x"
$customXLabel.Visible = $false
$contentPanel.Controls.Add($customXLabel)
$windowHeightBox = New-TextBox $input2X $y3 $INPUT_WIDTH $currentSettings.WindowHeight
$windowHeightBox.Visible = $false
$contentPanel.Controls.Add($windowHeightBox)

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
$applyButton.Location = New-Object System.Drawing.Point(70, 160)
$applyButton.Size = New-Object System.Drawing.Size(120, 35)
$applyButton.Text = "Apply Settings"
$applyButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$applyButton.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$applyButton.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$applyButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$applyButton.FlatAppearance.BorderSize = 0
$applyButton.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
if (Test-Path "reset.png") {
    $applyButton.Image = [System.Drawing.Image]::FromFile("reset.png")
    $applyButton.ImageAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $applyButton.TextImageRelation = [System.Windows.Forms.TextImageRelation]::ImageBeforeText
}
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
$contentPanel.Controls.Add($applyButton)

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Location = New-Object System.Drawing.Point(210, 160)
$removeButton.Size = New-Object System.Drawing.Size(130, 35)
$removeButton.Text = "Remove Scaling"
$removeButton.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
$removeButton.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$removeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$removeButton.FlatAppearance.BorderSize = 0
$removeButton.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
if (Test-Path "reset.png") {
    $removeButton.Image = [System.Drawing.Image]::FromFile("reset.png")
    $removeButton.ImageAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $removeButton.TextImageRelation = [System.Windows.Forms.TextImageRelation]::ImageBeforeText
}
$removeButton.Add_Click({
    if (Remove-WAScaling) {
        [System.Windows.Forms.MessageBox]::Show("Window scaling removed!", "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        $windowWidthBox.Text = $windowHeightBox.Text = ""
        $scaleCombo.SelectedIndex = -1
        $previewLabel.Text = ""
    }
})
$contentPanel.Controls.Add($removeButton)

# Show form
[void]$form.ShowDialog()
