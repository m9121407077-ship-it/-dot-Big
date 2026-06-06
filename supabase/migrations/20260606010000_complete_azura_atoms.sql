-- ============================================================================
-- Dot Prism Graph — Migration 003: Complete Azura Atom Set
-- Purpose: Load the remaining 38 atoms from the Azura Master Reference
-- Prerequisite: Migrations 001 (schema) and 002 (initial Azura data) applied
-- Date: 2026-06-06
-- 
-- After this migration:
--   - All 55 atoms from Master Reference are loaded
--   - Source classification, level (framework/platform/project/analytical), and
--     bitemporal metadata are complete
--   - Provenance is fully traceable for every claim in the Azura dossier
-- ============================================================================

BEGIN;

-- ============================================================================
-- L0 FRAMEWORK ATOMS — Remaining 8
-- Each is tied to the Sultanate of Oman entity. Most relate to legal framework
-- or jurisdictional facts that apply to ALL ITC projects, not just Azura.
-- ============================================================================

INSERT INTO private.atoms (atom_id, entity_id, criterion_id, claim, source_id, source_class, level, valid_from, content_hash, language) VALUES

-- AZ-A013: Title transfer fee. Framework-level Omani administrative cost.
-- This atom underpins the buyer's understanding that 3% above purchase price
-- is the registry fee at MOHUP, not a developer charge.
('44444444-0001-0000-0000-000000000013', '22222222-0000-0000-0000-000000000001', '33333333-1000-0000-0000-000000000004',
 'هزینه انتقال title deed (registry fee) در عمان ۳٪ از قیمت خرید است',
 '11111111-1111-1111-1111-000000000022', 3, 'framework', '2024-01-01',
 encode(digest('AZ-A013-TransferFee3pct', 'sha256'), 'hex'), 'fa'),

-- AZ-A014: Golden Residency 2025 relaunch. This affects Azura buyers above
-- OMR 200,000 threshold who can pursue residency for self + first-degree family.
('44444444-0001-0000-0000-000000000014', '22222222-0000-0000-0000-000000000001', NULL,
 'Golden Residency عمان در آگوست ۲۰۲۵ با حداقل سرمایه‌گذاری OMR 200,000 دوباره راه‌اندازی شد، با اقامت ۱۰ ساله برای خریدار و بستگان درجه یک',
 '11111111-1111-1111-1111-000000000022', 3, 'framework', '2025-08-01',
 encode(digest('AZ-A014-GoldenResidency', 'sha256'), 'hex'), 'fa'),

-- AZ-A015: Personal income tax horizon. Currently zero but legislated for 2028.
-- Material for buyers planning long-term rental income from Azura units.
('44444444-0001-0000-0000-000000000015', '22222222-0000-0000-0000-000000000001', NULL,
 'مالیات بر درآمد شخصی در عمان قانون‌گذاری شده با اجرای ۲۰۲۸ برای درآمدهای بالا. فعلاً درآمد اجاره مالیات شخصی ندارد',
 '11111111-1111-1111-1111-000000000022', 3, 'framework', '2026-01-01',
 encode(digest('AZ-A015-PersonalIncomeTax', 'sha256'), 'hex'), 'fa'),

-- AZ-A019: Preliminary Real Estate Register requirement under RD 79/2025.
-- This is a major buyer protection: prevents double-selling and creates
-- pre-construction legal record of buyer's claim. Critical context for Azura.
('44444444-0001-0000-0000-000000000019', '22222222-0000-0000-0000-000000000001', '33333333-1000-0000-0000-000000000004',
 'RD 79/2025 الزام می‌کند تمام واحدهای Off-Plan و قراردادهایشان ظرف ۶ ماه در Preliminary Real Estate Register ثبت شوند تا از فروش مضاعف جلوگیری شود',
 '11111111-1111-1111-1111-000000000003', 1, 'framework', '2026-03-10',
 encode(digest('AZ-A019-PrelimRegister', 'sha256'), 'hex'), 'fa'),

