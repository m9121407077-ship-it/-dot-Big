# Azura Beach Residences — مرجع جامع و نهایی Prism
**وضعیت:** G1 + G3 + G4 کامل، آماده برای پیاده‌سازی در Claude Code
**تاریخ:** ۱۷ خرداد ۱۴۰۵
**روش:** ترکیب G1 اولیه + دو دور تحقیق G2 (Grok + Gemini) + اعتبارسنجی گراف + ممیزی ضدسوگیری
**هدف این فایل:** تنها منبع canonical حقیقت Azura برای انتقال به Claude Code و schema implementation

---

## بخش اول — رجیستری کامل اتم‌ها

این رجیستری ۵۵ اتم فعال دارد که در پنج سطح طبقه‌بندی شده‌اند: L0 (چارچوب عمان)، L1 (Al Mouj و JV)، L2 (پروژه‌ی Azura)، L2.5 (نوع واحدها و مشخصات)، و L4 (اپراتورها و عملیات). هر اتم منبع و کلاسش مشخص است.

### اتم‌های L0 — چارچوب حقوقی و رگولاتوری عمان

اتم AZ-A012 می‌گوید escrow برای خرید Off-Plan در عمان از طریق Royal Decree 30/2018 الزامی است. منبع: decree.om و تحلیل Trowers & Hamlins. کلاس ۱.

اتم AZ-A018 می‌گوید Royal Decree 79/2025 (قانون تنظیم بازار املاک) در ۱۴ سپتامبر ۲۰۲۵ صادر و در حدود ۱۰ مارس ۲۰۲۶ بعد از دوره‌ی گذار ۱۸۰ روزه اجرایی شده. منبع: تحلیل حقوقی Trowers و BSA Law. کلاس ۱/۳.

اتم AZ-A019 می‌گوید RD 79/2025 الزام می‌کند تمام واحدهای Off-Plan و قراردادهایشان ظرف شش ماه در «Preliminary Real Estate Register» ثبت شوند تا از فروش مضاعف جلوگیری شود. منبع: Gemini تحلیل قانون. کلاس ۳.

اتم AZ-A020 می‌گوید RD 79/2025 الزام Marketing License جدید را برقرار کرده که نیازمند تأیید حسابداران و مشاوران پروژه است. منبع: Gemini. کلاس ۳.

اتم AZ-A021 می‌گوید ماده ۲۶۷ قانون مدنی عمان (Royal Decree 29/2013) به قاضی اختیار می‌دهد liquidated damages توافق‌شده در قرارداد را نادیده بگیرد و آن را با «خسارت واقعی متحمل‌شده» تطبیق دهد. هرگونه توافق قراردادی که این حق دادگاه را سلب کند null and void است. این یکی از مهم‌ترین اتم‌های buyer-side تمام پرونده است. منبع: تحلیل Dentons و Curtis. کلاس ۲.

اتم AZ-A022 می‌گوید ماده ۱۷۶ قانون مدنی عمان: خسارت غیرمستقیم (مثل سود از دست‌رفته‌ی اجاره) فقط وقتی قابل‌مطالبه است که سازنده عمداً بی‌مبالاتی کرده باشد (reckless conduct). منبع: تحلیل CMS Law. کلاس ۲.

اتم AZ-A023 می‌گوید ماده ۲۴۶ قانون مدنی عمان: الزام به حسن نیت در اجرای قرارداد، که به خریدار حق فسخ قرارداد و استرداد کامل وجوه را در صورت تأخیرهای طولانی و غیرموجه که هدف اصلی قرارداد را از بین می‌برند، می‌دهد. منبع: تحلیل Al Tamimi و Curtis. کلاس ۲.

اتم AZ-A013 می‌گوید هزینه‌ی انتقال title deed در عمان ۳٪ قیمت خرید است. منبع: Sanad Services و منابع متعدد. کلاس ۳.

اتم AZ-A014 می‌گوید Golden Residency در ۱ آگوست ۲۰۲۵ با حداقل OMR 200,000 دوباره راه‌اندازی شد. منبع: Sands of Wealth. کلاس ۳.

