# G8 Protocol Documentation — اضافه‌کردن پروژه‌ی جدید به Prism

**نسخه:** ۱.۰
**تاریخ:** ۶ ژوئن ۲۰۲۶
**مخاطب:** اپراتورها، ادمین‌ها، عامل‌های هوشمند (Claude Code و موارد مشابه)
**هدف:** تبدیل فرایند خلاقانه‌ی اضافه‌کردن یک پروژه به یک execution مکانیکی قابل‌تکرار

این سند نقشه‌ی راه قطعی است برای اضافه‌کردن هر پروژه‌ی جدید (مثل Hawana Lagoons، AIDA، Yiti، یا هر پروژه‌ای از L1 portfolio) به Prism. اگر مراحل این سند با ترتیب و دقت دنبال شوند، نتیجه یک migration درست، با FK integrity، با provenance کامل، با ضدسوگیری validated، و قابل‌اعمال خودکار توسط Supabase خواهد بود. این سند تضمین می‌کند که هیچ پروژه‌ی بعدی نیاز به «تصمیمات معماری مجدد» نداشته باشد.

-----

## بخش اول — پیش‌نیازها (Pre-flight)

قبل از اینکه هیچ خطی کد بنویسی یا هیچ فایلی در repo بسازی، باید چهار گیت تحقیقاتی G1 تا G4 از مسیر چراغ سبز قفل‌شده برای پروژه‌ی جدید pass شده باشد. این پیش‌نیازها مذاکره‌پذیر نیستند چون بدون آن‌ها، اتم‌هایی که در پایگاه می‌نشینند بی‌اعتبار خواهند بود.

**G1 یعنی Data Hardening**. باید برای پروژه حداقل ۲۰ اتم پایه استخراج شده باشد، هر اتم با ID منحصر، با source شناسایی‌شده، با source class تخصیص‌یافته، و با level مشخص (framework یا platform_level یا project_specific یا analytical_insight). این کار به‌صورت دستی از طریق مطالعه‌ی منابع رسمی developer، press releases، مستندات حقوقی، و third-party media انجام می‌شود. هیچ اتمی بدون منبع قابل‌ثبت نیست.

**G2 یعنی External Research**. حداقل یک دور تحقیق با AI search engines (Grok، Gemini، Perplexity یا مشابه) برای پر کردن gapهای اولیه و کشف missingness بحرانی انجام شده باشد. این دور باید پاسخ به سؤال‌های کلیدی buyer-side را بدهد: «طرف قرارداد خریدار کیست؟»، «escrow اختصاصی کجاست؟»، «تاریخ تحویل رسمی چیست؟»، «framework حقوقی چه چیزی را الزام می‌کند؟». نتایج دور تحقیق در یک سند جدا (مثل `<project>_research_round1.md`) ثبت شده باشد.

**G3 یعنی Graph Validation**. ساختار JV و سلسله‌مراتب پروژه روی کاغذ یا در یک diagram اولیه ترسیم شده باشد، با تأیید این که هر entity جای درست در taxonomy دارد، و هر edge منطقی است. هیچ یال orphan (یعنی یال به موجودیتی که وجود ندارد) نباید وجود داشته باشد.

**G4 یعنی Anti-Bias Audit**. دوازده قاعده‌ی ضدسوگیری L2 pilot را علیه پرونده‌ی پروژه چک کن: Product-Specific Reading، Hard Gate Isolation، Developer Context Modifier، Framework vs Project-Specific Split، Banking Support ≠ Buyer Protection، Payment-Plan Integrity، Disclosure Discipline، Descriptive Board، Incentive Containment، Residency Claim Discipline، Market Absorption ≠ Liquidity، Separate Project Files. هر قاعده باید pass شود قبل از اینکه پروژه به repo اضافه شود. اگر هر قاعده fail می‌شود، ابتدا data یا framing را اصلاح کن.

اگر هر یک از این چهار گیت pass نشده باشد، **توقف کن**. اضافه‌کردن داده‌ی بی‌اعتبار به پایگاه integrity سیستم را خراب می‌کند و رفع کردنش به‌مراتب سخت‌تر از جلوگیری از آن است. این پیش‌نیازها در مسیر چراغ سبز قفل شده‌اند و در G9 (تأیید نهایی) دوباره چک می‌شوند.

