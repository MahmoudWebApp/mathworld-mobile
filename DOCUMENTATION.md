# Mathworld Mobile Flutter

> تطبيق MathWorld الذكي لحل المسائل الرياضية - نسخة الجوال

## نظرة عامة

تطبيق Flutter متقدم يجلب تجربة منصة MathWorld التعليمية إلى الأجهزة الذكية، مع دعم كامل للعربية والإنجليزية وميزات offline.

### ✨ المميزات الرئيسية

- 🔐 **مصادقة آمنة**: تسجيل دخول وإنشاء حساب مع حفظ آمن للتوكن
- 📚 **تصفح ديناميكي**: المراحل والفئات والمسائل بسهولة
- ✅ **حل مسائل تفاعلي**: واجهة سلسة لحل المسائل مع نتائج فورية
- 📊 **لوحة إحصائيات**: عرض التقدم والإحصائيات الشخصية
- ❤️ **المفضلات**: حفظ المسائل المهمة
- 🌙 **ثيم داكن**: دعم الوضع الليلي
- 🌍 **عربي وإنجليزي**: تبديل سلس بين اللغات
- 📱 **دعم Offline**: استخدام الهيف المحلي للعمل بدون إنترنت

## البنية الفنية

### التقنيات المستخدمة

- **Flutter 3.x** - إطار العمل
- **Riverpod** - إدارة الحالة (State Management)
- **Dio** - HTTP Client للاتصال بالـ API
- **Hive** - قاعدة بيانات محلية للتخزين الآمن
- **Easy Localization** - دعم اللغات
- **Flutter Secure Storage** - حفظ التوكن بأمان

### هيكل المشروع

```
lib/
├── config/
│   ├── theme.dart          # الثيم والألوان
│   ├── constants.dart      # الثوابت و API endpoints
│   └── app_routes.dart     # التوجيه بين الشاشات
├── models/
│   ├── user.dart           # نموذج المستخدم
│   ├── stage.dart          # نموذج المرحلة
│   ├── category.dart       # نموذج الفئة
│   ├── problem.dart        # نموذج المسألة
│   └── dashboard_stats.dart # نموذج الإحصائيات
├── providers/
│   ├── auth_provider.dart      # التحكم في المصادقة
│   ├── problems_provider.dart  # جلب المسائل
│   ├── stages_provider.dart    # جلب المراحل
│   └── theme_provider.dart     # إدارة الثيم
├── services/
│   ├── api_service.dart    # خدمة الاتصال بالـ API
│   └── hive_service.dart   # خدمة التخزين المحلي
├── screens/
│   ├── splash/             # شاشة البدء
│   ├── auth/               # شاشات التسجيل والدخول
│   ├── home/               # الصفحة الرئيسية
│   ├── stages/             # شاشات المراحل
│   ├── problems/           # شاشات المسائل
│   ├── dashboard/          # لوحة المستخدم والمفضلات
│   └── settings/           # الإعدادات
├── widgets/
│   └── common/             # مكونات مشتركة
├── utils/                  # أدوات مساعدة
└── main.dart               # نقطة الدخول الرئيسية
```

## الخطوات الأولى

### المتطلبات

- Flutter 3.0+
- Dart 3.0+
- Android SDK / iOS SDK

### التثبيت والتشغيل

```bash
# استنساخ أو نسخ المشروع
cd mathworld_mobile

# تحميل المكتبات
flutter pub get

# التشغيل
flutter run
```

## الاتصال بـ API

التطبيق يتصل بـ Backend على:
```
Base URL: http://localhost:5229/api
```

### نقاط النهاية المستخدمة

#### المصادقة
- `POST /auth/login` - تسجيل الدخول
- `POST /auth/register` - إنشاء حساب جديد

#### البيانات
- `GET /stages` - جلب المراحل
- `GET /categories` - جلب الفئات
- `GET /problems/search` - البحث عن المسائل
- `GET /problems/{id}` - تفاصيل مسألة
- `POST /problems/submit` - إرسال إجابة

#### المستخدم
- `GET /users/profile` - بيانات المستخدم
- `GET /users/dashboard` - إحصائيات المستخدم
- `GET /users/favorites` - المسائل المفضلة
- `POST /users/favorite/toggle` - إضافة/حذف من المفضلات

## خريطة الطريق (Roadmap)

- [x] بنية المشروع الأساسية
- [x] المصادقة (Login/Register)
- [ ] استكمال جميع الـ Providers
- [ ] استكمال جميع الشاشات
- [ ] ربط جميع الشاشات بـ API
- [ ] إضافة معالجة الأخطاء
- [ ] إضافة اختبارات
- [ ] التحسينات والأداء
- [ ] اختبار على أجهزة فعلية
- [ ] النشر على App Store و Google Play

## ملفات مهمة

- `pubspec.yaml` - حزم المشروع والاعتماديات
- `.env` - متغيرات البيئة
- `README.md` - هذا الملف

## التطوير المستمر

للاستمرار في التطوير:

1. استكمل جميع الـ Providers في `providers/`
2. اكمل جميع الشاشات في `screens/`
3. أضف معالجة الأخطاء والتحميل
4. اختبر على أجهزة فعلية (Android و iOS)
5. قم بالتحسينات والبناء النهائي

## الدعم والمساعدة

للمزيد من المعلومات عن Flutter:
- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Hive Documentation](https://docs.hivedb.dev/)

---

**تم إنشاؤه بواسطة**: AI Assistant
**التاريخ**: 2024
