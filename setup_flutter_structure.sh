#!/bin/bash

# Création des dossiers
mkdir -p lib/{core/{env,errors,network,storage,utils},features/{auth/{data,domain,presentation},calculator/{data,domain,presentation,pdf},admin/{data,domain,presentation},home/presentation},l10n}

# Fichiers racine
touch lib/{app.dart,bootstrap.dart,main.dart}

# Core
touch lib/core/env/env.dart
touch lib/core/errors/failures.dart
touch lib/core/network/dio_client.dart
touch lib/core/storage/secure_storage.dart
touch lib/core/utils/formatters.dart

# Auth
touch lib/features/auth/data/{auth_api.dart,auth_repository.dart}
touch lib/features/auth/domain/{user.dart,tokens.dart}
touch lib/features/auth/presentation/login_page.dart
touch lib/features/auth/providers.dart

# Calculator
touch lib/features/calculator/data/calculator_service.dart
touch lib/features/calculator/domain/calculator_models.dart
touch lib/features/calculator/presentation/calculate_page.dart
touch lib/features/calculator/pdf/pdf_report.dart
touch lib/features/calculator/providers.dart

# Admin
touch lib/features/admin/data/admin_api.dart
touch lib/features/admin/domain/admin_models.dart
touch lib/features/admin/presentation/{admin_shell_page.dart,admin_dashboard_page.dart,contents_page.dart,equipments_page.dart,history_page.dart,parameters_page.dart,profile_page.dart,users_page.dart}
touch lib/features/admin/providers.dart

# Home
touch lib/features/home/presentation/home_page.dart

# Confirmation
echo "✅ Structure Flutter créée avec succès !"