-- AZ-A020: Marketing License requirement under RD 79/2025. New regulatory
-- gate before developer can market off-plan units.
('44444444-0001-0000-0000-000000000020', '22222222-0000-0000-0000-000000000001', NULL,
 'RD 79/2025 الزام Marketing License جدید برای توسعه‌دهندگان را برقرار کرده که نیازمند تأیید حسابداران و مشاوران پروژه است',
 '11111111-1111-1111-1111-000000000003', 1, 'framework', '2026-03-10',
 encode(digest('AZ-A020-MarketingLicense', 'sha256'), 'hex'), 'fa'),

-- AZ-A024: Municipal tax on rental contracts. Affects buyers who plan to rent.
('44444444-0001-0000-0000-000000000024', '22222222-0000-0000-0000-000000000001', NULL,
 'مالیات شهرداری ۳٪ روی ارزش قرارداد اجاره برای موجران در عمان',
 '11111111-1111-1111-1111-000000000022', 3, 'framework', '2024-01-01',
 encode(digest('AZ-A024-MunicipalTax', 'sha256'), 'hex'), 'fa'),

-- AZ-A027: Why escrow details aren't public — analytical insight from Gemini.
-- Critical for buyer expectation management: don't expect public escrow info,
-- ask at SPA signing instead.
('44444444-0001-0000-0000-000000000027', '22222222-0000-0000-0000-000000000001', '33333333-1000-0000-0000-000000000003',
 'فرهنگ شرکتی عمان به‌صورت سنتی عدم افشای عمومی شماره escrow است. خریدار فقط در زمان امضای SPA با مشخصات حساب امانی مواجه می‌شود (back-end management بین developer، بانک و ناظر MoHUP)',
 '11111111-1111-1111-1111-000000000014', 3, 'analytical_insight', '2026-06-06',
 encode(digest('AZ-A027-EscrowCulture', 'sha256'), 'hex'), 'fa'),

-- AZ-A028: RD 79/2025 escrow distribution mechanism — protects buyers if
-- project is cancelled. Critical safety net.
('44444444-0001-0000-0000-000000000028', '22222222-0000-0000-0000-000000000001', '33333333-1000-0000-0000-000000000003',
 'RD 79/2025: توافق‌نامه escrow میان توسعه‌دهنده و بانک باید مکانیزم توزیع مانده‌حساب در صورت لغو یا توقف پروژه را مشخص کند، که حقوق خریدار را در سناریوی worst-case حفظ می‌کند',
 '11111111-1111-1111-1111-000000000003', 1, 'framework', '2026-03-10',
 encode(digest('AZ-A028-EscrowDistribution', 'sha256'), 'hex'), 'fa');

-- ============================================================================
-- L1 PLATFORM/JV ATOMS — Remaining 7
-- These atoms describe Al Mouj as platform (master development) and as JV
-- entity. They modify but do not directly score Azura — per Developer Context
-- Modifier rule from L2 pilot.
-- ============================================================================

INSERT INTO private.atoms (atom_id, entity_id, criterion_id, claim, source_id, source_class, level, valid_from, content_hash, language) VALUES

-- AZ-A011: JV partner roster. Three partners produce Al Mouj S.A.O.C.
('44444444-1000-0000-0000-000000000011', '22222222-1300-0000-0000-000000000001', NULL,
 'شرکای JV Al Mouj Muscat S.A.O.C. عبارت‌اند از MAF Properties (سهم تأیید‌شده ۵۰٪)، OMRAN Group SAOC (شرکت دولتی توسعه گردشگری)، و Tanmia Oman SAOC (شرکت ملی توسعه سرمایه‌گذاری)',
 '11111111-1111-1111-1111-000000000005', 2, 'platform_level', '2025-01-01',
 encode(digest('AZ-A011-JVPartners', 'sha256'), 'hex'), 'fa'),

