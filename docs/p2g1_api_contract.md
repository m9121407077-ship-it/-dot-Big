# P2.G1 — قرارداد API بین Prism و PWA Dot

**وضعیت:** پیشنهاد، در انتظار اجرای Claude Code
**فاز:** Dot Activation — Phase 2, Gate 1
**مبنا:** ADR معماری دو‌خزانه (`docs/architecture.md`)، رجیستری Azura (`docs/azura_master_reference.md`)، migrationهای `20260606000000`، `20260606000100`، `20260606010000`.
**هدف این فایل:** تنها منبع canonical حقیقت برای endpoint اول Dot، قابل ارجاع از پرامت Claude Code و از کد PWA.

-----

## بخش یک — چهار اصل قفل‌شده

این چهار اصل مرز کل قرارداد را تعریف می‌کنند و در هیچ گیت بعدی بازنمی‌شوند.

**اصل یک — جهت یک‌طرفه.** PWA فقط می‌خوانَد. هیچ نوشتنی از سمت PWA به Prism مجاز نیست. هیچ POST، PUT، PATCH، یا DELETE روی داده‌ی محتوایی. اگر روزی فرم تماس یا ثبت user feedback لازم شد، در یک خزانه‌ی سوم جدا می‌نشیند، نه در Prism.

**اصل دو — فقط خزانه‌ی سرویس.** PWA با کلید `anon` Supabase کار می‌کند و فقط به schema با نام `public_serving` دسترسی دارد. schema با نام `private` — که اتم‌ها، گراف، منابع، تناقض‌ها، و missingness در آن نشسته‌اند — از API به‌طور کامل قطع است و توسط RLS با policy deny-by-default محافظت می‌شود. این مرز در migration اول از فاز یک قفل شده و در این گیت دست نمی‌خورد.

**اصل سه — Prism قاضی است، Dot راوی.** خودِ حکم، متن سؤال‌های buyer-side، رشته‌ی توضیح هر سؤال، و ترتیب نمایش — همه سمت سرور ساخته می‌شوند. PWA هیچ logic ترکیبی، هیچ قضاوت، و هیچ بازنویسی متن انجام نمی‌دهد. این یعنی تمام guardrailهای ضدمنیپولیشن و صدای buyer-side در یک جا متمرکز و قابل‌ممیزی می‌مانند.

**اصل چهار — هیچ نشانه‌ای از موات بیرون نرود.** UUIDهای منبع، URLهای منبع، `content_hash`، `atom_id`، `criterion_id`، `source_class`، و متن خام `claim` هرگز در JSON خروجی به PWA نمی‌رسند. PWA فقط خروجی پخته را می‌گیرد. اگر روزی کسی کل API را scrape کند، فقط نتیجه‌ها را در دست دارد، نه substrate تحقیقاتی.

-----

## بخش دو — تنها endpoint قرارداد گیت یک

برای اولین جرقه (P2.G2)، PWA به یک endpoint وصل می‌شود و بس:

- **Function:** `public_serving.get_project_dossier(p_project_id uuid)`
- **Method:** Supabase RPC — یعنی `POST /rest/v1/rpc/get_project_dossier`
- **Auth:** کلید anon (در PWA env: `VITE_SUPABASE_ANON_KEY`)
- **ورودی:** `p_project_id` — UUID موجودیت پروژه در `private.entities` با `entity_type = 'project'`. برای Azura در PWA env متغیر `VITE_AZURA_PROJECT_ID` ذخیره می‌شود.
- **خروجی:** یک `jsonb` با شکل مشخص بخش سه.

دلیل اینکه یک تابع است نه چند view: تمام composition، تمام انتخاب فیلدها، و تمام محدودیت‌های موات سمت سرور می‌مانند. PWA یک بار صدا می‌زند، یک صفحه‌ی کامل به‌دست می‌آورد. این الگو همچنین به ما اجازه می‌دهد بعداً شکل JSON را تکامل دهیم (`schema_version` در metadata)، بدون اینکه چندین view و چندین client query را همزمان migrate کنیم.

-----

## بخش سه — شکل JSON خروجی

