# G7 Research Brief — مبنای علوم شناختی بصری برای طراحی گراف Azura

**تاریخ:** ۶ ژوئن ۲۰۲۶
**هدف:** پایه‌گذاری اصول طراحی گراف buyer-side روی ادبیات peer-reviewed علوم شناختی بصری، تا قبل از طراحی، هر تصمیم بصری به یک یافته‌ی علمی مستند متصل باشد و نه بر اساس حدس زیبایی‌شناختی.

-----

## بخش اول — منابع علمی پایه

ادبیات visualization research در پنجاه سال اخیر سه ستون نظری اصلی را معرفی کرده که این طراحی بر آن‌ها استوار است.

ستون اول، **نظریه‌ی Cognitive Load** اصالتاً توسط John Sweller در ۱۹۸۸ معرفی شد و توسط Chandler و Sweller (۱۹۹۱) توسعه یافت. این نظریه می‌گوید که working memory انسان ظرفیتی محدود دارد — Miller در ۱۹۵۶ آن را ۷ ± ۲ گروه برآورد کرد، ولی Cowan در مقاله‌ی به‌روزرسانی‌اش در سال ۲۰۰۱ در Behavioral and Brain Sciences نشان داد که عدد واقعی نزدیک به ۴ ± ۱ گروه است. cognitive load به سه نوع تقسیم می‌شود: intrinsic load که از ذات پیچیدگی موضوع می‌آید و قابل‌کاهش نیست، extraneous load که از طراحی ضعیف ارائه ناشی می‌شود و باید به حداقل برسد، و germane load که تلاش سازنده‌ی ذهن برای ساختن schemaهای جدید است و باید حداکثر شود. کاربرد این برای visualization اولاً توسط Huang و همکاران (۲۰۱۶) در «Structure Based Aesthetics and Support of Cognitive Tasks for Graph Evaluation» و سپس توسط Yoghourdjian و همکاران (۲۰۲۰) با اندازه‌گیری EEG و heart rate variability بسط داده شد.

ستون دوم، **نظریه‌ی Pre-attentive Processing** که از کار Anne Treisman و Garry Gelade در ۱۹۸۰ آغاز شد. این نظریه می‌گوید که سیستم بصری انسان مجموعه‌ای از ویژگی‌های ابتدایی را به‌صورت موازی، در زیر آستانه‌ی توجه آگاهانه، و در زمانی کمتر از ۲۵۰ میلی‌ثانیه تشخیص می‌دهد. این ویژگی‌ها شامل رنگ، اندازه، orientation، حرکت، و موقعیت فضایی است. Colin Ware در کتاب «Information Visualization: Perception for Design» (نسخه‌ی سوم، ۲۰۱۲) این ویژگی‌ها را به visualization تعمیم داد و نشان داد که استفاده‌ی هدفمند از یک ویژگی pre-attentive می‌تواند توجه را بدون cost cognitive به نقطه‌ای از گراف بکشاند.

ستون سوم، **Gestalt psychology** که با کار Max Wertheimer در ۱۹۲۳ شروع شد و توسط Kurt Koffka در ۱۹۳۵ بسط یافت. اصول Gestalt — proximity، similarity، continuity، closure، common region — قاعده‌های ناخودآگاه ادراک گروه‌بندی بصری را توصیف می‌کنند. Marriott و همکاران (۲۰۱۲) و سپس Bennett، Ryall و Gooch (۲۰۰۶) در «The Aesthetics of Graph Visualization» نشان دادند که هنگامی که graph layouts اصول symmetry و continuity در Gestalt را رعایت می‌کنند، شرکت‌کنندگان «impression عمیق‌تری» از ساختار گراف می‌گیرند.