-- AZ-A016: Delivery track record. 2024 was 160+ units. Platform-level only,
-- not directly attributable to Azura per Developer Context Modifier rule.
('44444444-1000-0000-0000-000000000016', '22222222-2000-0000-0000-000000000001', '33333333-2000-0000-0000-000000000004',
 'Al Mouj در سال ۲۰۲۴ بیش از ۱۶۰ واحد مسکونی و بلوک اداری تحویل داد — سابقه تحویل پلتفرم‌level که اعتماد محدود به ادامه تحویل می‌سازد ولی Azura-specific نیست',
 '11111111-1111-1111-1111-000000000005', 2, 'platform_level', '2024-12-31',
 encode(digest('AZ-A016-DeliveryRecord2024', 'sha256'), 'hex'), 'fa'),

-- AZ-A017: Al Mouj maturity context. Operating since 2007, 75% complete by 2020.
-- This is what makes the destination feel real, not promised.
('44444444-1000-0000-0000-000000000017', '22222222-2000-0000-0000-000000000001', '33333333-2000-0000-0000-000000000002',
 'Al Mouj Muscat از ۲۰۰۷ شروع شده، master plan ۴,۰۰۰ واحدی در ۲.۳ km² تا ۲۰۲۰ به ۷۵٪ کامل شده، با حدود ۲۰,۰۰۰ ساکن فعال — یک مقصد بالغ نه یک render آینده',
 '11111111-1111-1111-1111-000000000027', 3, 'platform_level', '2020-01-01',
 encode(digest('AZ-A017-AlMoujMaturity', 'sha256'), 'hex'), 'fa'),

-- AZ-A026: Bank Muscat as pioneer of real estate escrow. Strong circumstantial
-- signal for likely Azura escrow holder.
('44444444-1000-0000-0000-000000000026', '22222222-4000-0000-0000-000000000002', '33333333-1000-0000-0000-000000000003',
 'بانک مسقط نخستین سرویس حساب امانی اختصاصی بخش املاک در عمان را راه‌اندازی کرد، با شراکت استراتژیک تأیید‌شده با Al Mouj',
 '11111111-1111-1111-1111-000000000021', 2, 'platform_level', '2023-01-01',
 encode(digest('AZ-A026-BankMuscatPioneer', 'sha256'), 'hex'), 'fa'),

-- AZ-A029: Al Mouj JV financial independence from MAF Holding. Critical
-- for liability analysis — buyer's counterparty is Omani SPV, not MAF group.
('44444444-1000-0000-0000-000000000029', '22222222-1300-0000-0000-000000000001', NULL,
 'Al Mouj Muscat S.A.O.C. از نظر مالی مستقل از MAF Holding است. در دعاوی حقوقی، خریدار صرفاً با نهاد عمانی Al Mouj S.A.O.C. طرف است، نه با MAF Holding مادر',
 '11111111-1111-1111-1111-000000000030', 1, 'platform_level', '2024-01-01',
 encode(digest('AZ-A029-JVIndependence', 'sha256'), 'hex'), 'fa'),

-- AZ-A032: Historical build cycle pattern. 24-36 months for Al Mouj projects.
-- Anchor for delay risk assessment when developer-specific date is missing.
('44444444-1000-0000-0000-000000000032', '22222222-2000-0000-0000-000000000001', '33333333-2000-0000-0000-000000000004',
 'الگوی تاریخی Al Mouj برای زمان launch تا handover پروژه‌های قبلی (Juman One، Marsa Gardens) ۲۴ تا ۳۶ ماه بوده — anchor تخمین برای پروژه‌های جدید مثل Azura در غیاب تاریخ رسمی developer',
 '11111111-1111-1111-1111-000000000014', 3, 'platform_level', '2024-01-01',
 encode(digest('AZ-A032-BuildCyclePattern', 'sha256'), 'hex'), 'fa'),