```json
{
  "project": {
    "id": "uuid",
    "name": "Azura Beach Residences",
    "status": "off_plan",
    "jurisdiction": "OM"
  },
  "verdict": {
    "label": "حساس به توقف",
    "code": "enhanced_diligence_required",
    "rationale": "سه گیت سخت همچنان باز یا partial هستند: مجوز مستقیم، escrow اختصاصی Azura، روند title transfer. ماده ۲۶۷ قانون مدنی عمان نیز جریمه‌های قراردادی SPA را تا حد زیادی غیرقابل‌تضمین می‌کند.",
    "last_reviewed_at": "2026-06-06T00:00:00Z"
  },
  "question_backs": [
    {
      "subject": "حساب escrow اختصاصی Azura",
      "severity": "critical",
      "question": "هنگام امضای SPA، شماره‌ی حساب escrow اختصاصی Azura و نام بانک متولی باید با مجوز MoHUP تطابق داشته باشد.",
      "context": "framework کاملاً مستند است (RD 30/2018 + RD 79/2025) و MoHUP صفحه‌ی رسمی escrow دارد، ولی نام بانک Azura هنوز public نیست."
    }
  ],
  "ownership_chain": [
    { "name": "Azura Beach Residences", "type": "project", "via": null, "weight": null, "depth": 0 },
    { "name": "Al Mouj Muscat Community", "type": "master_development", "via": "contains", "weight": null, "depth": 1 },
    { "name": "Al Mouj Muscat S.A.O.C.", "type": "jv", "via": "develops", "weight": null, "depth": 2 },
    { "name": "MAF Properties LLC", "type": "developer", "via": "joint_venture_with", "weight": 0.5, "depth": 3 }
  ],
  "metadata": {
    "schema_version": "p2g1-v1",
    "generated_at": "2026-06-07T08:30:00Z"
  }
}
```

سه قاعده‌ی شکل:

اول، اگر برای پروژه ردیفی در `private.verdicts` نیست، فیلد `verdict` معادل `null` است و یک فلگ `verdict_missing: true` در ریشه‌ی شیء اضافه می‌شود. PWA placeholder مناسب نشان می‌دهد و هرگز خودش حکم نمی‌سازد.

دوم، `severity` در `question_backs` دقیقاً یکی از چهار مقدار `critical | significant | moderate | low` است (همان enum قفل‌شده‌ی schema). PWA فقط رنگ یا نشانه‌ی نمایشی اختصاص می‌دهد، نه ترجمه.

سوم، `ownership_chain` به ترتیب از خود پروژه (`depth=0`) به سمت ریشه‌ها مرتب می‌شود. عمق با کلاه ۱۰ بسته است (همان safety موجود در `entity_parents`). PWA می‌تواند زنجیره را از پایین یا بالا رندر کند، ولی منطق مرتب‌سازی سمت سرور است.

-----

## بخش چهار — تغییرات schema (افزودنی محض)

این گیت دو چیز به repo اضافه می‌کند، و هیچ‌چیز دیگر را عوض نمی‌کند:

**جدول جدید در `private`:**

```sql
CREATE TABLE private.verdicts (
    entity_id         UUID PRIMARY KEY REFERENCES private.entities(entity_id),
    label             TEXT NOT NULL,
    code              TEXT NOT NULL,
    rationale         TEXT NOT NULL,
    last_reviewed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    reviewed_by       TEXT,
    metadata          JSONB DEFAULT '{}'::jsonb
);

ALTER TABLE private.verdicts ENABLE ROW LEVEL SECURITY;
-- بدون policy = deny-by-default برای anon و authenticated.
-- فقط service_role می‌نویسد. تابع dossier با SECURITY DEFINER می‌خواند.
```

**تابع جدید در `public_serving`:** تابع `public_serving.get_project_dossier(p_project_id uuid)` با `SECURITY DEFINER` و `LANGUAGE plpgsql` که از `private.entities`، `private.verdicts`، `private.missingness`، و `private.edges` (با recursive CTE) داده را می‌خوانَد و JSON بالا را برمی‌گرداند. اجرا فقط برای `anon` و `authenticated` GRANT می‌شود.

**Seed برای Azura:** ردیف verdict با مقادیر زیر، استخراج‌شده از Azura master reference بخش هفت:

- `label`: `حساس به توقف`
- `code`: `enhanced_diligence_required`
- `rationale`: «سه گیت سخت همچنان باز یا partial هستند: مجوز مستقیم (هیچ developer license تأیید عمومی)، escrow اختصاصی Azura (RD 79/2025 لانچ در دوره‌ی گذار)، و روند title transfer. ماده ۲۶۷ قانون مدنی عمان نیز جریمه‌های قراردادی SPA را تا حد زیادی غیرقابل‌تضمین می‌کند.»
- `reviewed_by`: `phase1_operator_review`

