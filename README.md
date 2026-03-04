<div align="center">

# DiaCompanion

**An intelligent, clinically-informed diabetes management companion built to empower patients through predictive analytics, real-time glucose insights, and compassionate AI-driven support.**

![Flutter](https://img.shields.io/badge/Flutter-3.11-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white)
![Gemini AI](https://img.shields.io/badge/Gemini_AI-2.5_Flash-4285F4?logo=google&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)

</div>

---

## Clinical Overview

DiaCompanion was conceived at the intersection of healthcare informatics and mobile technology. Informed by clinical nursing insights and grounded in evidence-based diabetes care standards — including the ADA Standards of Care — the application is designed to serve as a **proactive companion** for individuals managing Type 1 and Type 2 diabetes.

Rather than replacing clinical judgement, DiaCompanion extends the continuum of care beyond the clinic. It gives patients the ability to observe their own patterns, understand their risk profile, and ask informed questions — all within a tool that respects the boundaries between patient education and medical practice.

This project reflects a commitment to academic leadership in health technology: bridging the gap between what patients experience daily and what clinicians see periodically.

---

## Core Features

### 🔬 Predictive Diagnostics — Diabetes Risk Assessment

DiaCompanion integrates a **logistic regression classifier** trained on the widely-studied [Pima Indians Diabetes Dataset](https://www.kaggle.com/datasets/uciml/pima-indians-diabetes-database), enabling early risk detection from eight standard clinical parameters:

| Parameter | Unit | Example |
|-----------|------|---------|
| Pregnancies | count | 6 |
| Glucose (OGTT) | mg/dL | 148 |
| Blood Pressure (diastolic) | mm Hg | 72 |
| Skin Thickness (triceps fold) | mm | 35 |
| Insulin (2-hr serum) | µU/mL | 0 |
| BMI | kg/m² | 33.6 |
| Diabetes Pedigree Function | score | 0.627 |
| Age | years | 50 |

Users can enter values manually via interactive sliders or upload a CSV file for batch prediction. Results are presented as:

- A **visual risk gauge** (Low / Moderate / High) with probability percentage
- A **per-feature contribution breakdown** identifying which factors are driving risk
- A clear **medical disclaimer** reminding users to consult their healthcare provider

### 📈 Glucose Forecasting — 3-Hour Trend Prediction

Using weighted linear regression on historical blood glucose data (prioritising the most recent 24 hours), the forecasting engine generates **12 prediction points at 15-minute intervals**, projecting glucose trends up to 3 hours into the future.

Key characteristics:
- **Exponential recency weighting** — newer readings have greater influence
- **Confidence scoring** — based on R² value and data density, with decay for longer horizons
- **Physiological clamping** — predictions are bounded to 30–500 mg/dL
- **Visual integration** — forecast appears as a dashed amber line on the glucose trend chart

### 🤖 DiaBot — Gemini-Powered Conversational Assistant

DiaBot is an empathetic, medically-cautious AI assistant powered by Google's **Gemini 2.5 Flash** model. It helps users understand their glucose patterns, plan meals, and learn about diabetes management — all within a conversational interface.

The system prompt ensures DiaBot:
- Aligns advice with **ADA Standards of Care 2024/2025**
- Covers glucose trends, nutrition, exercise, medication awareness, and lifestyle
- **Never diagnoses, prescribes, or adjusts medication**
- Includes a medical disclaimer in every response
- Immediately refers users to emergency services when safety-critical symptoms are described

### 📊 Data Center — Import, Visualise, Manage

The Data Center provides a centralised hub for glucose data management:
- **CSV/JSON file upload** with format validation
- **Interactive line charts** (fl_chart) with time-range filtering (24h, 7d, 30d, all)
- **Dashboard statistics** — average, min, max glucose, prediction confidence
- **Manual glucose logging** via a polished bottom-sheet form

### 🏠 Home Dashboard — Live Quick Overview

The home screen displays real-time stats derived from stored data:
- **Last Reading** — most recent glucose value
- **Trend** — Rising, Falling, or Stable based on prediction trajectory
- **Readings Today** — count of entries logged today
- **7-Day Average** — rolling weekly glucose mean

---

## Technical Architecture

```
lib/
├── app.dart                         # Root widget, MultiProvider setup
├── main.dart                        # Entry point, Hive + Gemini initialisation
├── core/
│   ├── constants/app_constants.dart  # App-wide configuration
│   ├── theme/app_theme.dart          # Material Design 3 theming
│   └── services/
│       ├── database_service.dart     # Hive CRUD operations
│       ├── file_parser_service.dart  # CSV/JSON parsing & validation
│       ├── prediction_service.dart   # Weighted linear regression forecasting
│       ├── chatbot_service.dart      # Gemini API integration & system prompt
│       └── diabetes_predictor.dart   # Logistic regression risk classifier
├── features/
│   ├── home/                        # Dashboard, greeting, quick stats
│   ├── data_center/                 # Upload, charts, data management
│   ├── diabot/                      # Chat UI, streaming responses
│   └── risk_predictor/              # Manual entry, CSV batch, risk gauge
└── shared/
    └── models/
        ├── glucose_record.dart       # Hive-annotated glucose data model
        ├── glucose_prediction.dart   # Forecast data class
        └── diabetes_input.dart       # Clinical input model for risk prediction
```

### State Management

The application uses **Provider** (`ChangeNotifierProvider`) for reactive state management across four providers:
- `HomeProvider` — greeting, time-based updates
- `DataCenterProvider` — records, predictions, chart filtering
- `DiaBotProvider` — chat messages, streaming state
- `RiskPredictorProvider` — form fields, prediction results

### Key Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `hive` / `hive_flutter` | Local NoSQL storage |
| `fl_chart` | Interactive glucose trend charts |
| `file_picker` | CSV/JSON file selection |
| `google_generative_ai` | Gemini API integration |
| `intl` | Date/time formatting |

---

## Setup & Installation

### Prerequisites

- Flutter SDK ≥ 3.11
- Android SDK (API 34 recommended)
- A [Google AI Studio](https://aistudio.google.com/) API key for Gemini

### Steps

```bash
# 1. Clone the repository
git clone <repository-url>
cd App

# 2. Install dependencies
flutter pub get

# 3. Create your environment file with the Gemini API key
echo "GEMINI_API_KEY=your_api_key_here" > dart_defines.env

# 4. Run on a connected device or emulator
flutter run --dart-define-from-file=dart_defines.env

# 5. Build a release APK
flutter build apk --release --dart-define-from-file=dart_defines.env
```

### Android Permissions

The following permissions are declared in the Android manifests and are required for the app to function correctly:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

> [!IMPORTANT]
> If you encounter a `SocketException: Failed host lookup` error, verify that **both** `INTERNET` and `ACCESS_NETWORK_STATE` permissions are present in `android/app/src/main/AndroidManifest.xml` (above the `<application>` tag). The debug and profile manifests should also include these for development builds.

### API Key Security

The Gemini API key is injected at compile time via `--dart-define-from-file` and is never stored in source code. The `dart_defines.env` file is included in `.gitignore` to prevent accidental commits.

---

## Data Standards

### Glucose Record Format (Data Center)

For uploading historical blood glucose data, use a CSV file with the following columns:

```csv
timestamp,glucose_level,carbs_intake,insulin_dose
2026-03-03T06:00:00,95,0,4
2026-03-03T07:30:00,142,55,6
2026-03-03T09:00:00,168,30,3
```

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `timestamp` | ISO 8601 datetime | ✅ | When the reading was taken |
| `glucose_level` | number (mg/dL) | ✅ | Blood glucose value |
| `carbs_intake` | number (grams) | ❌ | Carbohydrates consumed |
| `insulin_dose` | number (units) | ❌ | Insulin administered |

### Diabetes Risk Prediction Format

For batch diabetes risk prediction, use a CSV with the eight clinical parameters:

```csv
pregnancies,glucose,blood_pressure,skin_thickness,insulin,bmi,diabetes_pedigree,age
6,148,72,35,0,33.6,0.627,50
1,85,66,29,0,26.6,0.351,31
```

All columns are required. Values should be numeric. A header row is optional but recommended.

---

## Medical Disclaimer

> **⚕️ IMPORTANT: DiaCompanion is a supportive health management tool and is NOT a substitute for professional medical diagnosis, treatment, or advice. All predictions, risk assessments, and AI-generated responses are for informational and educational purposes only. Always consult your physician, endocrinologist, or qualified healthcare provider before making any decisions about your diabetes management. If you experience a medical emergency, call your local emergency services immediately.**

---

## Acknowledgements

- **Pima Indians Diabetes Dataset** — Originally from the National Institute of Diabetes and Digestive and Kidney Diseases, made available through the UCI Machine Learning Repository.
- **American Diabetes Association** — Clinical guidelines referenced in DiaBot's system prompt follow the ADA Standards of Care.
- **Google Gemini AI** — Powers the DiaBot conversational assistant.

---

<div align="center">

Built with care for those who live with diabetes every day. 💙

</div>