اتم AZ-A015 می‌گوید مالیات بر درآمد شخصی در عمان قانون‌گذاری شده با اجرای ۲۰۲۸ برای درآمد بالا. فعلاً درآمد اجاره مالیات ندارد. منبع: Sands of Wealth. کلاس ۳.

اتم AZ-A024 می‌گوید مالیات شهرداری ۳٪ روی ارزش قرارداد اجاره برای موجران. منبع: Gemini تحلیل. کلاس ۳.

اتم AZ-A025 می‌گوید MoHUP در ۲۴ می ۲۰۲۶ صفحه‌ی رسمی «Escrow Account Details for Real Estate Development Projects» منتشر کرد. منبع: mohup.gov.om/en/media/announcements. کلاس ۱.

اتم AZ-A026 می‌گوید بانک مسقط (Bank Muscat) پیشگام خدمات حساب امانی اختصاصی بخش املاک در عمان است. منبع: bankmuscat.om media center. کلاس ۲.

اتم AZ-A027 می‌گوید فرهنگ شرکتی عمان به‌صورت سنتی عدم افشای عمومی شماره‌ی escrow است؛ خریدار فقط در زمان امضای SPA با مشخصات حساب امانی مواجه می‌شود (back-end management بین developer، بانک و ناظر MoHUP). منبع: تحلیل Gemini. کلاس ۳ (insight).

اتم AZ-A028 می‌گوید RD 79/2025 سند خاتمه escrow agreement را الزام می‌کند: توافق‌نامه‌ی escrow میان توسعه‌دهنده و بانک باید مکانیزم توزیع مانده‌حساب در صورت لغو یا توقف پروژه را مشخص کند. منبع: تحلیل حقوقی. کلاس ۲.

### اتم‌های L1 — Al Mouj Muscat S.A.O.C. و JV

اتم AZ-A010 می‌گوید MAF Properties مالک ۵۰٪ Al Mouj Muscat S.A.O.C. است. منبع: MAF Properties FY2025 Audited FS. کلاس ۱.

اتم AZ-A011 می‌گوید شرکای JV عبارت‌اند از MAF Properties، OMRAN، و Tanmia. منبع: سایت رسمی Al Mouj. کلاس ۲.

اتم AZ-A029 می‌گوید Al Mouj Muscat S.A.O.C. JV مالی کاملاً مستقل است و به بودجه‌ی MAF Holding وابستگی ندارد. در دعاوی حقوقی، خریدار صرفاً با نهاد عمانی Al Mouj S.A.O.C. طرف است. منبع: Gemini تحلیل ساختار. کلاس ۳.

اتم AZ-A030 می‌گوید Al Mouj رسماً عمومی اعلام کرده «Your money is safe in the escrow accounts. All processes are backed by Omani government». منبع: Oman Property Advisor و پست‌های اینستاگرام Al Mouj. کلاس ۲.

اتم AZ-A031 می‌گوید استراتژی بازاریابی Al Mouj «brand-reliance marketing» است — یعنی به‌جای شفاف‌سازی پیش‌دستانه‌ی جزئیات عملیاتی (escrow، تاریخ تحویل، پیمانکار)، روی اعتبار تاریخی MAF و OMRAN تکیه می‌کند. این یک buyer-side insight حیاتی است. منبع: تحلیل Gemini. کلاس ۳ (analytical).

اتم AZ-A016 می‌گوید Al Mouj در ۲۰۲۴ بیش از ۱۶۰ واحد مسکونی و بلوک اداری تحویل داد. منبع: سایت رسمی Al Mouj. کلاس ۲. سطح: platform-level، نه Azura-specific.

اتم AZ-A017 می‌گوید Al Mouj از ۲۰۰۷ آغاز شده، ۷۵٪ master plan (۴,۰۰۰ واحد در ۲.۳ km²) تا ۲۰۲۰ کامل شده. منبع: Arab Urban Platform. کلاس ۳.

اتم AZ-A032 می‌گوید الگوی تاریخی Al Mouj برای زمان launch تا handover ۲۴ تا ۳۶ ماه است. منبع: Gemini تحلیل پروژه‌های Juman One و Marsa Gardens. کلاس ۳.

