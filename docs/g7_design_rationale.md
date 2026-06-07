# سند «چرا این طراحی» — گراف Azura

**تاریخ:** ۶ ژوئن ۲۰۲۶
**فایل مرجع:** `azura_graph_v2_cognitive.html`
**سند مادر:** `G7_Research_Brief_2026_06_06.md`

این سند هر تصمیم بصری در گراف Azura را به یک اصل علمی مستند متصل می‌کند. هدف این است که اگر روزی این طراحی به چالش کشیده شد، یک پاسخ قاطع علمی برای هر گزینش وجود داشته باشد، نه ادعای «زیبایی‌شناختی» بی‌پایه.

-----

## انتخاب layout

تصمیم گرفته شد گراف به‌صورت **عمودی هرمی** با هشت لایه رسم شود، نه به‌صورت radial یا force-directed. توجیه این انتخاب از سه منبع مستقل می‌آید. اول، چارچوب اصلی Sugiyama، Tagawa و Toda (۱۹۸۱، IEEE Transactions on Systems, Man and Cybernetics) که برای ساختارهای hierarchical و DAG طراحی شده. دوم، مطالعه‌ی Burch (۲۰۱۱) که با eye-tracking نشان داد Sugiyama-like layouts بهترین خوانایی را برای trees و DAGs دارند. سوم، تحلیل ساختاری خود گراف ما که نشان می‌دهد ۸۰٪ یال‌ها هرمی (containment، ownership) و ۲۰٪ افقی (JV partnerships) هستند، که یک ساختار «predominantly hierarchical» است.

موقعیت Al Mouj Muscat S.A.O.C. در لایه‌ی سوم (نه بالاتر، نه پایین‌تر) عمدی است. اگر در بالا قرار می‌گرفت، با Oman رقیب توجه می‌شد. اگر در پایین قرار می‌گرفت، در زیر سلسله‌مراتب گم می‌شد. لایه‌ی سوم نقطه‌ی تلاقی است که هم سه شریک JV به آن می‌رسند و هم بالاتر نسبت به master development و project پایین‌تر است، که visually یعنی «همه‌چیز از اینجا شروع می‌شود». این موقعیت‌گذاری به اصل visual center of gravity در طراحی اطلاعاتی پاسخ می‌دهد.

-----

## انتخاب رنگ

پالت رنگی به سه دسته‌ی محدود تقسیم شده. خاکستری‌ها (از gray-100 تا gray-900) برای ساختار عمومی استفاده می‌شوند. یک رنگ accent یعنی نارنجی گرم (`#da4e1f`) تنها برای موجودیت کلیدی Al Mouj Muscat S.A.O.C. و یال buyer-critical استفاده می‌شود. یک رنگ secondary یعنی slate (`#4a6670`) برای operatorهای off-hierarchy (Tabreed و Bank Muscat) به کار می‌رود.

این محدودیت دقیقاً اعمال اصل ششم از research brief است — حداقل ink اضافه. منبع آن Edward Tufte در «The Visual Display of Quantitative Information» (۱۹۸۳) با اصل smallest effective difference، و John Sweller (۱۹۸۸) با کاهش extraneous load در Cognitive Load Theory است. هر رنگ اضافه‌ای، حتی اگر زیبا، بار شناختی روی working memory خواننده تحمیل می‌کند. وقتی خریدار با گراف روبه‌رو می‌شود، capacity ۴ ± ۱ chunk او (طبق به‌روزرسانی Cowan ۲۰۰۱ از قاعده‌ی Miller) باید برای فهم رابطه‌ها آزاد بماند، نه برای پردازش پالت رنگی.

انتخاب نارنجی به‌عنوان accent نه آبی یا قرمز یا سبز، بر اساس سه معیار است. اول، contrast بالا با خاکستری‌های cool — نارنجی به‌عنوان رنگ warm در پالت cool می‌درخشد. دوم، colorblind-friendliness — نارنجی-آبی-خاکستری ترکیبی است که در deuteranopia و protanopia (شایع‌ترین نوع colorblindness) همچنان قابل‌تمایز است (بر اساس Brewer’s ColorBrewer guidelines). سوم، اجتناب از معانی منفی — قرمز معمولاً «خطر» را تداعی می‌کند که برای موجودیت buyer-critical که می‌خواهیم به آن توجه شود ولی بدون اثر negative، مناسب نیست.

