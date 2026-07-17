# MathWorld Mobile



# 📚 MathWorld

### منصة تعليمية تفاعلية لحل المسائل الرياضية

تطبيق Flutter حديث يهدف إلى مساعدة الطلاب على تعلم الرياضيات بطريقة تفاعلية من خلال مراحل دراسية، تصنيفات، مسائل متعددة الخيارات، حلول تفصيلية، ونظام نقاط وإحصائيات شخصية.

---

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Dart](https://img.shields.io/badge/Dart-3.x-blue)
![Riverpod](https://img.shields.io/badge/Riverpod-State%20Management-green)
![License](https://img.shields.io/badge/License-MIT-orange)



---

# ✨ المميزات

## 🔐 نظام المصادقة

* تسجيل الدخول.
* إنشاء حساب جديد.
* حفظ الجلسة باستخدام JWT.
* تسجيل الخروج.
* استرجاع الجلسة تلقائياً.
* تخزين آمن للبيانات باستخدام Flutter Secure Storage.

---

## 🏠 الصفحة الرئيسية

تم إعادة تصميم الصفحة الرئيسية لتصبح لوحة تحكم متكاملة للمستخدم وتحتوي على:

* ترحيب بالمستخدم.
* إحصائيات الحساب.
* مجموع النقاط.
* نسبة النجاح.
* عدد المسائل المحلولة.
* عدد المفضلات.
* آخر النشاطات.
* آخر المسائل المحلولة.
* زر سريع للانتقال إلى المراحل.

---

## 📖 المراحل الدراسية

يعرض التطبيق جميع المراحل الدراسية بشكل منظم.

كل مرحلة تحتوي على:

* مجموعة من التصنيفات.
* عدد المسائل.
* إمكانية الانتقال مباشرة للتصنيفات.

---

## 📂 التصنيفات

كل مرحلة تحتوي على عدة تصنيفات مثل:

* الجبر
* الهندسة
* التفاضل
* التكامل
* الإحصاء
* الاحتمالات

---

## 🧮 نظام المسائل

يدعم التطبيق:

* البحث.
* التصفية حسب المرحلة.
* التصفية حسب التصنيف.
* Pagination.
* عرض عدد النقاط.
* عدد المشاهدات.
* المفضلة.
* حالة الحل.

---

## ✏️ حل المسائل

كل سؤال يحتوي على:

* عنوان.
* نص السؤال.
* خيارات متعددة.
* معادلات رياضية LaTeX.
* عدد النقاط.
* التصنيف.
* عدد المشاهدات.

بعد الإجابة يتم عرض:

* هل الإجابة صحيحة.
* عدد النقاط المكتسبة.
* الحل التفصيلي.
* فيديو شرح (عند توفره).

---

## ⭐ المفضلة

يمكن للمستخدم:

* إضافة للمفضلة.
* إزالة من المفضلة.
* مشاهدة جميع المفضلات.

---

## 📈 الإحصائيات

يعرض التطبيق:

* عدد المسائل المحلولة.
* مجموع النقاط.
* نسبة النجاح.
* المفضلات.
* آخر النشاطات.

---

## 🌙 الإعدادات

يمكن للمستخدم تغيير:

* اللغة.
* الثيم.
* الوضع الفاتح.
* الوضع الداكن.
* حسب إعدادات الجهاز.

---

## 🌍 تعدد اللغات

مدعوم حالياً:

* العربية 🇸🇦
* English 🇺🇸

---

## 📐 دعم المعادلات الرياضية

يستخدم التطبيق:

```latex
x^2+y^2=z^2

\int_0^1 x dx

\sqrt{x}
```

ويتم عرضها باستخدام:

```
flutter_math_fork
```

---

# 🏗️ Architecture

يتبع المشروع بنية منظمة وقابلة للتوسع:

```text
lib
│
├── config
│   ├── app_routes.dart
│   ├── constants.dart
│   └── theme.dart
│
├── models
│
├── providers
│
├── services
│
├── screens
│
├── widgets
│
└── main.dart
```

---

# 🛠️ التقنيات المستخدمة

| التقنية                | الاستخدام        |
| ---------------------- | ---------------- |
| Flutter                | تطوير التطبيق    |
| Riverpod               | إدارة الحالة     |
| Dio                    | الاتصال بالـ API |
| Hive                   | التخزين المحلي   |
| Flutter Secure Storage | حفظ JWT          |
| Easy Localization      | تعدد اللغات      |
| Google Fonts           | الخطوط           |
| Flutter Math Fork      | معادلات LaTeX    |
| Cached Network Image   | تحميل الصور      |
| Shimmer                | Loading Skeleton |
| Lottie                 | الرسوم المتحركة  |
| Animate Do             | Animations       |
| Shared Preferences     | الإعدادات        |
| Connectivity Plus      | مراقبة الإنترنت  |

---

# 📱 شاشات التطبيق

* Splash
* Login
* Register
* Home
* Stages
* Categories
* Problems
* Problem Details
* Favorites
* Solved Problems
* Settings

---

# 🔄 سير عمل التطبيق

```text
Splash

↓

Login / Register

↓

Home

↓

Stages

↓

Categories

↓

Problems

↓

Problem Details

↓

Submit Answer

↓

Solution
```

---

# 📦 إدارة الحالة

يعتمد المشروع بالكامل على **Riverpod**.

أهم Providers:

* AuthProvider
* SettingsProvider
* DashboardProvider
* StagesProvider
* CategoriesProvider
* ProblemsProvider
* FavoritesProvider
* SolvedProblemsProvider

---

# 🔒 التخزين المحلي

يستخدم المشروع:

## Hive

لتخزين:

* المستخدم.
* المفضلة.
* Cache.
* اللغة.
* الثيم.

## Flutter Secure Storage

لتخزين:

* JWT Token

---

# 🌐 Backend

يتصل التطبيق بخادم REST API.

يشمل:

* Authentication
* Stages
* Categories
* Problems
* Dashboard
* Favorites
* Statistics

---

# 📂 Assets

```text
assets
│
├── images
├── lottie
└── translations
```

---

# 📦 Packages

```yaml
flutter_riverpod
riverpod_annotation
dio
hive
hive_flutter
flutter_secure_storage
easy_localization
google_fonts
cached_network_image
shimmer
flutter_spinkit
connectivity_plus
http
shared_preferences
animate_do
lottie
flutter_dotenv
flutter_math_fork
```

---

# 🚀 تشغيل المشروع

## 1. تثبيت الحزم

```bash
flutter pub get
```

---

## 2. إنشاء ملفات Hive

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 3. تشغيل التطبيق

```bash
flutter run
```

---

## 4. تحليل المشروع

```bash
flutter analyze
```

---

# 📋 متطلبات المشروع

* Flutter 3.x
* Dart 3.x
* Android Studio أو VS Code
* Android SDK أو Xcode (لـ iOS)

---

# 🔮 التطويرات المستقبلية

* تسجيل الدخول عبر Google.
* تسجيل الدخول عبر Apple.
* استعادة كلمة المرور.
* الإشعارات (Push Notifications).
* تحميل الدروس للعمل بدون إنترنت.
* تتبع تقدم الطالب لكل مرحلة.
* نظام الإنجازات (Achievements).
* لوحة ترتيب المستخدمين (Leaderboard).
* الاختبارات التجريبية.
* بنك أسئلة متقدم.
* فيديوهات تعليمية داخل التطبيق.
* دعم الأجهزة اللوحية.
* تحسينات إضافية في إمكانية الوصول (Accessibility).

---

# 👨‍💻 المطور

**MathWorld Mobile**

تم تطوير المشروع باستخدام Flutter مع التركيز على الأداء، سهولة الاستخدام، وقابلية التوسع، ليكون منصة تعليمية حديثة لدعم تعلم الرياضيات بطريقة تفاعلية.