اتم AZ-A033 می‌گوید بانک مسقط شریک استراتژیک Al Mouj است (رویدادهای مشترک، تسهیلات ویژه)، که بانک نگهدارنده‌ی escrow Azura را به احتمال زیاد همین بانک می‌کند — هرچند تأیید رسمی ندارد. منبع: Gemini تحلیل ارتباط. کلاس ۳ (circumstantial).

### اتم‌های L2 — Azura Beach Residences پروژه

اتم AZ-A001 می‌گوید Azura در West Point precinct از Al Marsa District در Al Mouj روی ۱۹,۵۰۰ مترمربع زمین ساحلی قرار دارد. منبع: Muscat Daily ۶ جولای ۲۰۲۵. کلاس ۳.

اتم AZ-A002 می‌گوید Azura اولین dual-frontage (نمای همزمان اقیانوس و مارینا) در عمان است. منبع: Al Mouj رسمی از طریق MEP Middle East. کلاس ۲/۳.

اتم AZ-A003 می‌گوید فاز ۱ Azura شامل ۳۰۹ واحد است: ۲۸۶ آپارتمان یک تا سه‌خوابه در دو ساختمان + ۲۳ شاله‌ی چهارخوابه پنج‌سرویسه با استخر خصوصی و سه پارکینگ. منبع: Zawya press release ۶ جولای ۲۰۲۵. کلاس ۲.

اتم AZ-A004 می‌گوید فاز ۱ Azura در جولای ۲۰۲۵ sold-out شد. منبع: GCC Business News ۱۴ فوریه ۲۰۲۶. کلاس ۳.

اتم AZ-A034 می‌گوید فاز ۲ Azura شامل ۳۰۷ واحد است (آپارتمان‌های ۱-۳ خوابه در دو برج میان‌ارتفاع + شاله‌های ۴ خوابه). منبع: omanobserver.om فوریه ۲۰۲۶. کلاس ۳.

اتم AZ-A005 می‌گوید فاز ۲ Azura در اکتبر ۲۰۲۵ sold-out شد. منبع: GCC Business News ۱۴ فوریه ۲۰۲۶. کلاس ۳.

اتم AZ-A006 می‌گوید فاز ۳ و ۴ Azura (آخرین فازها) شامل ۵۷۰ آپارتمان + ۴۱ duplex chalet چهارخوابه با استخر و آسانسور خصوصی هستند. منبع: Zawya press release ۱۵ فوریه ۲۰۲۶. کلاس ۲.

اتم AZ-A035 می‌گوید آسانسور خصوصی برای تمام ۴۱ شاله‌ی فاز ۳ و ۴ به‌صورت رسمی در press release Al Mouj تأیید شده. منبع: Zawya, TradingView, Oman Observer, Trade Arabia. کلاس ۲/۳. (resolves C003)

اتم AZ-A007 می‌گوید ساختار پرداخت Azura: ۵٪ هنگام امضا، ۵٪ سه ماه بعد، مابقی milestone-linked. منبع: almouj.com صفحات Phase II و III/IV. کلاس ۲.

اتم AZ-A036 می‌گوید جزئیات دقیق milestoneها (درصد per stage) در منابع عمومی منتشر نشده؛ معمولاً فقط در SPA واقعی و تحت نظارت حساب امانی ذکر می‌شوند. منبع: Grok سواب کلی. کلاس ۳.

اتم AZ-A008 می‌گوید Azura فاز ۳+۴ صریحاً «100% freehold ownership for all nationalities» با residency eligibility برای خریدار و بستگان درجه یک است. منبع: Kanebridge News. کلاس ۳.

اتم AZ-A009 می‌گوید CEO Al Mouj (Nasser Al Sheibani) Azura 3+4 را «final chapter» توصیف کرد. منبع: Zawya فوریه ۲۰۲۶. کلاس ۲.

اتم AZ-A037 می‌گوید مناقصه‌ی پیمانکار اصلی فاز ۱ و ۲ Azura در می ۲۰۲۶ منتشر شد، ولی برنده عمومی نشده. منبع: BNC Network اینستاگرام. کلاس ۳.