علاوه بر این سه ستون نظری، یک یافته‌ی empirical کلیدی از Helen Purchase ادبیات graph drawing را تغییر داد. در مقاله‌ی «Which Aesthetic Has the Greatest Effect on Human Understanding» در سال ۱۹۹۷ (Lecture Notes in Computer Science) و سپس در «Empirical Evaluation of Aesthetics-Based Graph Layout» با Carrington و Allder در ۲۰۰۲، Purchase با شرکت‌کنندگان واقعی و وظایف کنترل‌شده نشان داد که **تقاطع یال‌ها (edge crossings) بزرگ‌ترین اثر منفی روی درک گراف دارد**، به‌مراتب بزرگ‌تر از سایر aesthetic principles مثل symmetry یا bend minimization. این یافته در replicationهای بعدی، از جمله Ware، Purchase، Colpoys و McGill در «Cognitive Measurements of Graph Aesthetics» در Information Visualization در ۲۰۰۲، تأیید شد.

برای انتخاب layout algorithm، مقاله‌ی Pohl و همکاران (۲۰۰۹) در Computational Aesthetics in Graphics با عنوان «Comparing the Readability of Graph Layouts Using Eyetracking and Task-Oriented Analysis» معیار طلایی است. آن‌ها سه layout — force-directed، orthogonal، و hierarchical — را در وظایف مختلف مقایسه کردند و نشان دادند که هیچ layout مطلقاً بهتر نیست: انتخاب باید به وظیفه‌ی کاربر بسته باشد. برای ساختارهای هرمی، Burch و Archambault مستقلاً نشان دادند که **چارچوب Sugiyama** (Sugiyama، Tagawa و Toda در IEEE Transactions on Systems, Man and Cybernetics در ۱۹۸۱) که ترکیب layered layout با crossing minimization است، بهترین خوانایی را برای trees و DAGs ارائه می‌دهد.

برای تشخیص حد مقیاس‌پذیری، یافته‌ی کلیدی از Yoghourdjian و همکاران (۲۰۲۰) در IEEE Transactions on Visualization and Computer Graphics با عنوان «Scalability of Network Visualisation from a Cognitive Load Perspective» می‌آید. آن‌ها با اندازه‌گیری EEG (theta brain activity)، pupil dilation و heart rate variability نشان دادند که در گراف‌های پرتراکم، کاربران از حدود ۵۰ گره به بعد دچار افت چشمگیر عملکرد می‌شوند، و در گراف‌های کم‌تراکم این آستانه حدود ۱۰۰ گره است. نکته‌ی شگفت‌آور این بود که cognitive load اندازه‌گیری‌شده با EEG **تا یک سطح بالا می‌رود و سپس افت می‌کند** — تفسیر محققان این بود که شرکت‌کنندگان به‌سادگی تسلیم می‌شوند و دیگر تلاش نمی‌کنند.

-----

## بخش دوم — کاربرد یافته‌ها در بستر Azura

گراف ما ۲۲ موجودیت و ۲۸ یال در ۱۰ نوع رابطه دارد. این عدد، با توجه به یافته‌ی Yoghourdjian، در محدوده‌ی «کم‌تراکم با اندازه‌ی کوچک» می‌نشیند که می‌توانیم کل گراف را در یک نمای واحد بدون aggregation رسم کنیم — یعنی خریدار کل ساختار JV را در یک نگاه می‌بیند، نه با کلیک کردن روی نمایش‌های متعدد. این یک مزیت مهم برای understanding task است.

ساختار گراف ۸۰٪ هرمی است: کشور → هلدینگ‌ها → developerها → JV → master development → پروژه → فازها → نوع واحد. این یعنی چارچوب Sugiyama که توسط Burch و Archambault برای DAGs توصیه شده، layout مناسب ماست. ولی ۲۰٪ یال‌ها افقی هستند (JV partnerships بین developerها، operator connections مثل Tabreed) که باید به‌صورت ویژه رسم شوند بدون این که سلسله‌مراتب اصلی را شلوغ کنند.

هدف buyer-side که در ابتدای کار قفل کردیم این بود که چشم خریدار قبل از هر چیز باید روی یک سؤال بنشیند: «من با چه نهادی قرارداد می‌بندم؟» — که جوابش Al Mouj Muscat S.A.O.C. است. این یعنی این گره باید با ویژگی pre-attentive از بقیه‌ی گراف متمایز شود تا در همان ۲۵۰ میلی‌ثانیه‌ی نگاه اول، خریدار آن را پیدا کند.