-- AZ-A033: Bank Muscat strategic partnership signal. Circumstantial evidence
-- for likely escrow holder.
('44444444-1000-0000-0000-000000000033', '22222222-4000-0000-0000-000000000002', '33333333-1000-0000-0000-000000000003',
 'بانک مسقط شریک استراتژیک Al Mouj در رویدادهای مشترک، تسهیلات mortgage ویژه، و سرویس‌های مالی — احتمال بالا ولی نه تأیید رسمی برای نگهداری escrow اختصاصی Azura',
 '11111111-1111-1111-1111-000000000021', 2, 'platform_level', '2025-01-01',
 encode(digest('AZ-A033-BankMuscatPartner', 'sha256'), 'hex'), 'fa');

-- ============================================================================
-- L2 PROJECT ATOMS — Remaining 11
-- These are specific to Azura Beach Residences. They score directly via the
-- Score Core criteria (location, market, delay, disclosure) or sit in Section A
-- Gate Board or Section D Descriptive.
-- ============================================================================

INSERT INTO private.atoms (atom_id, entity_id, criterion_id, claim, source_id, source_class, level, valid_from, content_hash, language) VALUES

-- AZ-A002: First dual-frontage in Oman. Differentiation claim verified by 
-- multiple press sources. Scores in location_ecosystem.
('44444444-2000-0000-0000-000000000002', '22222222-2100-0000-0000-000000000001', '33333333-2000-0000-0000-000000000002',
 'Azura Beach Residences اولین dual-frontage residential در عمان است — نمای همزمان اقیانوس و marina با دسترسی مستقیم به ساحل، تأیید‌شده در press releases متعدد Al Mouj',
 '11111111-1111-1111-1111-000000000015', 3, 'project_specific', '2025-07-09',
 encode(digest('AZ-A002-DualFrontage', 'sha256'), 'hex'), 'fa'),

-- AZ-A003: Phase 1 composition. 309 units across 2 apartment buildings + 23 chalets.
('44444444-2000-0000-0000-000000000003', '22222222-2110-0000-0000-000000000001', NULL,
 'فاز ۱ Azura شامل ۳۰۹ واحد است: ۲۸۶ آپارتمان ۱-۳ خوابه در دو ساختمان آپارتمانی + ۲۳ شاله ۴ خوابه ۵ سرویسه، هر شاله با استخر خصوصی plunge و ۳ جای پارکینگ',
 '11111111-1111-1111-1111-000000000010', 2, 'project_specific', '2025-07-06',
 encode(digest('AZ-A003-Phase1Composition', 'sha256'), 'hex'), 'fa'),

-- AZ-A004: Phase 1 sold-out July 2025. Market absorption signal, NOT liquidity.
('44444444-2000-0000-0000-000000000004', '22222222-2110-0000-0000-000000000001', '33333333-2000-0000-0000-000000000003',
 'فاز ۱ Azura در جولای ۲۰۲۵ کاملاً sold-out اعلام شد — سیگنال تقاضای اولیه قوی، ولی طبق قاعده Market Absorption ≠ Liquidity به‌عنوان نقدشوندگی resale تفسیر نمی‌شود چون هنوز تحویل نشده',
 '11111111-1111-1111-1111-000000000013', 3, 'project_specific', '2025-07-31',
 encode(digest('AZ-A004-Phase1SoldOut', 'sha256'), 'hex'), 'fa'),

-- AZ-A005: Phase 2 sold-out Oct 2025. Continued market absorption signal.
('44444444-2000-0000-0000-000000000005', '22222222-2110-0000-0000-000000000002', '33333333-2000-0000-0000-000000000003',
 'فاز ۲ Azura در اکتبر ۲۰۲۵ کاملاً sold-out اعلام شد — تکرار سیگنال جذب بازار قوی، با همان قید عدم انتقال به نقدشوندگی resale',
 '11111111-1111-1111-1111-000000000013', 3, 'project_specific', '2025-10-31',
 encode(digest('AZ-A005-Phase2SoldOut', 'sha256'), 'hex'), 'fa'),