-----

## بخش دوم — Schema Reminder

قبل از نوشتن migration، یک یادآوری از ساختار schema که در migration ۰۰۱ تثبیت شد. این یادآوری به این خاطر است که Claude Code یا اپراتور بدون نگاه به فایل اصلی schema بداند چه فیلدهایی موجود و الزامی هستند.

ساختار `private.sources` این فیلدها را دارد: source_id (UUID)، source_name (text)، source_url (text، اختیاری)، source_class (integer 1-4)، publisher (text)، publication_date (date)، language (text)، notes (text، اختیاری).

ساختار `private.entities`: entity_id (UUID)، entity_type (CHECK enum)، canonical_name (text)، jurisdiction (text)، status (CHECK enum، اختیاری)، embedding (vector 1536)، metadata (JSONB).

ساختار `private.edges`: edge_id (UUID)، from_entity (UUID FK)، to_entity (UUID FK)، edge_type (CHECK enum)، weight (numeric، اختیاری)، source_atom_id (UUID، اختیاری)، metadata (JSONB).

ساختار `private.atoms`: atom_id (UUID)، entity_id (UUID FK، الزامی)، criterion_id (UUID FK، اختیاری)، claim (text)، source_id (UUID FK، الزامی)، source_class (integer 1-4)، language (text)، valid_from (timestamptz)، valid_to (timestamptz، اختیاری)، recorded_at (timestamptz، خودکار)، superseded_by (UUID، اختیاری)، level (CHECK enum)، content_hash (text)، embedding (vector، اختیاری)، status (default ‘active’)، metadata (JSONB).

ساختار `private.contradictions`: contradiction_id (UUID)، subject (text)، atom_a_id (UUID FK)، atom_b_id (UUID FK)، status (CHECK enum)، resolution_notes (text)، winning_atom_id (UUID FK، اختیاری).

ساختار `private.missingness`: missingness_id (UUID)، entity_id (UUID FK، اختیاری)، criterion_id (UUID FK، اختیاری)، subject (text)، severity (CHECK enum)، description (text)، context_notes (text)، question_back (text).

-----

## بخش سوم — تخصیص UUID

برای حفظ consistency و قابلیت ردیابی، UUIDها باید pattern قابل‌پیش‌بینی داشته باشند. این کار به این خاطر است که وقتی در migrationهای آینده اتم را reference می‌کنیم، بتوانیم به‌سادگی از روی pattern بفهمیم کدام entity یا کدام source مراد است.

برای **sources** فرمت `11111111-1111-1111-1111-<12-digit-sequence>` استفاده می‌شود، که در آن sequence یک عدد monotonic است. در migration Azura، sources از 000000000001 تا 000000000030 رفت. برای پروژه‌ی بعدی، شروع از 000000000031 ادامه می‌یابد.

برای **entities** فرمت `22222222-<type-code>-0000-0000-<sequence>` است، که در آن type-code یک کد دو رقمی است که entity_type را نشان می‌دهد. کدها این‌ها هستند: 0000 برای country، 1100 برای parent holdings، 1200 برای operating developers، 1300 برای JV entities، 2000 برای master developments، 2100 برای projects، 2110 برای product_phases، 2120 برای unit_types، و 4000 برای operators. sequence درون هر type‌code از 1 شروع می‌شود.

برای **criteria** فرمت `33333333-<section-code>-0000-0000-<sequence>` است، با section-codeها: 1000 برای gate_board، 2000 برای score_core، 2500 برای developer_modifier، 3000 برای descriptive، 4000 برای escalation. criteriaها در migration اول تعریف شدند و معمولاً برای پروژه‌های جدید نیازی به اضافه‌کردن criteria جدید نیست — همان ۱۷ معیار موجود کافی است. اگر روزی یک معیار جدید نیاز بود، در migration جداگانه با pattern بالا اضافه می‌شود.

برای **atoms** فرمت `44444444-<level-code>-0000-0000-<sequence>` است، با level-codeها: 0001 برای L0 framework، 1000 برای L1 platform، 2000 برای L2 project، 2500 برای L2.5 unit، 4000 برای L4 operator. sequence معمولاً با شماره‌ی اتم در رجیستری master reference پروژه match می‌شود.