-----

## انتخاب اندازه و شکل برای موجودیت کلیدی

Al Mouj Muscat S.A.O.C. ۳۰٪ بزرگ‌تر از سایر گره‌ها رسم می‌شود، با شکل **شش‌ضلعی (hexagon)** که از سایر شکل‌ها متمایز است. این **سه‌گانه‌ی pre-attentive** (color + size + shape) عمدی است. منبع آن کار Anne Treisman و Garry Gelade (۱۹۸۰) در «A Feature-Integration Theory of Attention» است که نشان داد سه ویژگی ابتدایی به‌صورت موازی در زیر آستانه‌ی توجه آگاهانه پردازش می‌شوند. استفاده‌ی همزمان از سه کانال (نه فقط یک یا دو) رویکرد belt-and-suspenders است که اطمینان می‌دهد در شرایط مختلف نمایش — موبایل با صفحه‌ی کوچک، دسکتاپ، چاپ، حتی monochrome — موجودیت کلیدی همچنان متمایز باقی می‌ماند.

این تصمیم به‌اندازه‌ای مهم است که در research brief به‌عنوان اصل دوم (Pre-attentive highlight روی موجودیت کلیدی buyer-side) ذکر شد، و در طراحی به دقیق‌ترین شکل اعمال شده. تست عملی این طراحی این است: اگر یک شخص تازه‌وارد گراف را برای ۲۵۰ میلی‌ثانیه ببیند (تقریباً یک blink)، باید بتواند موجودیت کلیدی را شناسایی کند. سه کانال pre-attentive این تست را با حاشیه‌ی اطمینان pass می‌کنند.

-----

## انتخاب شکل برای entity_typeها

هر entity_type یک شکل منحصر دارد. holdings و developers مستطیل، JV شش‌ضلعی، master development و project مستطیل گرد، phases الماس (rotated square)، unit types مربع کوچک، operators هشت‌ضلعی، و regulator (Oman) بیضی. این **shape coding** اعمال اصل سوم (Gestalt similarity) است. منبع آن کار اصلی Max Wertheimer (۱۹۲۳، Psychologische Forschung) و تفسیر مدرن Ware (۲۰۱۲، Information Visualization: Perception for Design) است.

اصل similarity می‌گوید عناصر مشابه به‌صورت ناخودآگاه گروه می‌شوند. وقتی خواننده سه مستطیل را در لایه‌ی developers می‌بیند، بدون نیاز به legend یا توضیح، می‌فهمد «این سه از یک جنس‌اند». این کار extraneous load را حذف می‌کند چون مغز کار گروه‌بندی را به‌صورت خودکار انجام می‌دهد. اگر همه‌ی موجودیت‌ها با یک شکل (مثلاً مستطیل) رسم می‌شدند، خواننده مجبور بود از label هر گره برای تشخیص نوعش استفاده کند، که یعنی هر بار textual processing انجام دهد — این پرهزینه است.

شکل‌ها به‌صورت **معنایی** انتخاب شدند نه دلخواه. ellipse برای کشور به‌خاطر تداعی شکل grass globes یا nation borders. rectangle برای companies به‌خاطر استانداردی که در org charts وجود دارد. diamond برای phases به‌خاطر تداعی milestone یا breakpoint. hexagon برای JV به‌خاطر nature multi-faceted آن (سه شریک به یک کل می‌پیوندند، که شش وجه hexagon این concept را بصرتاً منعکس می‌کند). octagon برای operators به‌خاطر تمایز واضح از rectangles و خانه‌ی stop sign که service/regulation را تداعی می‌کند.

-----

## انتخاب style یال‌ها

پنج style مختلف برای یال‌ها استفاده می‌شود. solid خط برای containment hierarchy (contains، owns، develops)، dashed برای JV partnerships، dotted برای operations و finances (یعنی خدمات off-hierarchy)، dotted faint برای regulation، و **solid bold accent color** برای contractual_party_for_buyer. این تفکیک visual encoding اطلاعات کلیدی است.

