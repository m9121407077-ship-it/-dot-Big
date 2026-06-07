# Prism — منشور داده‌ی Dot

Prism یک data prism است: ابزاری که داده‌ی خام را از منابع متنوع (کاربر، crawl، تحقیق دستی) دریافت می‌کند، آن را normalize، تمیز، و atomize می‌کند، و وقتی محصول مصرف‌کننده‌ی نهایی (Dot) به یک ماده‌ی buyer-side نیاز دارد، Prism از روی اتم‌ها مولکول و از روی مولکول‌ها ماده می‌سازد و آن را با evidence ledger کامل به Dot تحویل می‌دهد.

## جریان کاری اصلی

ذات Prism در یک workflow چهار-مرحله‌ای زندگی می‌کند:

داده‌ی خام از منابع متنوع وارد Prism می‌شود. این داده می‌تواند از کاربر دستی بیاید، از crawl خودکار وب، یا از تحقیق ساختاریافته با AI search engines. Prism این داده را normalize، تمیز، و atomize می‌کند تا هر fact مستقل به‌عنوان یک atom با provenance کامل (منبع، کلاس منبع، valid_from، content_hash) ثبت شود.

اتم‌ها در ساختار خودشان در پایگاه می‌نشینند. هر atom به یک entity مشخص متعلق است و می‌تواند به یک criterion مشخص ارجاع داشته باشد. اتم‌ها bitemporal و append-only هستند — یعنی هرگز update یا delete نمی‌شوند، تنها supersede می‌شوند، که تاریخ کامل هر fact حفظ می‌شود.

وقتی Dot برای پاسخ به یک نیاز buyer یک ماده درخواست می‌کند، Prism از روی اتم‌ها مولکول می‌سازد. مولکول‌ها computed views هستند که چندین atom مرتبط با یک entity و یک criterion را با هم ترکیب می‌کنند، با recency awareness و source class weighting. این کار از طریق view `public_serving.molecules` به‌صورت خودکار انجام می‌شود.

از روی مولکول‌ها، Prism مواد (materials) را synthesize می‌کند. مواد، synthesisهای روایی buyer-relevant هستند که چندین مولکول را در یک narrative قابل‌مصرف توسط Dot ترکیب می‌کنند. هر ماده با evidence ledger همراه است — یعنی هر claim در ماده به atom منبع آن قابل‌ردیابی است. این ledger در dossierهای پروژه قابل‌مشاهده است.

ماده‌ی نهایی به همراه ledger به Dot تحویل می‌شود. Dot می‌تواند این ماده را به presentation buyer-facing تبدیل کند، توصیه بسازد، یا با مولفه‌های دیگر ترکیب کند.

## این repo

این repository بخش substrate Prism روی Postgres را در خود نگه می‌دارد. این substrate روی Supabase اجرا می‌شود (پروژه `iiucfqmdekrfmaobiaia.supabase.co`، منطقه `eu-central-1` در فرانکفورت). اجزای اصلی:

دو schema جدا: `private` که vault تحقیق است و server-side only، و `public_serving` که vault سرویس‌دهی API است و read-only برای consumerها. این تفکیک دو-خزانه‌ای مرز امنیتی وجودی Prism است که از scrape مستقیم اتم‌های خام جلوگیری می‌کند.

شش جدول هسته در private: `entities` (موجودیت‌های گراف)، `edges` (روابط)، `atoms` (factها با provenance)، `sources` (منابع)، `criteria` (معیارهای evaluation)، `criteria_applicability` (منطق شرطی فعال‌بودن معیارها بسته به project status).

دو جدول کمکی: `contradictions` (registry تناقض‌ها با status حل) و `missingness` (registry شکاف‌ها با context و question-back).

دو view در `public_serving`: `molecules` (computed view چند-atom) و `project_status` و `entity_parents` (helper views برای traversal گراف).

extensions فعال: `pgvector` برای semantic search توسط AI agents آینده، `uuid-ossp` و `pgcrypto` برای ID generation و content hashing.

helper function: `insert_atom_with_supersession` که supersession atomها را به‌صورت atomic مدیریت می‌کند.

## features اضافی Prism

علاوه بر هسته‌ی atom-molecule-material، Prism چند feature اضافی دارد که هر کدام یک facet متفاوت از داده را نمایش می‌دهد. گراف بصری (در `docs/azura_graph_v2.html`) رابطه‌های بین موجودیت‌ها را به‌صورت تعاملی نشان می‌دهد، طراحی‌شده بر اساس اصول علوم شناختی بصری (مستند در `docs/g7_research_brief.md` و `docs/g7_design_rationale.md`). semantic search از طریق pgvector به AI agents اجازه می‌دهد روی هر سه لایه (atoms، molecules، materials) جستجوی معنایی انجام دهند. registry تناقض‌ها و missingness‌ها به اپراتور اجازه می‌دهد بفهمد چه چیزی می‌دانیم، چه چیزی نمی‌دانیم، و چه سؤالات‌ی باید پرسیده شود. این‌ها همگی **features Prism هستند، نه خود Prism** — Prism حتی بدون این features، با همان workflow بنیادی atom-molecule-material، یک محصول کامل است.

