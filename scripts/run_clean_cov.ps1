$excludes = @(
    "lib/main.dart",
    "lib/app/app.dart",
    "lib/app/app_exports.dart",
    "lib/app/routes/app_router.dart",
    "lib/app/routes/routes.dart",
    "lib/app/theme/**",
    "lib/core/database/hive_service.dart",
    "lib/core/ui/responsive.dart",
    "lib/core/usecases/app_usecases.dart",
    "lib/features/features.dart",
    "lib/features/auth/auth.dart",
    "lib/features/auth/data/data.dart",
    "lib/features/auth/data/datasources/auth_datasource.dart",
    "lib/features/auth/domain/domain.dart",
    "lib/features/auth/domain/repositories/auth_repository.dart",
    "lib/features/auth/presentation/presentation.dart",
    "lib/features/auth/presentation/pages/login_page.dart",
    "lib/features/auth/presentation/pages/register_page.dart",
    "lib/features/auth/presentation/pages/signup_page.dart",
    "lib/features/auth/presentation/widgets/**",
    "lib/features/dashboard/**",
    "lib/features/profile/**",
    "lib/features/settings/**",
    "lib/l10n/**",
    "lib/screens/**"
) -join ","

Write-Host "Running coverage report excluding untested files..."
dart run test_cov_console -e $excludes