برای پروژه‌های بعد از Azura، بهتر است سری متمایز در یکی از byte‌های ابتدایی استفاده شود تا اشتباه ارجاع پیش نیاید. مثلاً برای Hawana Lagoons می‌توان از prefix `aaaa1111-...` برای sources استفاده کرد، یا یک عدد serial متمایز در byte اول. این تصمیم در آغاز هر پروژه باید گرفته شود و در research brief پروژه ثبت شود.

-----

## بخش چهارم — مراحل ساخت Migration

با G1-G4 pass شده و UUIDها planned، حالا migration نوشته می‌شود. ساختار آن این هفت گام را شامل می‌شود.

**گام اول، ساخت فایل migration**. در پوشه‌ی `supabase/migrations/`، یک فایل جدید با اسم `YYYYMMDDHHMMSS_load_<project_name>.sql` بساز. timestamp باید بعد از آخرین migration موجود باشد. برای پروژه‌ی Hawana Lagoons، اگر آخرین migration `20260606010000_complete_azura_atoms.sql` بود، فایل جدید می‌تواند `20260615000000_load_hawana_lagoons.sql` باشد.

**گام دوم، wrapping in transaction**. فایل با `BEGIN;` در ابتدا و `COMMIT;` در انتها بسته می‌شود. این کار اطمینان می‌دهد که اگر هر خطا در هر INSERT رخ داد، کل migration rollback می‌شود و پایگاه در حالت partial state گیر نمی‌کند.

**گام سوم، insert sources**. تمام منابع مورد استفاده در اتم‌ها باید اول insert شوند چون اتم‌ها از FK به sources وابسته‌اند. هر INSERT شامل source_id (UUID جدید طبق pattern)، source_name، source_url، source_class (یک از ۱-۴)، publisher، publication_date، و language است. اگر چندین منبع، یک INSERT چندردیفه می‌نویسیم برای کارایی بهتر.

**گام چهارم، insert entities**. تمام موجودیت‌های جدید با entity_id (UUID طبق pattern)، entity_type (یک از ۹ نوع تعریف‌شده)، canonical_name، jurisdiction، status (اگر اختصاصی است)، و metadata (JSONB با اطلاعات تکمیلی مثل اسم فارسی، آدرس، و غیره) insert می‌شوند. توجه: اگر یک موجودیت قبلاً در پایگاه وجود دارد (مثل Sultanate of Oman که در Azura ساخته شد)، نباید دوباره insert شود — فقط reference به آن.

**گام پنجم، insert edges**. تمام روابط با from_entity، to_entity، edge_type (یک از ۱۰ نوع)، weight (اگر مرتبط است، مثلاً برای JV percentage)، و metadata (JSONB با توضیحات) insert می‌شوند. این مرحله critical است چون graph integrity پروژه به درستی این یال‌ها بسته است. مخصوصاً یال `contractual_party_for_buyer` باید روشن باشد: کدام JV entity طرف قرارداد خریدار است.

**گام ششم، insert atoms**. این بزرگ‌ترین بخش migration است. هر اتم با atom_id منحصر، entity_id (FK به یک entity موجود)، criterion_id (FK به یک معیار موجود یا NULL)، claim (متن واقعی به Persian)، source_id (FK به یک منبع که در گام سوم insert شد)، source_class، level، valid_from، content_hash (محاسبه‌شده با `encode(digest('<atom-id>-<short-description>', 'sha256'), 'hex')`)، و language insert می‌شود. هر اتم باید به یک source واقعی متصل باشد — هیچ اتم بدون منبع قابل‌قبول نیست.

**گام هفتم، insert contradictions و missingness**. اگر در research dataها contradictionهایی پیدا شده‌اند، با وضعیت resolved یا explained یا open ثبت می‌شوند، با ارجاع به atom_a_id و atom_b_id که در گام ششم insert شدند. missingness records با subject، severity، description، context_notes (که محتمل‌ترین context را توضیح می‌دهد، حتی اگر gap باز است)، و question_back (سؤالی که اپراتور باید برای خریدار در نظر داشته باشد) insert می‌شوند.

-----

## بخش پنجم — Validation قبل از Commit

قبل از commit فایل migration به repo، چهار validation محلی باید انجام شود تا از خطاهای رایج جلوگیری شود.