-- AZ-A006: Phase 3+4 composition. Final chapter, 611 total units.
('44444444-2000-0000-0000-000000000006', '22222222-2110-0000-0000-000000000004', NULL,
 'فاز ۳ و ۴ Azura (final chapter) شامل ۵۷۰ آپارتمان premium + ۴۱ duplex chalet ۴ خوابه با استخر خصوصی و آسانسور اختصاصی است — مجموع ۶۱۱ واحد در دو فاز پایانی',
 '11111111-1111-1111-1111-000000000011', 2, 'project_specific', '2026-02-15',
 encode(digest('AZ-A006-Phase34Composition', 'sha256'), 'hex'), 'fa'),

-- AZ-A008: 100% freehold + residency eligibility. Gate-board level information.
('44444444-2000-0000-0000-000000000008', '22222222-2110-0000-0000-000000000004', '33333333-1000-0000-0000-000000000004',
 'Azura Phase 3+4 با ۱۰۰٪ freehold ownership برای تمام ملیت‌ها به فروش می‌رسد، با residency eligibility برای خریدار و بستگان درجه یک',
 '11111111-1111-1111-1111-000000000015', 3, 'project_specific', '2026-02-15',
 encode(digest('AZ-A008-FreeholdResidency', 'sha256'), 'hex'), 'fa'),

-- AZ-A009: CEO "final chapter" statement. Important because it signals
-- no further Azura phases, affecting expectations for future supply.
('44444444-2000-0000-0000-000000000009', '22222222-2110-0000-0000-000000000004', NULL,
 'CEO Al Mouj (Nasser Al Sheibani) فاز ۳+۴ را "final chapter" Azura توصیف کرد — سیگنال developer که سری Azura در همین چهار فاز خاتمه می‌یابد و عرضه‌ی آینده‌ای از این برند نخواهد بود',
 '11111111-1111-1111-1111-000000000011', 2, 'project_specific', '2026-02-15',
 encode(digest('AZ-A009-FinalChapter', 'sha256'), 'hex'), 'fa'),

-- AZ-A034: Phase 2 composition. 307 units in G+3 mid-rise apartment towers.
('44444444-2000-0000-0000-000000000034', '22222222-2110-0000-0000-000000000002', NULL,
 'فاز ۲ Azura شامل ۳۰۷ واحد است: آپارتمان‌های ۱-۳ خوابه در دو برج G+3 (۴ طبقه) + شاله‌های ۴ خوابه — معماری low-rise با تأکید بر privacy',
 '11111111-1111-1111-1111-000000000014', 3, 'project_specific', '2025-10-15',
 encode(digest('AZ-A034-Phase2Composition', 'sha256'), 'hex'), 'fa'),

-- AZ-A036: Milestone percentages not publicly disclosed. Affects payment plan
-- integrity scoring — we know the structure but not the granular percentages.
('44444444-2000-0000-0000-000000000036', '22222222-2100-0000-0000-000000000001', '33333333-2000-0000-0000-000000000001',
 'جزئیات دقیق milestoneها (درصد per stage مثلاً ۲۰٪ در foundation، ۳۰٪ در shell) در منابع عمومی منتشر نشده‌اند. فقط در SPA واقعی تحت نظارت حساب امانی ذکر می‌شوند',
 '11111111-1111-1111-1111-000000000006', 2, 'project_specific', '2026-06-06',
 encode(digest('AZ-A036-MilestoneDetailsHidden', 'sha256'), 'hex'), 'fa'),