## رابطه با ecosystem Dot

Prism در ecosystem Dot سه نقش متمایز را پشتیبانی می‌کند. **Prism** خودش منشور داده است که اپراتورهای داخل Dot روی آن کار می‌کنند تا داده ready شود برای محصولات دیگر. **Dot** محصول buyer-side است که materials را از Prism مصرف می‌کند و توصیه برای خریدار می‌سازد. **Lens** محصول user-side (آینده) خواهد بود که نیاز و ظرفیت کاربر را می‌گیرد و به Dot منتقل می‌کند تا توصیه متناسب ساخته شود.

علاوه بر این، یک Prism موازی روی SQLite در repo `dot-internal-decision-pack` وجود دارد که L0 (چارچوب عمان) و L1 (Al Mouj و سایر developers) atomهای deep research را به‌عنوان source of truth audit-grade نگه می‌دارد. در حال حاضر این دو Prism (SQLite قدیمی + Postgres جدید) با hand-curated mirror references به یکدیگر اشاره می‌کنند، نه با sync خودکار. ساخت یک bridge کنترل‌شده برای sync پایدار در نقشه‌ی راه نزدیک است.

## وضعیت

این repo نقطه‌ی پایانی Phase 1 یعنی **Azura vertical slice** است. ۹ گیت از مسیر چراغ سبز قفل‌شده پر شده:

G1 (Data Hardening): ۵۵ atom در پنج سطح با full provenance.
G2 (External Research): دو دور تحقیق با Grok و Gemini.
G3 (Graph Validation): ۲۲ entity و ۲۸ edge با validation کامل.
G4 (Anti-Bias Audit): ۱۲ از ۱۲ قاعده pass.
G5 (Dossier Perfection): پرونده‌ی کامل operator-facing Azura.
G6 (Schema Implementation): ۳ migration روی Supabase production.
G7 (Visual Cognition Design): research brief + prototype + rationale.
G8 (Protocol Documentation): راهنمای مکانیکی اضافه‌کردن پروژه.
G9 (Operator Green Light): تأیید operator (Mr. H).

## نقشه‌ی راه بعد

پس از این release، چهار خط کاری در صف قرار دارد:

اولاً، اتصال PWA Lovable به API Postgres برای نمایش داده‌ی Azura — این کار شامل تعریف API contract بین Prism و PWA، اتصال Lovable به `public_serving` schema، و رندر داده‌ی واقعی Azura به‌جای dummy data است.

دوماً، تبدیل PWA از حالت decorative mockup فعلی به یک application دینامیک و responsive — این یعنی layout responsive روی موبایل و دسکتاپ، navigation داده‌محور، و real-time updateها از Prism.

سوماً، ساخت bridge L0/L1 از Prism SQLite به Prism Postgres برای حذف mirror state و رسیدن به single source of truth.

چهارماً، اضافه‌کردن پروژه‌ی دوم (Hawana Lagoons، AIDA، یا Yiti) با استفاده از پروتکل مکانیکی G8.

## فایل‌های مهم

برای deep dive در معماری، `docs/architecture.md` را ببینید. برای داده‌ی Azura، `docs/azura_master_reference.md` (رجیستری ساختاری) و `docs/azura_dossier.md` (synthesis روایی buyer-side). برای روش‌شناسی طراحی گراف، `docs/g7_research_brief.md` و `docs/g7_design_rationale.md`. برای اضافه‌کردن پروژه‌های آینده، `docs/g8_protocol_documentation.md`. برای تست‌های validation، `docs/verification_queries.sql`.

برای دیدن گراف Azura در مرورگر، فایل `docs/azura_graph_v2.html` را در Safari یا Chrome باز کنید (هیچ server لازم نیست).

## مدیریت migrationها

هر تغییری در database (اضافه‌کردن جدول، اضافه‌کردن پروژه‌ی جدید، اصلاح criteria) به‌صورت یک migration جدید در `supabase/migrations/` نوشته می‌شود، با فرمت نام `YYYYMMDDHHMMSS_<descriptive_name>.sql` و push به branch `main`. Supabase GitHub integration به‌صورت خودکار migrationها را به ترتیب timestamp روی production اعمال می‌کند.

هیچ migration پس از merge به main نباید تغییر کند — برای اصلاح state، یک migration جدید نوشته می‌شود که supersede می‌کند.