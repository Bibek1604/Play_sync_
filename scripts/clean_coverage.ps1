$patterns = @(
    'lib[\\/]main\.dart',
    'lib[\\/]app[\\/].*',
    'lib[\\/]core[\\/]database[\\/]hive_service\.dart',
    'lib[\\/]core[\\/]ui[\\/].*',
    'lib[\\/]core[\\/]usecases[\\/].*',
    'lib[\\/]features[\\/]features\.dart',
    'lib[\\/]features[\\/]auth[\\/]auth\.dart',
    'lib[\\/]features[\\/]auth[\\/]data[\\/]data\.dart',
    'lib[\\/]features[\\/]auth[\\/]data[\\/]datasources[\\/]auth_datasource\.dart',
    'lib[\\/]features[\\/]auth[\\/]domain[\\/]domain\.dart',
    'lib[\\/]features[\\/]auth[\\/]domain[\\/]repositories[\\/]auth_repository\.dart',
    'lib[\\/]features[\\/]auth[\\/]presentation[\\/]presentation\.dart',
    'lib[\\/]features[\\/]auth[\\/]presentation[\\/]widgets[\\/].*',
    'lib[\\/]features[\\/]auth[\\/]presentation[\\/]pages[\\/].*',
    'lib[\\/]features[\\/]dashboard[\\/].*',
    'lib[\\/]features[\\/]profile[\\/].*',
    'lib[\\/]features[\\/]settings[\\/].*',
    'lib[\\/]l10n[\\/].*',
    'lib[\\/]screens[\\/].*'
)

$argsList = @("-f", "coverage/lcov.info")
foreach ($p in $patterns) {
    $argsList += "-r"
    $argsList += $p
}

dart run remove_from_coverage @argsList