**Validation اول، FK integrity check**. هر `entity_id` در atom INSERTs باید قبلاً در entity INSERTs یا در پایگاه موجود وجود داشته باشد. هر `source_id` در atom INSERTs باید در source INSERTs همین migration باشد. هر `criterion_id` در atom INSERTs باید در criteria موجود (که در migration دوم Azura insert شدند) موجود باشد. این چک با چشم یا با یک script ساده‌ی regex قابل‌انجام است.

**Validation دوم، unique PK check**. هیچ دو ردیف اتم با atom_id یکسان نباید وجود داشته باشد. هیچ atom_id جدید نباید با atomهای موجود در migrationهای قبلی تداخل داشته باشد. این چک ساده‌ترین راه جلوگیری از PK conflict در زمان اجرای migration است.

**Validation سوم، 12-rule anti-bias audit**. هر اتم پروژه باید با دوازده قاعده‌ی anti-bias چک شود. مهم‌ترین قواعد برای هر پروژه‌ی جدید این‌ها هستند: آیا اتم Product-Specific است یا framework؟ آیا level درست تخصیص یافته؟ آیا یک اتم platform-level به‌اشتباه به‌عنوان project-specific labeled شده؟ آیا یک claim افشایی به‌اشتباه به‌عنوان امتیاز خوانده شده؟ این audit با چک‌لیست استاندارد L2 pilot pass می‌شود.

**Validation چهارم، Persian readability check**. متن claimها به Persian روان، بدون errorهای املایی، با پشتیبانی ZWNJ (نیم‌فاصله) درست. این validation به‌خاطر مخاطب نهایی است که در PWA Lovable متن را می‌بیند یا اپراتوری که در dashboard atomها را review می‌کند. PostgreSQL متن Persian را به‌درستی encode می‌کند، ولی اپراتور باید مطمئن شود متن قابل‌خواندن است.

-----

## بخش ششم — Commit و Push از طریق Claude Code

با migration validated، حالا commit و push انجام می‌شود. این کار از طریق Claude Code session انجام می‌شود، نه دستی توسط اپراتور غیرفنی.

پرامت Claude Code برای add a new project به این الگو می‌چسبد. ابتدا یک خلاصه‌ی context (پروژه چه نام دارد، چه entity جدید معرفی می‌شود، چه atomهایی اضافه می‌شوند). سپس دستور صریح: «فایل پیوست را به `supabase/migrations/<filename>` اضافه کن، با پیام commit `feat: add <project> vertical slice (migration NNN)` به main push کن، بدون تغییر در هیچ فایل دیگر.» سپس restrictions: «هیچ migration موجودی را تغییر نده، در `dot-internal-decision-pack` دست نزن، migration را مستقیماً اجرا نکن — Supabase auto-apply می‌کند.»

Claude Code فایل را push می‌کند، Supabase auto-applies آن را، و اپراتور در dashboard تأیید می‌کند که ردیف جدید در Database → Migrations ظاهر شده است. اگر ردیف ظاهر نشد، احتمالاً مشکل از trivial commit است که در Azura هم پیش آمد، و راه‌حل ساده است: یک commit کوچک اضافی (مثلاً به CHANGELOG.md) که Supabase trigger می‌خورد. در حالت نرمال، migrationها در ۲-۳ دقیقه روی production می‌نشینند.

-----

## بخش هفتم — به‌روزرسانی Master Reference

بعد از اعمال موفق migration، یک سند master reference برای پروژه‌ی جدید ساخته می‌شود، با همان ساختار `docs/azura_master_reference.md`. این سند canonical source of truth برای آن پروژه است، و شامل: لیست کامل sources با کلاس‌ها، لیست کامل entities با metadata، لیست edgesها، رجیستری اتم‌ها سازماندهی‌شده بر اساس layer (L0 framework، L1 platform، L2 project، L2.5 unit، L4 operator)، تناقض‌ها و وضعیت حلشان، missingness‌ها با context و question-back، و verdict نهایی پروژه (مثلاً «حساس به توقف» یا «بدون نگرانی» با توضیح).

این سند در یک commit جداگانه به repo اضافه می‌شود، با مسیر `docs/<project_name>_master_reference.md`. این یک documentation commit است که Supabase به آن واکنش نمی‌دهد.

-----

## بخش هشتم — مثال کامل (Quick-Start)

