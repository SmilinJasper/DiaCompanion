# AGENTS.md — DiaCompanion

> This file provides instructions for AI agents contributing to the DiaCompanion codebase. It describes project conventions, architecture decisions, and safety-critical constraints that must be respected.

## Project Overview

DiaCompanion is a Flutter Android application for diabetes management. It combines local data storage (Hive), predictive analytics (weighted linear regression, logistic regression), interactive charting (fl_chart), and an AI chatbot (Google Gemini API) into a single patient-facing tool.

**Package name:** `com.glucopredict.gluco_predict`
**Primary language:** Dart (Flutter)
**State management:** Provider (`ChangeNotifierProvider`)
**Local database:** Hive (NoSQL, file-based)
**AI backend:** Google Gemini 2.5 Flash via `google_generative_ai` package

## Directory Structure

```
lib/
├── app.dart                  # Root widget — registers all providers here
├── main.dart                 # Entry point — initialises Hive, ChatbotService
├── core/
│   ├── constants/            # App-wide constants (app name, version, layout)
│   ├── theme/                # Material Design 3 theme definitions
│   └── services/             # Stateless service classes (database, parsing, prediction, AI)
├── features/
│   ├── home/                 # Home dashboard (providers/, presentation/pages/, presentation/widgets/)
│   ├── data_center/          # Data upload, charts, glucose record management
│   ├── diabot/               # AI chatbot UI and provider
│   └── risk_predictor/       # Diabetes risk prediction UI, gauge widget, provider
└── shared/
    └── models/               # Data classes shared across features (GlucoseRecord, DiabetesInput, etc.)
```

## Conventions

### Adding a New Feature

1. Create a directory under `lib/features/<feature_name>/`
2. Follow the existing structure: `providers/`, `presentation/pages/`, `presentation/widgets/`
3. Register any new `ChangeNotifierProvider` in `lib/app.dart`
4. Add navigation from `home_page.dart` or the relevant parent screen

### Services

Services in `lib/core/services/` are **stateless singletons** using private constructors (`ClassName._()`) and static methods. They do not depend on Flutter widgets or BuildContext.

### Models

Data models live in `lib/shared/models/`. If a model needs Hive persistence, annotate it with `@HiveType` and run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### State Management

Use `ChangeNotifier` + `Provider`. Each feature should have its own provider. Access providers in widgets via `context.watch<T>()` (reactive) or `context.read<T>()` (one-shot).

### Naming

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Private members: `_prefixed`
- Constants: `camelCase` (Dart convention)

## API Key Handling

The Gemini API key is loaded at compile time via `--dart-define-from-file=dart_defines.env`. It is accessed in code through `String.fromEnvironment('GEMINI_API_KEY')`. The `dart_defines.env` file is gitignored.

**Never hardcode API keys in source files.**

## Safety-Critical Constraints

> [!CAUTION]
> This is a health-related application. The following rules are non-negotiable.

1. **DiaBot system prompt** (`lib/core/services/chatbot_service.dart`):
   - Must always include a medical disclaimer in responses
   - Must never diagnose, prescribe, or adjust medication
   - Must refer to emergency services for safety-critical symptoms (DKA, severe hypo, chest pain)
   - Must align with ADA Standards of Care

2. **Prediction models**:
   - The diabetes risk predictor uses pre-trained logistic regression weights — do not modify these weights without retraining and validation against the Pima dataset
   - Glucose predictions are clamped to physiological limits (30–500 mg/dL) — do not remove this safety bound
   - Risk tiers (Low <35%, Moderate 35–65%, High >65%) were chosen to err on the side of caution

3. **Medical disclaimer** must appear:
   - On the Risk Predictor results page
   - In every DiaBot response (enforced via system prompt)
   - In the README

## Android Configuration

Permissions required in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```
These must also be present in `debug/` and `profile/` manifests.

## Testing & Verification

Before submitting changes, always run:
```bash
flutter analyze
```
Ensure zero issues before committing. For Hive model changes, regenerate adapters:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Sample Data

Test data files are in `test_data/`:
- `sample_glucose.csv` — 15 glucose readings for Data Center upload
- `sample_diabetes_prediction.csv` — 15 patient profiles for risk prediction

Use these for manual QA when modifying upload parsing or prediction logic.