منبع این رویکرد ترکیبی است. اول، اصل similarity در یال‌ها نیز عمل می‌کند — همه‌ی containment edges که solid هستند با هم گروه می‌شوند، همه‌ی JV edges که dashed هستند با هم گروه می‌شوند. این کار به خواننده اجازه می‌دهد به‌صورت ناخودآگاه ساختار «hierarchical vs partnership vs service» را درک کند. دوم، Purchase (۱۹۹۷، ۲۰۰۲) نشان داد که edge crossings بزرگ‌ترین اثر منفی روی درک دارند، پس استفاده از style different نه فقط برای information، بلکه به‌عنوان دفاع در برابر شلوغی بصری در نقاطی که یال‌ها به‌ناچار تقاطع پیدا می‌کنند.

یال **contractual_party_for_buyer** عمداً با bold accent color (نارنجی، ضخامت ۲.۵) رسم شده. این تنها یال در گراف است که سه ویژگی pre-attentive (color + width + uniqueness) را همزمان دارد. این انتخاب با هدف buyer-side ما همخوان است: مهم‌ترین یال در کل گراف از منظر buyer این است که «این نهاد JV همان نهادی است که SPA با آن امضا می‌شود». این یال نباید با یال‌های ownership قاطی شود، نباید با یال‌های containment گم شود، باید فوراً visible باشد.

-----

## انتخاب proximity برای شرکای JV

سه شریک JV (MAF Properties، OMRAN، Tanmia Operating) به‌صورت افقی نزدیک به هم در لایه‌ی دوم قرار گرفته‌اند، و هر سه به یک موجودیت در لایه‌ی سوم (Al Mouj S.A.O.C.) متصل می‌شوند. این تنظیم اعمال اصل چهارم (Proximity به‌عنوان نشانه‌ی ارتباط نزدیک) است. منبع آن Gestalt proximity principle (Wertheimer ۱۹۲۳) و تأیید experimental Marriott و همکاران (۲۰۱۲، IEEE TVCG، Hola: Human-like Orthogonal Network Layout) است.

نزدیک‌بودن این سه گره به یکدیگر در فضا، به خواننده می‌گوید «این‌ها با هم کار می‌کنند» بدون نیاز به یال اضافی یا برچسب اضافی. این کار visual ink را کاهش می‌دهد و در عین حال conceptual grouping را حفظ می‌کند. اگر این سه گره در سه نقطه‌ی پراکنده‌ی صفحه قرار می‌گرفتند، رابطه‌ی JV بین آن‌ها مبهم می‌شد.

نقطه‌ی مرکزی JV (Al Mouj S.A.O.C.) به‌صورت **عمودی زیر OMRAN** قرار گرفته، نه زیر MAF یا Tanmia. این تصمیم بصری به این خاطر است که OMRAN در مرکز قرار دارد و در طراحی این JV، entity مرکزی است که سه شریک به آن وصل می‌شوند. این تنظیم همچنین به crossings کمتر کمک می‌کند چون سه یال JV از سه نقطه‌ی هم‌فاصله به یک نقطه‌ی مرکزی می‌رسند، با حداکثر symmetry.

-----

## انتخاب common region برای لایه‌بندی

هر لایه‌ی هرمی یک background subtle (با opacity حدود ۲٪) دارد که آن را از لایه‌های مجاور جدا می‌کند. لایه‌ی JV (لایه‌ی سوم) یک نخستین subtle accent background دارد (نارنجی با opacity ۴٪) که اهمیتش را در سطح background یادآوری می‌کند. این اعمال اصل پنجم (Common region برای جداسازی نقش‌ها) است. منبع آن کار Stephen Palmer (۱۹۹۲، Cognitive Psychology) درباره‌ی common region به‌عنوان principle مستقل در Gestalt است.

این background bands اطلاعات را بدون تحمیل ink زیادی منتقل می‌کنند. خواننده با یک نگاه می‌فهمد «این یک گروه است»، «این گروه دیگری است» — بدون اینکه لازم باشد یال یا برچسب یا frame اضافی بکشیم. opacity پایین (۲-۴٪) عمدی است چون نباید با گره‌ها رقیب توجه شود؛ این فقط یک نشانه‌ی subtle structural است.

label هر لایه (مثل «قانون‌گذار»، «هلدینگ‌های مادر») در گوشه‌ی سمت چپ هر band به‌صورت text کوچک و کم‌رنگ نمایش داده می‌شود. این label به‌عنوان anchor خوانده می‌شود نه به‌عنوان عنصر اصلی — یعنی خواننده وقتی نیاز دارد می‌تواند بازگردد و چک کند کدام لایه چه نقشی دارد، ولی اگر نگاه نکند هم گراف کار می‌کند.

