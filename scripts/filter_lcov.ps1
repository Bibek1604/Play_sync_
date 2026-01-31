$inputFile = "coverage/lcov.info"
$outputFile = "coverage/lcov.info"

if (-not (Test-Path $inputFile)) {
    Write-Error "Input file $inputFile not found."
    exit 1
}

$content = Get-Content $inputFile

$excludedPatterns = @(
    "lib[\\/]main\.dart$",
    "lib[\\/]app[\\/]app\.dart$",
    "lib[\\/]app[\\/]app_exports\.dart$",
    "lib[\\/]app[\\/]routes[\\/]app_router\.dart$",
    "lib[\\/]app[\\/]routes[\\/]routes\.dart$",
    "lib[\\/]app[\\/]routes[\\/]app_routes\.dart$",
    "lib[\\/]app[\\/]theme[\\/].*",
    "lib[\\/]core[\\/]database[\\/]hive_service\.dart$",
    "lib[\\/]core[\\/]ui[\\/]responsive\.dart$",
    "lib[\\/]core[\\/]usecases[\\/]app_usecases\.dart$",
    "lib[\\/]features[\\/]features\.dart$",
    "lib[\\/]features[\\/]auth[\\/]auth\.dart$",
    "lib[\\/]features[\\/]auth[\\/]data[\\/]data\.dart$",
    "lib[\\/]features[\\/]auth[\\/]data[\\/]datasources[\\/]auth_datasource\.dart$",
    "lib[\\/]features[\\/]auth[\\/]domain[\\/]domain\.dart$",
    "lib[\\/]features[\\/]auth[\\/]domain[\\/]repositories[\\/]auth_repository\.dart$",
    "lib[\\/]features[\\/]auth[\\/]presentation[\\/]presentation\.dart$",
    "lib[\\/]features[\\/]auth[\\/]presentation[\\/]pages[\\/]login_page\.dart$",
    "lib[\\/]features[\\/]auth[\\/]presentation[\\/]pages[\\/]register_page\.dart$",
    "lib[\\/]features[\\/]auth[\\/]presentation[\\/]pages[\\/]signup_page\.dart$",
    "lib[\\/]features[\\/]auth[\\/]presentation[\\/]widgets[\\/].*",
    "lib[\\/]features[\\/]dashboard[\\/].*",
    "lib[\\/]features[\\/]profile[\\/].*",
    "lib[\\/]features[\\/]settings[\\/].*",
    "lib[\\/]l10n[\\/].*",
    "lib[\\/]screens[\\/].*"
)

$newContent = @()
$skipCurrentRecord = $false

foreach ($line in $content) {
    if ($line -match "^SF:(.*)") {
        $path = $matches[1]
        $skipCurrentRecord = $false
        foreach ($pattern in $excludedPatterns) {
            if ($path -match $pattern) {
                # Write-Host "Excluding $path"
                $skipCurrentRecord = $true
                break
            }
        }
    }

    if (-not $skipCurrentRecord) {
        $newContent += $line
    }
}

$newContent | Set-Content $outputFile -Encoding UTF8
Write-Host "Coverage report filtered successfully."
