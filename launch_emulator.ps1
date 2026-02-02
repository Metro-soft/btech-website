$emulatorPath = "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe"
$avdName = "Pixel_XL"

Write-Host "Starting Android Emulator ($avdName) in Safe GPU Mode..." -ForegroundColor Cyan

# Check if emulator exists
if (-not (Test-Path $emulatorPath)) {
    Write-Error "Emulator executable not found at: $emulatorPath"
    exit 1
}

# Launch with angle_indirect (stable for Intel GPUs) or swiftshader_indirect (software rendering)
& $emulatorPath -avd $avdName -gpu angle_indirect

if ($LASTEXITCODE -ne 0) {
    Write-Warning "First attempt failed. Trying Software Rendering (SwiftShader)..."
    & $emulatorPath -avd $avdName -gpu swiftshader_indirect
}
