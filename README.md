# مدیریت کارکنان

برنامه Flutter Windows اطلاعات کارکنان را از Collection موجود `employees` در PocketBase دریافت می‌کند. داده اولیه یا ذخیره‌سازی محلی ندارد.

آدرس پیش‌فرض در [PocketBaseConfig](lib/config/pocketbase_config.dart) قرار دارد. پس از اجرای PocketBase، برنامه را اجرا کنید:

```powershell
flutter pub get
flutter run -d windows
```

برای اتصال به آدرس دیگری، `--dart-define=POCKETBASE_URL=<server-url>` را به دستور اجرا اضافه کنید.

فیلدهای Collection عبارت‌اند از `first_name`، `last_name`، `national_code`، `mobile`، `personnel_code`، `job_title`، `department`، `hire_date`، `end_date` و `is_active`. تاریخ‌ها به صورت روز تقویمی ذخیره می‌شوند؛ `end_date` اختیاری است و هنگام فعال شدن دوباره کارمند پاک می‌شود.

دسترسی درخواست‌های برنامه باید در API Rules این Collection مجاز باشد. این مرحله ورود کاربر ندارد و هیچ حساب Admin، رمز یا توکنی در برنامه قرار نگرفته است. پاسخ `403` برای درخواست بدون احراز هویت به قواعد قفل‌شده مربوط است؛ قواعد باید متناسب با شیوه دسترسی موردنظر پروژه تنظیم شوند. [مستندات API Rules](https://pocketbase.io/docs/api-rules-and-filters/)

فرم تکراری بودن کد ملی و کد پرسنلی را در لیست دریافت‌شده بررسی می‌کند و خطاهای اعتبارسنجی سرور را نیز نشان می‌دهد. برای تضمین یکتایی هنگام ثبت هم‌زمان از چند برنامه، این دو فیلد باید در دیتابیس نیز دارای ایندکس یکتا باشند.

تست‌ها از پاسخ‌های شبیه‌سازی‌شده استفاده می‌کنند و دیتابیس واقعی را تغییر نمی‌دهند:

```powershell
flutter test
flutter analyze
```