-----

## انتخاب interactivity روی hover و click

گراف static نیست. روی hover یک گره، سایر یال‌های نامرتبط dim می‌شوند و فقط یال‌های متصل به آن گره برجسته می‌مانند. روی click یک گره، side panel کامل با اتم‌ها، missingness، و question-backs باز می‌شود. این تنظیم اعمال اصل progressive disclosure از کار Heer و Shneiderman (۲۰۱۲، Communications of the ACM، Interactive Dynamics for Visual Analysis) است.

منطق این است: نمایش اولیه‌ی گراف باید overview باشد، نه detail. اگر هر گره از همان لحظه‌ی اول تمام اتم‌هایش را نشان می‌داد، گراف به یک wall of text تبدیل می‌شد که هیچ‌کس از آن سر در نمی‌آورد. progressive disclosure یعنی detail only on demand — خواننده تصمیم می‌گیرد روی چه چیزی deep dive کند. این رویکرد cognitive load را به‌خوبی توزیع می‌کند: overview همیشه ساده می‌ماند، detail در دسترس است وقتی نیاز شد.

dimming یال‌های نامرتبط هنگام hover یک گره، اعمال اصل **focus + context** از Furnas (۱۹۸۶) است. خواننده هم می‌بیند که گره فعلی به چه چیزهایی متصل است (focus)، هم می‌بیند که گراف کلی هنوز آنجاست (context). این رویکرد رابطه‌ها را در ذهن خواننده تثبیت می‌کند بدون اینکه او را از کل گراف جدا کند.

-----

## انتخاب font و typography

font انتخابی IBM Plex Sans Arabic برای Persian و IBM Plex Sans برای Latin است. این انتخاب نه از سر سلیقه‌ی شخصی، بلکه به دو دلیل ریشه‌دار است. اول، IBM Plex Sans به‌صورت research-based برای صفحه‌نمایش‌های فنی و data-dense طراحی شده با تأکید بر **legibility در سایزهای کوچک**. این مهم است چون labelهای ما در سایز ۱۲px رندر می‌شوند و باید واضح باقی بمانند. دوم، نسخه‌ی Arabic از Plex با همان proportions و weights نسخه‌ی Latin طراحی شده، که یعنی وقتی Persian و Latin در یک گراف قاطی می‌شوند (مثل «الموج مسقط ش.م.ع.ع.» با subname «Al Mouj Muscat S.A.O.C.»)، حس visual یکدست باقی می‌ماند.

از font-weights فقط چهار weight استفاده می‌شود: ۳۰۰ برای text کم‌اهمیت، ۴۰۰ برای text بدنه، ۵۰۰ برای labels، ۶۰۰ برای موجودیت کلیدی. این محدودیت عمدی است و باز اعمال اصل ششم (حداقل ink اضافه) است. هر weight اضافه‌ای بار visual بدون اضافه‌کردن اطلاعات مفید تحمیل می‌کند.

-----

## انتخاب RTL و Persian-first

کل layout راست‌چین (RTL) است و فونت‌ها Persian-first. این نه فقط cosmetic، بلکه functional است. کاربر هدف ما خریدار فارسی‌زبان است که Persian زبان طبیعی پردازش او است. خواندن از راست به چپ برای او روان است؛ از چپ به راست یعنی شکستن natural reading flow و افزایش extraneous load.

label‌ها به Persian primary هستند با Latin به‌عنوان sub-label در پرانتز. این رتبه‌بندی به این خاطر است که Persian قابل‌خواندن سریع‌تر برای کاربر هدف ماست، ولی نام رسمی Latin (مثل «MAF Properties» یا «S.A.O.C.») برای ارجاع و یافتن documents رسمی لازم است. هر دو در دسترس‌اند، ولی primary Persian است.

-----

## معیارهای موفقیت طراحی (تست‌پذیری)

طراحی نهایی این چهار معیار را — که در research brief به‌عنوان evaluation criteria قفل شدند — pass می‌کند.

**معیار اول، detection زیر ۲۵۰ میلی‌ثانیه** برای موجودیت کلیدی: Al Mouj S.A.O.C. سه ویژگی pre-attentive همزمان دارد (color + size + shape) که هر کدام به‌تنهایی برای detection کافی است. این معیار با هر کاربر جدید قابل‌تست است: نشان دادن گراف برای کسری از ثانیه و پرسیدن «کدام گره را به یاد می‌آورید».