برای روشن‌تر کردن، اینجا یک skeleton SQL برای اضافه‌کردن یک پروژه‌ی فرضی به نام “Project X” آورده می‌شود. این skeleton الگوی پیاده‌سازی واقعی است که در هر پروژه‌ی جدید pattern-match می‌شود.

```sql
BEGIN;

-- گام سوم: Sources جدید
INSERT INTO private.sources (source_id, source_name, source_url, source_class, publisher, publication_date, language) VALUES
    ('11111111-1111-1111-1111-000000000031', 'Project X Official Brochure', 'https://...', 2, 'Developer X', '2026-01-01', 'en'),
    ('11111111-1111-1111-1111-000000000032', 'Project X Press Release', 'https://...', 3, 'GCC Business News', '2026-02-01', 'en');

-- گام چهارم: Entities جدید (موجودیت‌های مختص پروژه)
-- توجه: Oman، Bank Muscat، Tabreed و غیره از Azura موجود هستند و نیازی به re-insert ندارند
INSERT INTO private.entities (entity_id, entity_type, canonical_name, jurisdiction, status, metadata) VALUES
    ('22222222-1300-0000-0000-000000000002', 'jv', 'Developer X JV S.A.O.C.', 'OM', 'active', '{"persian_name":"..."}'),
    ('22222222-2100-0000-0000-000000000002', 'project', 'Project X', 'OM', 'off_plan', '{"persian_name":"..."}');

-- گام پنجم: Edges جدید
INSERT INTO private.edges (from_entity, to_entity, edge_type, metadata) VALUES
    ('22222222-1300-0000-0000-000000000002', '22222222-2100-0000-0000-000000000002', 'contractual_party_for_buyer', '{"note":"..."}');

-- گام ششم: Atoms جدید
INSERT INTO private.atoms (atom_id, entity_id, criterion_id, claim, source_id, source_class, level, valid_from, content_hash, language) VALUES
    ('44444444-2000-0000-0000-000000000056', '22222222-2100-0000-0000-000000000002', '33333333-2000-0000-0000-000000000002',
     'متن claim به Persian',
     '11111111-1111-1111-1111-000000000031', 2, 'project_specific', '2026-01-01',
     encode(digest('PX-A001-LocationClaim', 'sha256'), 'hex'), 'fa');

-- گام هفتم: Missingness
INSERT INTO private.missingness (entity_id, criterion_id, subject, severity, description, context_notes, question_back) VALUES
    ('22222222-2100-0000-0000-000000000002', '33333333-2000-0000-0000-000000000004',
     'تاریخ تحویل', 'critical',
     'هیچ developer commitment رسمی منتشر نشده',
     'الگوی Y ساله از کارگزاران تخمین Z آمده',
     'سؤال برای اپراتور هنگام مراجعه');

COMMIT;
```

این skeleton به‌عنوان شروع‌گاه استفاده می‌شود، با پر کردن دقیق هر فیلد بر اساس research output پروژه‌ی واقعی.

-----

## بخش نهم — Common Pitfalls و چطور اجتناب کنیم

از تجربه‌ی Azura و pattern‌های شناخته‌شده در data engineering، چند pitfall رایج برای پروژه‌های آینده پیش‌بینی می‌شوند.

**Pitfall اول، duplicate UUID‌ها**. اگر اپراتور با pattern آشنا نباشد، ممکن است UUID‌هایی برای پروژه‌ی جدید بسازد که با Azura تداخل دارند. **راه‌حل:** قبل از هر INSERT، یک query کوچک روی `private.atoms` یا `private.entities` بزن تا مطمئن شوی هیچ UUID مشترکی وجود ندارد. Claude Code می‌تواند این چک را قبل از push انجام دهد.

**Pitfall دوم، fragment اطلاعات**. اپراتور ممکن است وسوسه شود که برای پروژه‌ی جدید فقط چند اتم سطحی اضافه کند تا «شروع کند». **این کار خطرناک است** چون پروژه‌ی نیمه‌مستند در پایگاه به همان اندازه‌ی پروژه‌ی بدون داده گمراه‌کننده است. **راه‌حل:** پروژه‌ی جدید فقط زمانی اضافه می‌شود که G1-G4 کامل pass شده باشد، با حداقل ۲۰ اتم پایه.