L0 یعنی Sultanate of Oman نقش regulatory frame را دارد — این موجودیت در گراف وجود دارد ولی نباید رقیب توجه با موجودیت‌های تجاری باشد. این یعنی باید با visual hierarchy کم‌رنگ‌تر رسم شود.

-----

## بخش سوم — هفت اصل طراحی استخراج‌شده

با ترکیب ادبیات با بستر Azura، هفت اصل عملیاتی برای طراحی گراف خروجی استخراج می‌شود. هر اصل به یک یا چند منبع علمی مستقیماً متصل است.

**اصل اول: Layered hierarchical layout با crossing minimization.** گراف باید با چارچوب Sugiyama رسم شود — موجودیت‌ها به لایه‌های افقی تخصیص یابند بر اساس entity_type، یال‌ها بین لایه‌ها رو به پایین جریان داشته باشند، و الگوریتم crossing minimization مرتبه‌ی گره‌ها در هر لایه را برای کاهش تقاطع‌ها تنظیم کند. پایه‌ی علمی: Sugiyama و همکاران (۱۹۸۱)، Burch (۲۰۱۱)، Archambault. این اصل مستقیماً یافته‌ی Purchase (۱۹۹۷، ۲۰۰۲) درباره‌ی بزرگ‌ترین اثر منفی edge crossings را به یک قاعده‌ی عملی تبدیل می‌کند.

**اصل دوم: Pre-attentive highlight روی موجودیت کلیدی buyer-side.** موجودیت Al Mouj Muscat S.A.O.C. باید با ترکیب دو ویژگی pre-attentive — رنگ متمایز و اندازه‌ی بزرگ‌تر — از بقیه‌ی گراف جدا شود تا در زیر ۲۵۰ میلی‌ثانیه‌ی نگاه اول کاربر، توجه روی آن بنشیند. پایه‌ی علمی: Treisman و Gelade (۱۹۸۰)، Ware (۲۰۱۲). دو ویژگی همزمان امن‌تر از یکی است چون اطمینان می‌دهد حتی در شرایط مختلف نمایش (موبایل، دسکتاپ، رنگ‌نابینایی) همچنان متمایز باقی می‌ماند.

**اصل سوم: Similarity به‌عنوان گروه‌بندی ضمنی.** موجودیت‌های هم‌نوع باید با شکل یا رنگ مشابه رسم شوند — مثلاً همه‌ی developerها با یک رنگ، همه‌ی phaseها با یک رنگ دیگر، همه‌ی operatorها با یک رنگ سوم. این به خواننده اجازه می‌دهد بدون توضیح یا legend سنگین، گروه‌ها را به‌صورت ناخودآگاه تشخیص دهد. پایه‌ی علمی: اصل similarity در Gestalt (Wertheimer ۱۹۲۳، Koffka ۱۹۳۵)، تفسیر Ware (۲۰۱۲). این اصل extraneous load را کاهش می‌دهد چون مغز کار گروه‌بندی را خودکار انجام می‌دهد.

**اصل چهارم: Proximity به‌عنوان نشانه‌ی ارتباط نزدیک.** موجودیت‌هایی که با هم رابطه‌ی نزدیک‌تر دارند باید در فضا نزدیک‌تر قرار گیرند. مثلاً سه شریک JV (MAF Properties، OMRAN، Tanmia) باید نزدیک به هم و نزدیک به نتیجه‌ی JVشان (Al Mouj S.A.O.C.) قرار گیرند. پایه‌ی علمی: اصل proximity در Gestalt، تأیید Marriott (۲۰۱۲). این کار به مغز اجازه می‌دهد ساختار JV را بدون تمرکز فعال روی یال‌ها درک کند.

**اصل پنجم: Common region برای جداسازی نقش‌ها.** موجودیت‌های با نقش متفاوت باید در نواحی بصری متمایز قرار گیرند — مثلاً جدول سرمایه‌گذاری در یک ناحیه، جدول عملیات (Tabreed، Bank Muscat) در ناحیه‌ی دیگر، جدول regulator در ناحیه‌ی سوم. این می‌تواند با background subtle یا با فضای خالی واضح ایجاد شود. پایه‌ی علمی: اصل common region/enclosure در Gestalt، تأیید Palmer (۱۹۹۲). این اصل به جداسازی مفهومی بدون تحمیل یال‌های اضافه کمک می‌کند.