اتم AZ-A038 می‌گوید برخی پلتفرم‌های کارگزاری تخمین تحویل Q4 2026 برای آپارتمان‌ها داده‌اند، که Gemini تحلیل کرده «aggressively optimistic» (۱۷-۱۸ ماه برای پروژه‌ی لوکس ساحلی غیرواقعی است). منبع: Jiwak.com و تحلیل Gemini. کلاس ۴/۳.

اتم AZ-A039 می‌گوید برخی لیستینگ‌ها تخمین تحویل ۲۰۲۸ برای شاله‌ها و ۲۰۲۹ برای Azura 4 ارائه داده‌اند. منبع: homelist.om. کلاس ۴.

اتم AZ-A040 می‌گوید عدم اعلام نام پیمانکار اصلی برای پروژه‌ای که sell-out را گزارش می‌کند، در تحلیل ریسک GCC یک «structural warning signal» محسوب می‌شود. منبع: تحلیل Gemini. کلاس ۳ (analytical insight).

### اتم‌های L2.5 — مشخصات نوع واحد (از بروشورهای رسمی PDF)

اتم AZ-A041 می‌گوید آپارتمان یک‌خوابه (انواع A1, A2, A3): مساحت کل ۷۰-۱۰۷ مترمربع، داخلی ۶۳-۹۶، خارجی ۸-۱۴. منبع: AzuraII_digital_English.pdf و Azura_Digital_Eng_AZ4.pdf و amm_Azura_Digital_Eng_AZ3.pdf. کلاس ۲.

اتم AZ-A042 می‌گوید آپارتمان دوخوابه (انواع B5, B6, B8, B10): مساحت کل ۱۳۶-۱۴۵، داخلی ۱۲۴-۱۳۰، خارجی ۱۲-۱۹. منبع: بروشورهای رسمی Al Mouj. کلاس ۲.

اتم AZ-A043 می‌گوید آپارتمان سه‌خوابه (انواع C1, C2, C3): مساحت کل ۱۶۶-۱۶۸، داخلی ۱۴۵-۱۵۰، خارجی ۱۷-۲۹. منبع: بروشورهای رسمی Al Mouj. کلاس ۲.

اتم AZ-A044 می‌گوید شاله چهارخوابه duplex (Type D): مساحت کل built-up ۳۰۵-۳۰۹ مترمربع (۲۷۳-۲۷۷ داخلی + ۳۲ خارجی) + باغ خصوصی ۹۰-۱۰۸ مترمربع با حق استفاده انحصاری. سه طبقه (G+2). منبع: amm_Azura_Digital_Eng_AZ3.pdf جدول مساحت Type D. کلاس ۲. (resolves C004)

اتم AZ-A045 می‌گوید هیچ واحد پنج‌خوابه‌ای در پروژه وجود ندارد. ادعای پنج‌خوابه در داده‌های اولیه اشتباه خواندن «four-bedroom, five-bathroom» بوده. منبع: تأیید Grok و Gemini از بروشورها. کلاس ۲.

اتم AZ-A046 می‌گوید آپارتمان‌های فاز ۲ ساختار G+3 (۴ طبقه)، آپارتمان‌های فاز ۴ G+11 (تا طبقه‌ی ۱۱). Savills فاز ۴ را «13-floor development» توصیف کرده. منبع: AzuraII brochure و AZ4.pdf و Savills listing. کلاس ۲. (resolves C002, با تمایز فاز)

اتم AZ-A047 می‌گوید قیمت شروع آپارتمان‌ها: ۶۹,۰۰۰ تا ۸۸,۰۰۰ OMR بسته به فاز. فاز II از ۸۸,۰۰۰، فاز III/IV از ۶۹,۰۰۰. واحدهای beachfront premium قیمت ۱۵-۲۵٪ بالاتر. منبع: almouj.com و Gemini تطبیق قیمت‌ها. کلاس ۲/۴.

اتم AZ-A048 می‌گوید قیمت شروع شاله ۴ خوابه: حدود ۴۵۰,۰۰۰ تا ۴۷۵,۰۰۰ OMR. منبع: Optimo Property, Dubizzle. کلاس ۴.