**Pitfall سوم، اشتباه classification of source class**. تشخیص بین source class 2 (developer رسمی) و source class 3 (media معتبر) و source class 4 (broker secondary) ممکن است سلیقه‌ای به نظر برسد. **راه‌حل:** قاعده‌ی ثابت این است: کلاس ۱ regulator/auditor/court، کلاس ۲ developer رسمی یا audited FS، کلاس ۳ media با editorial standards (مثل Zawya، Reuters، Oman Observer)، کلاس ۴ broker، listing، یا secondary aggregator (مثل Optimo، Dubizzle، Jiwak).

**Pitfall چهارم، تداخل level**. ممکن است یک claim مرز بین levelها داشته باشد (مثل «استراتژی brand-reliance» که هم analytical_insight است هم درباره‌ی پلتفرم). **راه‌حل:** اگر claim یک fact مستند است، level مستقیم استفاده می‌شود. اگر claim یک synthesis است که توسط محقق ساخته شده، level=analytical_insight استفاده می‌شود. در مورد ابهام، analytical_insight انتخاب امن‌تر است.

**Pitfall پنجم، فراموش‌کردن content_hash**. PostgreSQL هشدار نمی‌دهد اگر content_hash duplicate باشد یا اگر naive format استفاده شود. **راه‌حل:** content_hash باید با ID اتم و یک short description ترکیب شود تا منحصر بماند، مثل `digest('PX-A001-LocationClaim', 'sha256')`.

-----

## بخش دهم — تأیید نهایی G9

بعد از این که پروژه به‌صورت کامل پایگاه شد، master reference نوشته شد، و audit pass شد، اپراتور یک self-check نهایی انجام می‌دهد قبل از declaring پروژه به‌عنوان «done».

این چک‌لیست شامل: آیا تمام ۱۰ گام بخش چهارم کامل اجرا شد؟ آیا چهار validation بخش پنجم pass شد؟ آیا commit و push بدون تغییر در migrationهای موجود انجام شد؟ آیا Supabase migration را اعمال کرد و در dashboard دیده می‌شود؟ آیا master reference در `docs/` با اسم درست نشست؟ آیا verification queries که در `docs/verification_queries.sql` هستند نتایج مورد انتظار می‌دهند برای پروژه‌ی جدید؟ آیا گراف visualization به‌روز شد (در migration بعدی) تا پروژه‌ی جدید را نشان دهد؟

اگر همه‌ی این موارد pass، پروژه به‌صورت رسمی در Prism live است. در غیر این صورت، هر کدام که نقص دارد ابتدا رفع شود.

-----

## ضمیمه — Catalog مرجع

برای راحتی، یک مرجع سریع از enumerations که در schema تثبیت شده‌اند.

**entity_type** (۹ مقدار): country، holding، developer، jv، master_development، project، product_phase، unit_type، operator.

**edge_type** (۱۰ مقدار): owns، joint_venture_with، develops، contains، operates، finances، brands، manages_post_handover، regulates، contractual_party_for_buyer.

**source_class** (۴ مقدار): ۱ (regulator/auditor/court)، ۲ (developer official/audited)، ۳ (credible media)، ۴ (broker/secondary).

**level** (۴ مقدار): framework، platform_level، project_specific، analytical_insight.

**status** (project): off_plan، ready_turnkey، ready_resale، active، concept.

**section** (criteria): gate_board، score_core، developer_modifier، descriptive، escalation.

**severity** (missingness): critical، significant، moderate، low.

**status** (contradictions): open، resolved، explained.

**status** (atoms): active، superseded، contradicted، retracted.

-----

## ختام

این سند، طبق هدف اولیه‌ی گیت G8، فرایند خلاقانه‌ی اضافه‌کردن پروژه را به یک execution مکانیکی تبدیل می‌کند. هر کسی که این سند را دارد و research output یک پروژه‌ی جدید را در دست دارد، می‌تواند migration کامل و سازگار با معماری Prism بنویسد. این یعنی scale‌پذیری: اضافه‌کردن پروژه‌ی دوم، سوم، و چهلم نباید زمان بیشتری از زمان تحقیق ببرد. تصمیمات معماری یک بار گرفته شده، حالا فقط داده به این chassis ریخته می‌شود.