-- AZ-A038: Aggressively optimistic broker timeline. Analytical insight that
-- challenges Class 4 estimates against engineering reality.
('44444444-2000-0000-0000-000000000038', '22222222-2100-0000-0000-000000000001', '33333333-2000-0000-0000-000000000004',
 'برخی پلتفرم‌های کارگزاری تخمین تحویل Q4 2026 برای آپارتمان‌های فاز ۱ ارائه داده‌اند، که با لانچ جولای ۲۰۲۵ یعنی فقط ۱۷-۱۸ ماه برای پروژه‌ای با استخر بی‌نهایت و شاله‌های آسانسور-دار — این تخمین aggressively optimistic ارزیابی می‌شود',
 '11111111-1111-1111-1111-000000000024', 4, 'analytical_insight', '2026-06-06',
 encode(digest('AZ-A038-AggressiveTimeline', 'sha256'), 'hex'), 'fa'),

-- AZ-A039: Broker delivery estimates for chalets and Azura 4. Class 4 data
-- but useful as baseline when no developer commitment exists.
('44444444-2000-0000-0000-000000000039', '22222222-2100-0000-0000-000000000001', '33333333-2000-0000-0000-000000000004',
 'برخی لیستینگ‌های کارگزاری تخمین تحویل ۲۰۲۸ برای شاله‌ها و ۲۰۲۹ برای Azura فاز ۴ ارائه داده‌اند — Class 4 evidence فاقد commitment رسمی developer',
 '11111111-1111-1111-1111-000000000024', 4, 'project_specific', '2026-04-01',
 encode(digest('AZ-A039-BrokerEstimates', 'sha256'), 'hex'), 'fa');

-- ============================================================================
-- L2.5 UNIT TYPE ATOMS — Remaining 8
-- These describe the physical product specs from official PDF brochures.
-- They populate the unit_type entities with sourced dimensional data.
-- ============================================================================

INSERT INTO private.atoms (atom_id, entity_id, criterion_id, claim, source_id, source_class, level, valid_from, content_hash, language) VALUES

-- AZ-A041: 1BR apartment specifications from official brochure.
('44444444-2500-0000-0000-000000000041', '22222222-2120-0000-0000-000000000001', NULL,
 'آپارتمان ۱ خوابه Azura (انواع A1، A2، A3): مساحت کل built-up ۷۰-۱۰۷ مترمربع (داخلی ۶۳-۹۶، خارجی/بالکن ۸-۱۴). مرجع: بروشورهای رسمی PDF آرشیو شده در almouj.com',
 '11111111-1111-1111-1111-000000000008', 2, 'project_specific', '2026-02-15',
 encode(digest('AZ-A041-1BR-Specs', 'sha256'), 'hex'), 'fa'),

-- AZ-A042: 2BR apartment specifications.
('44444444-2500-0000-0000-000000000042', '22222222-2120-0000-0000-000000000002', NULL,
 'آپارتمان ۲ خوابه Azura (انواع B5، B6، B8، B10): مساحت کل built-up ۱۳۶-۱۴۵ مترمربع (داخلی ۱۲۴-۱۳۰، خارجی ۱۲-۱۹). مرجع: بروشورهای رسمی AzuraII، AZ3، AZ4',
 '11111111-1111-1111-1111-000000000008', 2, 'project_specific', '2026-02-15',
 encode(digest('AZ-A042-2BR-Specs', 'sha256'), 'hex'), 'fa'),

-- AZ-A043: 3BR apartment specifications.
('44444444-2500-0000-0000-000000000043', '22222222-2120-0000-0000-000000000003', NULL,
 'آپارتمان ۳ خوابه Azura (انواع C1، C2، C3): مساحت کل built-up ۱۶۶-۱۶۸ مترمربع (داخلی ۱۴۵-۱۵۰، خارجی ۱۷-۲۹ بسته به نمای ساحل یا مارینا)',
 '11111111-1111-1111-1111-000000000008', 2, 'project_specific', '2026-02-15',
 encode(digest('AZ-A043-3BR-Specs', 'sha256'), 'hex'), 'fa'),