اتم AZ-A049 می‌گوید سندرم «تورم متراژ» شایع است: کارگزاران تمام فضاهای باز را با زیربنای مسقف جمع می‌بندند تا price per sqm کاذباً کم به نظر برسد. منبع: Gemini تحلیل. کلاس ۳ (analytical insight).

اتم AZ-A050 می‌گوید تخصیص دقیق پارکینگ به ازای هر نوع واحد در منابع عمومی یافت نشد. منبع: Grok. کلاس: missingness.

### اتم‌های L4 — اپراتورها و خدمات

اتم AZ-A051 می‌گوید Tabreed Oman انحصار سرمایش منطقه‌ای (district cooling) برای کل Al Mouj دارد، با ظرفیت ۶۲,۰۰۰ تن تبرید و یک concession ابدی. مالکان هیچ حق انتخاب تأمین‌کننده‌ی جایگزین ندارند. منبع: tabreedoman.com و Gemini تحلیل. کلاس ۲/۳.

اتم AZ-A052 می‌گوید هزینه‌ی Tabreed جدا از service charge ساختمان است: capacity charge (بر اساس تناژ تخصیصی) + consumption charge. صدور صورت‌حساب جداگانه به مالک. نرخ دقیق Tabreed برای Azura عمومی نیست. منبع: Tabreed concession docs، Gemini. کلاس ۲/۳.

اتم AZ-A053 می‌گوید service charge آپارتمان‌های beachfront Azura: محدوده ۸-۱۵ OMR per sqm سالانه (پایان‌ بالاتر به‌خاطر استخر بی‌نهایت، جیم، دسترسی ساحلی مستقیم). منبع: تحلیل کارگزاران و tamlikoman.com. کلاس ۴.

اتم AZ-A054 می‌گوید service charge شاله‌ها: محدوده ۴-۷ OMR per sqm سالانه (پایین‌تر به‌خاطر اشتراک کمتر و تمرکز نگهداری خصوصی). منبع: تحلیل کارگزاران. کلاس ۴.

اتم AZ-A055 می‌گوید sinking fund برای تعمیرات اساسی: مشاوران سرمایه‌گذاری توصیه می‌کنند سالانه ۱٪ ارزش ملک برای maintenance reserve کنار گذاشته شود. وجود رسمی sinking fund برای Azura در منابع عمومی تأیید نشده. منبع: Gemini. کلاس ۳.

---

## بخش دوم — تناقض‌های ثبت‌شده و وضعیت حل آن‌ها

تناقض C001 درباره‌ی قیمت شروع (78K در برابر 85K) به‌صورت توضیح‌داده‌شده حل شده: تفاوت فازهاست. فاز II از 88K، فاز III/IV از 69K، اعداد میانی از کارگزاران مختلف.

تناقض C002 درباره‌ی ارتفاع ساختمان به‌صورت تمایز فازی حل شده: فاز II = G+3 (۴ طبقه)، فاز IV = G+11 (تا طبقه‌ی ۱۱، Savills می‌گوید ۱۳-floor)، شاله‌ها = G+2 (۳ طبقه). هیچ کدام «۱۰ طبقه‌ی Grok» نیست — این یک خطای متادیتای پلتفرم‌های آگهی بوده.

تناقض C003 درباره‌ی آسانسور خصوصی حل شده: تأیید رسمی press release برای ۴۱ شاله‌ی فاز ۳+۴.

تناقض C004 درباره‌ی متراژ شاله حل شده: ۳۰۵ مترمربع built-up (per official brochure) + ۹۰-۱۰۸ مترمربع باغ. عدد ۴۵۵+ ترفند تجمیعی «gross area» کارگزاران بود.

---

## بخش سوم — Missingness باقی‌مانده (با context کامل)

دو missingness بحرانی اولیه حالا context قوی دارند، یعنی gap‌ها از «unknown» به «known unknown با توضیح» تبدیل شده‌اند.