پنج question-back از `private.missingness` که قبلاً در فاز یک seed شده‌اند، خودبه‌خود از طریق join داخل تابع dossier ظاهر می‌شوند. این گیت داده‌ی missingness جدید اضافه نمی‌کند.

-----

## بخش پنج — مرز DO NOT برای PWA

- هیچ query مستقیم به `private.*` با هیچ کلید، با هیچ بهانه.
- هیچ استفاده از `service_role` key. فقط `anon` با env متغیر `VITE_SUPABASE_ANON_KEY`.
- هیچ ساخت verdict، rationale، یا متن سؤال در کد PWA. این متن‌ها فقط از خروجی RPC می‌آیند.
- هیچ نگاه‌داشتن (cache) verdict بیشتر از یک session. هر باز شدن صفحه، یک fetch تازه.
- هیچ نمایش source URL، source ID، یا atom ID — حتی اگر اشتباهی در payload دیده شدند (که نباید).
- هیچ تماس مستقیم با OpenAI، Gemini، یا هر مدل دیگر برای رنگ زدن به متن دریافت‌شده. متن همان است که Prism فرستاد.

-----

## بخش شش — مرز DO NOT برای Claude Code

- migration اولیه (`20260606000000_initial_schema.sql`) و دو فایل load Azura دست‌نخورده‌اند. هیچ `ALTER`، هیچ `DROP`، هیچ بازنویسی.
- view های موجود `public_serving.molecules`، `public_serving.project_status`، و `public_serving.entity_parents` byte-identical می‌مانند.
- هیچ RLS policy روی جدول‌های موجود `private.*` تغییر نمی‌کند.
- هیچ `entity_type` جدید، `edge_type` جدید، `criterion section` جدید، یا atom `level` جدید — اینها در فاز یک قفل شدند.
- هیچ endpoint نوشتن (insert/update/delete RPC) اضافه نمی‌شود.
- هیچ logic امتیازدهی یا قانون verdict در کد. verdict فقط از `private.verdicts` خوانده می‌شود. اگر نباشد، تابع `verdict_missing: true` برمی‌گرداند.
- هیچ کار روی PWA، هیچ تغییر در `docs/` به‌جز افزودن همین فایل و یک ردیف در `CHANGELOG.md`.
- هیچ گسترش به کشور دوم یا پروژه‌ی دوم. این کار به P2.G5 موکول است.

-----

## بخش هفت — تست‌های پذیرش

قبل از بستن این گیت، این سه تست باید pass شوند:

اول، خواندن موفق از طریق سرویس:

```sql
SELECT public_serving.get_project_dossier(
    (SELECT entity_id FROM private.entities
     WHERE canonical_name = 'Azura Beach Residences' AND entity_type = 'project')
);
```

باید JSON با شکل بخش سه برگرداند، با حداقل پنج `question_back` و `ownership_chain` با حداقل پنج گره.

دوم، اطمینان از قفل خزانه‌ی تحقیق برای anon:

```sql
SET ROLE anon;
SELECT * FROM private.atoms LIMIT 1;
```

باید خطای `permission denied for table atoms` (یا معادل RLS) بدهد.

سوم، اطمینان از دسترسی anon فقط از طریق تابع:

```sql
SET ROLE anon;
SELECT public_serving.get_project_dossier(
    (SELECT entity_id FROM private.entities
     WHERE canonical_name = 'Azura Beach Residences')
);
```

باید همان JSON موفق تست اول را برگرداند. یعنی anon از طریق `SECURITY DEFINER` به نتیجه می‌رسد، ولی به اتم خام نه.

-----

## بخش هشت — قدم بعدی

با merge این migration، گیت یک بسته می‌شود. گیت دو فقط یک کار است: PWA Lovable این یک endpoint را صدا می‌زند و خروجی را روی صفحه‌ی فعلی (که الان dummy data نشان می‌دهد) جای dummy می‌نشاند. هیچ طراحی جدید، هیچ feature جدید — فقط جایگزینی dummy با real. زیبایی و responsive (Apple-quality) به گیت سه موکول می‌شود.