-- AZ-A045: Correction of earlier 5BR error. Critical for accurate registry.
('44444444-2500-0000-0000-000000000045', '22222222-2100-0000-0000-000000000001', NULL,
 'هیچ واحد ۵ خوابه در پروژه Azura وجود ندارد. ادعای پنج‌خوابه در داده‌های ثانویه از اشتباه خواندن عبارت "four-bedroom, five-bathroom" در press releases بوده — اصلاح در همه فازها',
 '11111111-1111-1111-1111-000000000008', 2, 'project_specific', '2026-02-15',
 encode(digest('AZ-A045-No5BR', 'sha256'), 'hex'), 'fa'),

-- AZ-A046: Building height distinction by phase. Resolves earlier contradiction.
-- Phase 2 is G+3 (low-rise), Phase 4 is G+11 (mid-rise per AZ4 brochure +
-- Savills "13-floor" listing). The "10 floors" claim was metadata error.
('44444444-2500-0000-0000-000000000046', '22222222-2110-0000-0000-000000000004', NULL,
 'ارتفاع ساختمان‌ها بین فازها متفاوت است: فاز ۲ آپارتمان‌ها G+3 (۴ طبقه) per AzuraII brochure، فاز ۴ آپارتمان‌ها G+11 (تا طبقه ۱۱) per AZ4.pdf، Savills فاز ۴ را 13-floor توصیف کرده، شاله‌ها در همه فازها G+2 (۳ طبقه)',
 '11111111-1111-1111-1111-000000000008', 2, 'project_specific', '2026-02-15',
 encode(digest('AZ-A046-BuildingHeights', 'sha256'), 'hex'), 'fa'),

-- AZ-A047: Starting price ranges by phase. Resolves price contradiction.
('44444444-2500-0000-0000-000000000047', '22222222-2110-0000-0000-000000000004', NULL,
 'قیمت شروع آپارتمان‌ها بین OMR 69,000 تا 88,000 بسته به فاز و سایز: فاز II از 88,000، فاز III/IV از 69,000. واحدهای beachfront premium 15-25٪ بالاتر',
 '11111111-1111-1111-1111-000000000006', 2, 'project_specific', '2026-02-15',
 encode(digest('AZ-A047-AptPriceRange', 'sha256'), 'hex'), 'fa'),

-- AZ-A048: Chalet starting price from broker estimates (Class 4).
('44444444-2500-0000-0000-000000000048', '22222222-2120-0000-0000-000000000004', NULL,
 'قیمت شروع شاله ۴ خوابه Type D: حدود OMR 450,000 تا 475,000 per broker estimates. هیچ price list رسمی Class 2 منتشر نشده است',
 '11111111-1111-1111-1111-000000000025', 4, 'project_specific', '2026-04-01',
 encode(digest('AZ-A048-ChaletPrice', 'sha256'), 'hex'), 'fa'),

-- AZ-A050: Parking allocation missingness. Important for buyer planning.
('44444444-2500-0000-0000-000000000050', '22222222-2100-0000-0000-000000000001', NULL,
 'تخصیص دقیق پارکینگ به ازای نوع واحد در منابع عمومی یافت نشد. فقط شاله‌ها صریحاً ۳ جای پارکینگ ذکر شده‌اند. تعداد پارکینگ آپارتمان‌ها هنگام امضای SPA باید بررسی شود',
 '11111111-1111-1111-1111-000000000008', 2, 'project_specific', '2026-06-06',
 encode(digest('AZ-A050-ParkingMissing', 'sha256'), 'hex'), 'fa');

-- ============================================================================
-- L4 OPERATOR ATOMS — Remaining 4
-- These describe Tabreed and service charges. Critical for buyer's total
-- cost-of-ownership understanding.
-- ============================================================================