**M-FINAL-001 درباره‌ی تاریخ تحویل**: هنوز هیچ developer commitment رسمی منتشر نشده. ولی حالا چندین لایه context داریم: مناقصه‌ی پیمانکار اصلی در می ۲۰۲۶ منتشر شده (هنوز برنده نشده)، الگوی تاریخی Al Mouj ۲۴-۳۶ ماهه است، کارگزاران تخمین Q4 2026 برای آپارتمان‌ها و ۲۰۲۸ برای شاله‌ها داده‌اند، Gemini تخمین Q4 2026 را «aggressively optimistic» می‌داند و معتقد است شاله‌های پیچیده به ۲۰۲۷+ کشیده می‌شوند. عدم اعلام پیمانکار با وجود sell-out به‌عنوان structural warning signal ثبت شده. Question-Back برای خریدار باقی است.

**M-FINAL-002 درباره‌ی escrow اختصاصی Azura**: هنوز نام بانک و شماره‌ی حساب عمومی نشده. ولی حالا framework کاملاً مستند است (RD 30/2018 + RD 79/2025)، MoHUP صفحه‌ی رسمی escrow دارد، Al Mouj عمومی گفته «escrow accounts» (جمع، یعنی per project) موجود است، بانک مسقط شریک استراتژیک Al Mouj و پیشگام escrow services است (probable بانک نگهدارنده)، و دلیل عدم انتشار = فرهنگ شرکتی محافظه‌کار عمان + Azura در دوره‌ی گذار RD 79/2025 لانچ شده. Question-Back برای خریدار: شماره‌ی حساب در زمان امضای SPA باید با مجوز MoHUP تطابق داشته باشد.

**M-FINAL-003 تخصیص پارکینگ per unit type**: کم اهمیت ولی ثبت شده.

**M-FINAL-004 جزئیات milestone درصدی پرداخت**: کم اهمیت، فقط در SPA قابل‌دسترس.

**M-FINAL-005 درصد دقیق penalty تأخیر در SPA Al Mouj**: متوسط اهمیت. ولی Article 267 آن را تا حد زیادی بی‌اثر می‌کند چون قاضی می‌تواند تعدیل کند — پس حتی اگر بنویسد ۱۰٪، تضمین نیست.

---

## بخش چهارم — گراف به‌روز‌شده (G3)

موجودیت‌ها (entities) مجموعاً ۲۲ تا، در ۷ entity_type:

**Type country**: یک موجودیت — Oman (Sultanate of Oman).
**Type holding**: سه — MAF Holding LLC، Oman Investment Authority، Tanmia Oman SAOC.
**Type developer**: سه — MAF Properties LLC، OMRAN Group SAOC، Tanmia.
**Type jv**: یک کلیدی — Al Mouj Muscat S.A.O.C.
**Type master_development**: یک — Al Mouj Muscat Community.
**Type project**: یک — Azura Beach Residences.
**Type product_phase**: چهار — Azura Phase 1، Phase 2، Phase 3، Phase 4.
**Type unit_type**: پنج — Apartment 1BR، Apartment 2BR، Apartment 3BR، Chalet 4BR Type D، (Penthouse 4BR — هنوز در بروشورها به‌صورت جدا تأیید نشده، فعلاً candidate).
**Type operator**: سه — Tabreed Oman، Bank Muscat (probable escrow holder)، Wateera-equivalent (post-handover management، هنوز نام تأیید نشده).

روابط (edges) مجموعاً ۲۸ تا، در ۸ edge_type:

روابط owns (مالکیت parent → subsidiary): MAF Holding owns MAF Properties، OIA owns OMRAN، Tanmia Holding owns Tanmia operating.

روابط joint_venture_with (افقی، تولید پروژه): MAF Properties ↔ OMRAN (via Al Mouj S.A.O.C.، ۵۰٪ MAF)، MAF Properties ↔ Tanmia، OMRAN ↔ Tanmia. سه edge افقی که با هم Al Mouj Muscat S.A.O.C. را می‌سازند.

روابط develops: Al Mouj S.A.O.C. develops Al Mouj Muscat Community.

روابط contains: Al Mouj Community contains Azura، Azura contains Phase 1-4، هر Phase contains مجموعه‌ای از unit_typeها.