**اصل ششم: حداقل ink اضافه و حذف tinsel.** هر pixel غیرضروری، هر رنگ تزئینی، هر یال غیرلازم، هر decoration بدون اطلاعات، extraneous load تحمیل می‌کند. هر عنصر بصری باید توجیه اطلاعاتی داشته باشد. پایه‌ی علمی: data-ink ratio از Edward Tufte (۱۹۸۳، The Visual Display of Quantitative Information)، CLT از Sweller (۱۹۸۸). این اصل ratio capacity working memory را برای germane load (یعنی فهم رابطه‌ها) آزاد نگه می‌دارد.

**اصل هفتم: Salience تدریجی برای hierarchy اطلاعات.** L0 (regulator) که context است نه مرکز توجه، باید بصرتاً کم‌رنگ‌تر و کنار باشد. L1 (developers) باید واضح ولی نه dominant باشد. L1c (JV) باید مرکز توجه باشد چون buyer-relevance بالا دارد. L2-L2.5 (پروژه و فازها) باید تکمیل‌گر باشند. این اصل از Tufte (۱۹۸۳، Principle of Smallest Effective Difference) و کار Munzner (۲۰۱۴، Visualization Analysis and Design) می‌آید.

-----

## بخش چهارم — تصمیمات طراحی مشخص بر اساس این اصول

با این هفت اصل، تصمیمات زیر برای طراحی گراف Azura ساخته می‌شود.

از نظر **layout** الگوریتم Sugiyama با هشت لایه تعریف می‌شود: لایه‌ی صفر یعنی regulator (Oman)، لایه‌ی یک یعنی parent holdings، لایه‌ی دو یعنی operating developers، لایه‌ی سه یعنی JV entity (Al Mouj Muscat S.A.O.C.)، لایه‌ی چهار یعنی master development (Al Mouj Community)، لایه‌ی پنج یعنی project (Azura)، لایه‌ی شش یعنی product phases (۱-۴)، و لایه‌ی هفت یعنی unit types. operators (Tabreed، Bank Muscat) خارج از هرم اصلی در یک ستون کناری قرار می‌گیرند با یال‌های مستقیم به سطوح مرتبط.

از نظر **رنگ** پالت IBM Plex monochrome محدود به سه رنگ کلیدی استفاده می‌شود تا extraneous load کم بماند. خاکستری‌ها برای ساختار، یک رنگ accent (مثلاً نارنجی محدود) برای موجودیت کلیدی Al Mouj S.A.O.C.، و یک رنگ secondary (مثلاً آبی محدود) برای operatorهای offline. هیچ رنگ تزئینی استفاده نمی‌شود.

از نظر **اندازه** Al Mouj Muscat S.A.O.C. در مرکز ۳۰٪ بزرگ‌تر از سایر گره‌ها رسم می‌شود. Oman regulator حدود ۲۰٪ کوچک‌تر و کم‌رنگ‌تر از بقیه نشان داده می‌شود تا واضح باشد context است نه actor. سایر گره‌ها در اندازه‌ی استاندارد. این salience تدریجی را تأمین می‌کند.

از نظر **شکل** هر entity_type یک شکل خاص دارد. مستطیل برای companies (holdings, developers, JV)، گرد برای places (country, master_development, project)، الماس برای phases، مربع کوچک برای unit types، شش‌ضلعی برای operators. این به similarity grouping کمک می‌کند بدون نیاز به رنگ اضافه.

از نظر **یال‌ها** انواع یال با style متفاوت تمایز داده می‌شوند: solid line برای containment hierarchy (هرم اصلی)، dashed برای JV partnerships (افقی، اختیاری)، dotted برای operations (offline)، double-line برای contractual_party_for_buyer که critical است. هر یال یک label کوتاه دارد ولی فقط در hover ظاهر می‌شود تا گراف ابتدایی شلوغ نباشد.