INSERT INTO private.atoms (atom_id, entity_id, criterion_id, claim, source_id, source_class, level, valid_from, content_hash, language) VALUES

-- AZ-A052: Tabreed billing separation. Important: cooling cost is NOT in
-- service charge — separate bill on top.
('44444444-4000-0000-0000-000000000052', '22222222-4000-0000-0000-000000000001', NULL,
 'هزینه Tabreed جدا از service charge ساختمان است: capacity charge بر اساس تناژ تخصیصی واحد + consumption charge ماهیانه. صدور صورت‌حساب جداگانه به مالک. نرخ دقیق Tabreed برای Azura عمومی نشده',
 '11111111-1111-1111-1111-000000000020', 2, 'platform_level', '2025-01-01',
 encode(digest('AZ-A052-TabreedBilling', 'sha256'), 'hex'), 'fa'),

-- AZ-A053: Apartment service charge estimate. Class 4 estimate from market analysis.
('44444444-4000-0000-0000-000000000053', '22222222-2100-0000-0000-000000000001', NULL,
 'service charge آپارتمان‌های beachfront Azura: محدوده تخمینی ۸ تا ۱۵ OMR per sqm سالانه (پایان بالاتر به‌خاطر استخر بی‌نهایت، جیم اختصاصی، دسترسی ساحلی مستقیم). هیچ نرخ رسمی Class 2 منتشر نشده',
 '11111111-1111-1111-1111-000000000022', 4, 'project_specific', '2026-04-01',
 encode(digest('AZ-A053-AptServiceCharge', 'sha256'), 'hex'), 'fa'),

-- AZ-A054: Chalet service charge estimate. Lower than apartments due to less
-- shared infrastructure dependence.
('44444444-4000-0000-0000-000000000054', '22222222-2120-0000-0000-000000000004', NULL,
 'service charge شاله‌های Azura: محدوده تخمینی ۴ تا ۷ OMR per sqm سالانه (پایین‌تر به‌خاطر اشتراک کمتر در فضاهای داخلی ساختمان و تمرکز نگهداری روی باغ و استخر خصوصی)',
 '11111111-1111-1111-1111-000000000022', 4, 'project_specific', '2026-04-01',
 encode(digest('AZ-A054-ChaletServiceCharge', 'sha256'), 'hex'), 'fa'),

-- AZ-A055: Sinking fund recommendation. Buyer should budget separately for
-- major maintenance reserves over time.
('44444444-4000-0000-0000-000000000055', '22222222-2100-0000-0000-000000000001', NULL,
 'مشاوران سرمایه‌گذاری توصیه می‌کنند سالانه حدود ۱٪ ارزش ملک به‌عنوان sinking fund برای maintenance reserve کنار گذاشته شود. وجود رسمی sinking fund برای Azura هنوز عمومی نشده — احتمالاً در قانون جدید RD 79/2025 توسط انجمن مالکان مدیریت خواهد شد',
 '11111111-1111-1111-1111-000000000014', 3, 'analytical_insight', '2026-06-06',
 encode(digest('AZ-A055-SinkingFund', 'sha256'), 'hex'), 'fa');

-- ============================================================================
-- VERIFICATION: After this migration completes, the atoms table should hold
-- approximately 55 total active rows for Azura-related entities. The exact
-- count depends on which atoms were loaded as samples in 002 vs added here.
-- 
-- The provenance graph should now be: every claim in the Azura dossier can be
-- traced through atom → source → URL. Every legal article, every JV partner,
-- every brochure dimension, every analytical insight has a chain back to its
-- origin.
-- ============================================================================

COMMIT;

-- ============================================================================
-- DONE. Migration 003 complete. Full 55-atom Azura registry now live.
-- 
-- Next migration in this stream (whenever a new project starts) follows the
-- same pattern: insert new sources, new entities, new edges, then atoms.
-- The schema does not change; only data accumulates.
-- ============================================================================