رابطه‌ی buyer-critical: Al Mouj Muscat S.A.O.C. contractual_party_for_buyer Azura (تمام فازها). این مهم‌ترین edge کل گراف است.

روابط operates: Tabreed Oman operates Al Mouj Community (perpetual concession).

روابط finances: Bank Muscat probably_holds_escrow Al Mouj S.A.O.C. (circumstantial، نه تأییدشده).

روابط regulates: Oman (L0) regulates Al Mouj S.A.O.C. (ITC framework + RD 79/2025).

---

## بخش پنجم — ممیزی ضدسوگیری دوازده‌گانه (G4)

این ممیزی، هر یک از دوازده قاعده‌ی قفل‌شده‌ی L2 pilot را صریحاً علیه پرونده‌ی فعلی Azura چک می‌کند.

قاعده‌ی **Product-Specific Reading**: آیا ارزیابی در سطح پروژه/فاز انجام شد نه master؟ بله — تمام اتم‌های اسکورمحور یا project-specific هستند یا framework-level به‌صراحت برچسب‌گذاری شده‌اند. pass.

قاعده‌ی **Hard Gate Isolation**: آیا گیت‌های سخت بیرون از اسکور باقی ماندند؟ بله — گیت‌های سخت (مجوز، title، escrow، transfer) در Section A (Gate Board) قرار دارند و در Score Core نیامده‌اند. pass.

قاعده‌ی **Developer Context Modifier**: آیا نمره‌ی Al Mouj به‌صورت خام به Azura منتقل نشد؟ بله — اتم‌های AZ-A016 و AZ-A017 صریحاً platform-level برچسب خورده‌اند. سابقه‌ی Al Mouj فقط روی سه خوشه (ریسک تأخیر، اعتماد به تحویل، اعتماد به after-sales) اثر مجاز دارد. pass.

قاعده‌ی **Framework vs Project-Specific Split**: آیا escrow framework با escrow project قاطی نشد؟ بله — اتم AZ-A012 framework، اتم AZ-A030 platform-level public statement، missingness M-FINAL-002 project-specific. سه لایه‌ی جدا. pass.

قاعده‌ی **Banking Support ≠ Buyer Protection**: آیا financing بانکی با حفاظت خریدار قاطی نشد؟ بله — اتم AZ-A033 (بانک مسقط شریک) صریحاً circumstantial برچسب خورده، با missingness AZ M-FINAL-002 (escrow project) جدا. pass.

قاعده‌ی **Payment-Plan Integrity**: آیا payment plan فقط برای همان فاز امتیاز گرفت؟ بله — اتم AZ-A007 برای Phase II و III/IV هم‌زمان از official site تأیید شده، ولی milestone درصدها (AZ-A036) به‌عنوان missingness باقی است. pass.

قاعده‌ی **Disclosure Discipline**: آیا افشا به‌عنوان امتیاز خوانده شد نه نقص؟ بله — اتم AZ-A031 (brand-reliance marketing) و AZ-A040 (عدم اعلام پیمانکار = structural warning) صریحاً به‌عنوان نقص افشا ثبت شده‌اند، نه به‌عنوان «حرفه‌ای بودن». pass.

قاعده‌ی **Descriptive Board**: آیا جذابیت‌های شخصی (dual-frontage، استخر خصوصی، آسانسور) بیرون از اسکور ماندند؟ بله — این‌ها در Section D (Descriptive Board) جای می‌گیرند نه در Score Core. pass.

قاعده‌ی **Incentive Containment**: آیا مشوق‌ها (مثل «1 year payment holiday» در promotion) طبقه‌بندی شدند؟ بله — این یک marketing offer است نه buyer protection و در Section D ثبت می‌شود. pass.

قاعده‌ی **Residency Claim Discipline**: آیا ادعای اقامتی در سه لایه خوانده شد؟ بله — اتم AZ-A008 (Azura-specific eligibility claim)، اتم AZ-A014 (Golden Residency framework از L0)، و قاعده‌ی buyer-side که residency eligibility ≠ guaranteed residency. سه لایه‌ی جدا. pass.