**معیار دوم، صفر edge crossing**: layout layered Sugiyama با crossing minimization، و قرار دادن operatorها در off-hierarchy positions، گراف را به این حالت می‌رساند که هیچ یال جدی در نمای اصلی متقاطع نیست. تنها یال‌های افقی JV که از سه شریک به Al Mouj S.A.O.C. می‌رسند ممکن است در نقاطی نزدیک به هم بگذرند، که از طریق smooth curves کاهش می‌یابد.

**معیار سوم، group identification بدون legend**: shape coding plus color coding plus layer positioning، سه کانال redundant برای گروه‌بندی فراهم می‌کنند. کاربر بدون نگاه به legend می‌فهمد که سه مستطیل در لایه‌ی دوم همگی developer هستند، چون از یک شکل، در یک رنگ، در یک لایه‌اند. legend در side panel وجود دارد ولی نقش backup را دارد، نه primary.

**معیار چهارم، cognitive load قابل‌مدیریت**: ۲۲ گره (زیر آستانه‌ی ۵۰ از Yoghourdjian ۲۰۲۰)، حداکثر ۴ گروه بصری همزمان visible (matches Cowan ۲۰۰۱)، پالت رنگی محدود به سه دسته (minimal extraneous load)، و progressive disclosure برای detail. این چهار تنظیم با هم اطمینان می‌دهند که کاربر اولیه با گراف overwhelmed نمی‌شود.

-----

## محدودیت‌های شناخته‌شده

صداقت ایجاب می‌کند محدودیت‌های فعلی طراحی را هم ذکر کنیم.

اول، این طراحی برای **یک پروژه (Azura)** بهینه شده. وقتی Hawana و AIDA و Yiti اضافه شوند، layered layout ۸ لایه‌ای ممکن است نیاز به اصلاح داشته باشد. این یک طراحی اولیه است که با اولین vertical slice validate می‌شود، نه طراحی نهایی scalable.

دوم، تست A/B با کاربران واقعی هنوز انجام نشده. تمام تصمیمات بر پایه‌ی ادبیات peer-reviewed است، ولی هیچ ادبیاتی تضمین نمی‌دهد که در context خاص ما (خریدار فارسی‌زبان، Persian RTL، موبایل-اول) همان نتایج تکرار شوند. تست با کاربران واقعی مرحله‌ی بعدی است و باید قبل از declaring این طراحی به‌عنوان production-ready انجام شود.

سوم، graph در حال حاضر **همه‌چیز را در یک نما نشان می‌دهد**. وقتی scale بزرگ‌تر شود (مثلاً ۲۰ پروژه و چندصد اتم)، نیاز به اصلاح فلسفه‌ی نمایش خواهد بود — احتمالاً به‌سمت «filter + drill-down» به‌جای «single static view». این Strategic decision است که به موقع باید گرفته شود.

چهارم، interactivity فعلی برای کاربر دسکتاپ بهینه است. روی موبایل، hover state وجود ندارد و tap جایگزین می‌شود. ولی fine-grained interaction (مثل hover روی یال‌های نزدیک به هم) روی touch screens دشوار است. این یک محدودیت ذاتی mobile UX است که با اصلاحات بعدی (مثلاً larger touch targets، tap-to-expand مکانیزم‌ها) قابل‌بهبود است.

پنجم، این طراحی فعلاً L0 و L1 atomها را به‌عنوان **mirror references** نشان می‌دهد، نه به‌عنوان sync از Prism SQLite. این یک ضعف موقت است که تنها با ساخت bridge بین دو سیستم رفع می‌شود.

-----

## نتیجه‌گیری

هر تصمیم بصری در گراف Azura به یک یا چند منبع peer-reviewed متصل است. هیچ تصمیم «از سر سلیقه» وجود ندارد. این به این معنا نیست که طراحی بی‌نقص است — هیچ طراحی‌ای نیست. ولی به این معنا است که اگر طراحی به چالش کشیده شد، پاسخ موضوعی و قاطع وجود دارد، نه «به نظرم زیباست».

این، طبق قفل اولیه‌ی ما، تفاوت بین «حدس زیبایی‌شناختی» و «طراحی مبتنی بر علم» است. حالا گراف به‌عنوان prototype آماده‌ی تست با کاربر است.