از نظر **interactivity** گراف static نخواهد بود. روی hover یک گره، اتم‌های مرتبط با آن گره نمایش داده می‌شوند. روی hover یک یال، توضیح ماهیت رابطه (مثلاً «MAF Properties با ۵۰٪ مالکیت در Al Mouj S.A.O.C. شریک JV است») ظاهر می‌شود. روی کلیک یک گره، یک panel جانبی باز می‌شود با لیست کامل اتم‌ها، contradictionها، و missingness مرتبط. این به اصل CLT کمک می‌کند: نمایش اولیه ساده می‌ماند، اطلاعات اضافه only on demand.

-----

## بخش پنجم — معیارهای ارزیابی موفقیت طراحی

طراحی نهایی باید این معیارها را پاس کند تا قابل‌قبول باشد:

موجودیت Al Mouj Muscat S.A.O.C. باید در زیر ۲۵۰ میلی‌ثانیه‌ی نگاه اول توسط کاربر تازه‌وارد قابل‌تشخیص باشد. این معیار pre-attentive processing را verify می‌کند.

تعداد edge crossings در نمای اصلی باید صفر باشد، یا اگر صفر ممکن نیست، حداقل ممکن باشد. این معیار یافته‌ی Purchase را verify می‌کند.

کاربر تازه‌وارد بدون legend باید بتواند تشخیص دهد که سه گره با رنگ یکسان (developerها) هم‌نوع‌اند. این معیار اصل Gestalt similarity را verify می‌کند.

cognitive load self-reported کاربر بعد از یک دقیقه تعامل باید زیر یک آستانه‌ی قابل‌قبول باشد (مثلاً ۴ از ۷ در NASA-TLX scale). این معیار CLT را verify می‌کند.

اگر این چهار معیار pass شد، طراحی به استانداردهای علوم شناختی بصری احترام گذاشته است. اگر هر کدام fail شد، باید بازنگری شود.

-----

## ارجاعات کلیدی

Sweller, J. (1988). Cognitive load during problem solving. Cognitive Science, 12(2), 257-285.

Cowan, N. (2001). The magical number 4 in short-term memory. Behavioral and Brain Sciences, 24(1), 87-114.

Treisman, A., & Gelade, G. (1980). A feature-integration theory of attention. Cognitive Psychology, 12(1), 97-136.

Ware, C. (2012). Information Visualization: Perception for Design (3rd ed.). Morgan Kaufmann.

Wertheimer, M. (1923). Untersuchungen zur Lehre von der Gestalt II. Psychologische Forschung, 4(1), 301-350.

Purchase, H. (1997). Which aesthetic has the greatest effect on human understanding? In Graph Drawing GD’97, LNCS 1353, 248-261.

Purchase, H., Carrington, D., & Allder, J. (2002). Empirical evaluation of aesthetics-based graph layout. Empirical Software Engineering, 7(3), 233-255.

Ware, C., Purchase, H., Colpoys, L., & McGill, M. (2002). Cognitive measurements of graph aesthetics. Information Visualization, 1(2), 103-110.

Sugiyama, K., Tagawa, S., & Toda, M. (1981). Methods for visual understanding of hierarchical systems. IEEE Transactions on Systems, Man and Cybernetics, 11(2), 109-125.

Pohl, M., Schmitt, M., & Diehl, S. (2009). Comparing readability of graph layouts using eyetracking and task-oriented analysis. Proceedings of Computational Aesthetics in Graphics, Visualization, and Imaging.

Yoghourdjian, V., Yang, Y., Dwyer, T., Lawrence, L., Wybrow, M., & Marriott, K. (2020). Scalability of network visualisation from a cognitive load perspective. IEEE Transactions on Visualization and Computer Graphics, 27(2), 1677-1687.

Tufte, E. R. (1983). The Visual Display of Quantitative Information. Graphics Press.

Munzner, T. (2014). Visualization Analysis and Design. CRC Press.

Marriott, K., Stuckey, P. J., & Wybrow, M. (2012). Hola: Human-like orthogonal network layout. IEEE Transactions on Visualization and Computer Graphics, 18(12), 2657-2666.

Bennett, C., Ryall, J., Spalteholz, L., & Gooch, A. (2006). The aesthetics of graph visualization. In Proceedings of Computational Aesthetics in Graphics, Visualization, and Imaging.