قاعده‌ی **Market Absorption ≠ Liquidity**: آیا sold-out به‌عنوان «نقدشوندگی» تفسیر نشد؟ بله — اتم‌های AZ-A004 و AZ-A005 (sold-out Phases 1 و 2) صریحاً به‌عنوان «سیگنال تقاضای اولیه» نه «نقدشوندگی resale» ثبت شده‌اند. هیچ resale data وجود ندارد چون هنوز تحویل نشده. pass.

قاعده‌ی **Separate Project Files**: آیا Azura فایل مستقل خودش را دارد؟ بله — این فایل دقیقاً همان است. pass.

**نتیجه‌ی ممیزی: ۱۲ از ۱۲ pass. صفر نقض قاعده.**

---

## بخش ششم — Criteria Applicability برای Off-Plan

با ۵۵ اتم و گراف کامل، حالا می‌توان جدول applicability را برای وضعیت off-plan قطعی کرد:

برای پروژه‌ی Off-Plan، معیارهای فعال (scoreable) عبارت‌اند از: Payment Plan Integrity (وزن ۲۰٪)، Location Quality (۲۵٪)، Market Absorption Signal (۱۵٪)، Delay Sensitivity (۲۰٪)، Disclosure Discipline (۲۰٪).

معیارهایی که برای Off-Plan غیرفعال‌اند: Post-Handover Build Quality (نمی‌توان قبل از تحویل سنجید)، Service Charge Reality (تخمین وجود دارد ولی reality فقط بعد از یک سال سکونت)، Resale Liquidity (بعد از تحویل و بازار ثانویه قابل‌ارزیابی)، Maintenance Track Record (بعد از تحویل).

این داده در جدول criteria_applicability ذخیره می‌شود تا کد ندارد، فقط داده.

---

## بخش هفتم — حکم نهایی پرونده (به‌روزشده)

با تمام اتم‌ها، گراف، و audit، حکم Azura همچنان **«حساس به توقف — Enhanced Diligence Required»** است، ولی الان دلایلش روشن‌تر و عمیق‌تر است.

سه گیت سخت همچنان باز یا partial هستند: مجوز مستقیم (هیچ developer license تأیید عمومی)، escrow اختصاصی (framework قوی + signal بانک مسقط، ولی شماره‌ی حساب public نیست)، روند title transfer (RD 79/2025 الزام Preliminary Real Estate Register را قرار داده ولی اجرای آن برای Azura در دوره‌ی گذار است).

اضافه‌ی قابل‌توجه از G2: ماده‌ی ۲۶۷ قانون مدنی عمان به‌عنوان context حقوقی، جریمه‌های SPA را تا حد زیادی غیرقابل‌تضمین می‌کند — یعنی حتی اگر SPA penalty داشته باشد، خریدار باید خسارت واقعی را اثبات کند تا قاضی به جریمه‌ی توافقی استناد کند. این یک buyer-side insight بسیار مهم برای آموزش بازار فارسی‌زبان است.

Question-Backهای نهایی برای خریدار: (یک) شماره‌ی حساب escrow اختصاصی Azura و نام بانک متولی هنگام امضای SPA. (دو) تاریخ تخمینی تحویل فاز مورد نظر + contractual penalty + شناخت اینکه penalty طبق ماده ۲۶۷ توسط قاضی قابل‌تعدیل است. (سه) نمونه‌ی SPA و شرایط لغو با تأکید بر ماده ۲۴۶ (حق فسخ برای تأخیر طولانی غیرموجه). (چهار) نام پیمانکار اصلی فاز مورد نظر و وضعیت ثبت در Preliminary Real Estate Register. (پنج) تخمین service charge + هزینه‌ی Tabreed جداگانه + توضیح perpetual concession.

---

## آمار خلاصه نهایی

اتم‌های فعال: ۵۵ (از ۱۷ اولیه). موجودیت‌ها: ۲۲. روابط: ۲۸. تناقض‌ها: ۴ (۳ resolved + ۱ explained). شکاف‌ها: ۵ (۲ بحرانی با context، ۳ متوسط). ممیزی ضدسوگیری: ۱۲/۱۲ pass. حکم: حساس به توقف (تأیید‌شده).
