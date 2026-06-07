# P2.G6 — Bridge Design: SQLite Prism → Postgres Prism

**وضعیت:** پیشنهاد، در انتظار اجرای Claude Code در سه substep
**فاز:** Dot Activation — Phase 2, Gate 6 (re-prioritized to precede G2)
**مبنا:** snapshot واقعی SQLite Prism (۵۶۴ event، Merkle root `dd1c4bfe…`)، ADR معماری دو‌خزانه، و قرارداد G1.
**هدف این فایل:** تنها منبع canonical حقیقت برای انتقال یک‌طرفه‌ی SQLite Prism به Postgres Prism، با حفظ کامل provenance و idempotency.

-----

## بخش یک — شش اصل قفل‌شده

این شش اصل مرز کل bridge را تعریف می‌کنند و در هیچ substep بازنمی‌شوند.

**اصل یک — جهت یک‌طرفه.** خواندن از SQLite (CSVهای `data/prism/` که source of truth هستند)، نوشتن به Postgres. هیچ نوشتنی به SQLite اتفاق نمی‌افتد، هیچ بازخوانی از Postgres به SQLite، هیچ replication دوطرفه. SQLite تا لحظه‌ی freeze (G6c) source of truth می‌ماند؛ بعد از freeze، Postgres تنها source of truth است.

**اصل دو — Idempotent بودن.** هر جدول Postgres که داده‌ی SQLite دریافت می‌کند، یک ستون `legacy_id TEXT UNIQUE` دارد که `evidence_atom_id`, `source_id`, `criterion_id`, `missingness_id` و امثال آن را نگه می‌دارد. upsert از طریق `ON CONFLICT (legacy_id) DO UPDATE`. اجرای دوباره‌ی bridge همان state را تولید می‌کند، نه duplicate.

**اصل سه — افزودنی محض روی Postgres.** هیچ migration موجود (G1 یا قبل از آن) تغییر نمی‌کند. تنها تغییرات Postgres در یک migration جدید: افزودن `legacy_id` به جدول‌های موجود، افزودن ستون `evidence_quality` به `private.atoms`، افزودن JSONB `metadata` به `private.contradictions`، و ساخت چهار جدول جدید operator-side.

**اصل چهار — حفظ کامل provenance.** هر hash مرتبط (`_content_hash`, `_chain_prev`, `_chain_hash`) به Postgres منتقل می‌شود. در Postgres این‌ها در ستون‌های `legacy_content_hash`, `legacy_chain_prev`, `legacy_chain_hash` نگه‌داری می‌شوند. Postgres زنجیره را ادامه نمی‌دهد (Merkle authority سمت SQLite بود)، ولی مقادیر را برای audit آینده محفوظ نگه می‌دارد.

**اصل پنج — Halt-on-unknown.** اگر bridge به یک layer ناشناخته (L3/L4 بدون classification)، یک unit_id جدید (بدون entity مرتبط)، یا یک criterion_type ناشناخته برخورد کند، transaction را rollback می‌کند و خطایی دقیق با لیست موارد می‌دهد. هیچ heuristic روی داده‌ی واقعی اعمال نمی‌شود.

**اصل شش — Single transaction.** یک bridge run یعنی یک transaction Postgres. یا همه‌ی ۱۹۱ atom + ۱۵۶ source + ۵۳ criterion + ۳۸ ticket + ۴۱ missingness + ۱۵ contradiction + ۲۴ statement + ۴۶ strategy منتقل می‌شوند و commit می‌شود، یا rollback کامل و state Postgres دست‌نخورده می‌ماند. هیچ partial state.

-----

## بخش دو — Postgres schema delta (G6a)

این migration به `-dot-Big` اضافه می‌شود، **بدون** هیچ تغییر در فایل‌های موجود.

**افزودن `legacy_id TEXT UNIQUE` به جدول‌های موجود `private.*`:**

```sql
ALTER TABLE private.entities    ADD COLUMN legacy_id TEXT UNIQUE;
ALTER TABLE private.sources     ADD COLUMN legacy_id TEXT UNIQUE;
ALTER TABLE private.criteria    ADD COLUMN legacy_id TEXT UNIQUE;
ALTER TABLE private.atoms       ADD COLUMN legacy_id TEXT UNIQUE;
ALTER TABLE private.missingness ADD COLUMN legacy_id TEXT UNIQUE;
ALTER TABLE private.contradictions ADD COLUMN legacy_id TEXT UNIQUE;
```

**افزودن ستون typed `evidence_quality` به `private.atoms`:**

```sql
ALTER TABLE private.atoms
    ADD COLUMN evidence_quality TEXT CHECK (
        evidence_quality IS NULL OR
        evidence_quality IN ('confirmed', 'partially_supported', 'not_established')
    );

CREATE INDEX idx_atoms_evidence_quality ON private.atoms(evidence_quality);
```

این ستون typed است نه JSONB، چون cockpit در Gap Map روی هر cell یک query دارد و JSONB query هزینه‌بر است.

**افزودن `metadata JSONB` به `private.contradictions`:**

```sql
ALTER TABLE private.contradictions ADD COLUMN metadata JSONB DEFAULT '{}'::jsonb;
```

برای نگه‌داری `materiality`, `tie_breaker_rule_applied`, `confidence_impact`, و باقی فیلدهای SQLite که typed column ندارند.

**چهار جدول جدید operator-side در schema `private`:**

```sql
-- 1. private.source_strategy_registry — ۴۶ ردیف
CREATE TABLE private.source_strategy_registry (
    strategy_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legacy_id                TEXT UNIQUE NOT NULL,
    criterion_id             UUID REFERENCES private.criteria(criterion_id),
    layer                    TEXT NOT NULL,
    preferred_source_classes TEXT[],
    allowed_source_classes   TEXT[],
    forbidden_source_types   TEXT,
    preferred_source_types   TEXT,
    weak_signal_role         TEXT,
    required_language_policy TEXT,
    search_budget_max_queries INTEGER,
    stop_rule                TEXT,
    confirmation_rule        TEXT,
    missingness_if_absent    TEXT,
    question_back_template   TEXT,
    escalation_rule          TEXT,
    update_trigger           TEXT,
    notes                    TEXT,
    legacy_content_hash      TEXT,
    legacy_chain_prev        TEXT,
    legacy_chain_hash        TEXT,
    legacy_inserted_at       TIMESTAMPTZ,
    metadata                 JSONB DEFAULT '{}'::jsonb,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. private.contradiction_statements — ۲۴ ردیف
CREATE TABLE private.contradiction_statements (
    statement_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legacy_id                TEXT UNIQUE NOT NULL,
    contradiction_id         UUID NOT NULL REFERENCES private.contradictions(contradiction_id),
    statement_order          INTEGER,
    source_record_id         UUID REFERENCES private.sources(source_id),
    source_class_at_time     INTEGER,
    claim_text               TEXT,
    legacy_content_hash      TEXT,
    legacy_chain_prev        TEXT,
    legacy_chain_hash        TEXT,
    legacy_inserted_at       TIMESTAMPTZ,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. private.question_back_tickets — ۳۸ ردیف
CREATE TABLE private.question_back_tickets (
    ticket_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legacy_id                TEXT UNIQUE NOT NULL,
    case_id                  TEXT,
    research_run_id          UUID, -- nullable, may FK after research_runs has rows
    entity_id                UUID REFERENCES private.entities(entity_id),
    layer                    TEXT,
    criterion_id             UUID REFERENCES private.criteria(criterion_id),
    ticket_type              TEXT,
    ticket_status            TEXT NOT NULL CHECK (ticket_status IN (
        'open', 'in_progress', 'answered', 'closed', 'hold'
    )),
    ticket_priority          TEXT,
    assigned_role            TEXT,
    question_text            TEXT NOT NULL,
    why_needed               TEXT,
    required_evidence_type   TEXT,
    acceptable_source_classes TEXT[],
    blocked_until_answered   BOOLEAN DEFAULT false,
    created_from_missingness_id UUID REFERENCES private.missingness(missingness_id),
    created_from_contradiction_id UUID REFERENCES private.contradictions(contradiction_id),
    escalation_flag          BOOLEAN DEFAULT false,
    due_state                TEXT,
    resolution_status        TEXT,
    resolution_note          TEXT,
    notes                    TEXT,
    legacy_created_at        TIMESTAMPTZ,
    legacy_updated_at        TIMESTAMPTZ,
    legacy_closed_at         TIMESTAMPTZ,
    legacy_content_hash      TEXT,
    legacy_chain_prev        TEXT,
    legacy_chain_hash        TEXT,
    legacy_inserted_at       TIMESTAMPTZ,
    metadata                 JSONB DEFAULT '{}'::jsonb,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_qb_tickets_status   ON private.question_back_tickets(ticket_status);
CREATE INDEX idx_qb_tickets_entity   ON private.question_back_tickets(entity_id);
CREATE INDEX idx_qb_tickets_criterion ON private.question_back_tickets(criterion_id);

-- 4. private.research_runs — صفر ردیف فعلاً، ولی schema برای آینده
CREATE TABLE private.research_runs (
    research_run_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legacy_id                TEXT UNIQUE NOT NULL,
    case_id                  TEXT,
    run_title                TEXT,
    run_status               TEXT,
    run_mode                 TEXT,
    layer_scope              TEXT,
    started_at               TIMESTAMPTZ,
    completed_at             TIMESTAMPTZ,
    notes                    TEXT,
    legacy_content_hash      TEXT,
    legacy_chain_hash        TEXT,
    metadata                 JSONB DEFAULT '{}'::jsonb,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**RLS برای همه‌ی جدول‌های جدید:**

```sql
ALTER TABLE private.source_strategy_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.contradiction_statements ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.question_back_tickets    ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.research_runs             ENABLE ROW LEVEL SECURITY;
-- بدون policy = deny-by-default برای anon/authenticated، فقط service_role می‌نویسد/می‌خوانَد.
```

-----

## بخش سه — قوانین نگاشت

این بخش از سه بخش قبلی مفصل‌تر است چون قلب bridge است.

**نگاشت layer → level برای atomها:**

|SQLite `layer`           |Postgres `level`                                 |یادداشت                                                  |
|-------------------------|-------------------------------------------------|---------------------------------------------------------|
|`L0_COUNTRY_JURISDICTION`|`framework`                                      |قوانین، رگولاتوری، AML — جهانی برای جواز                 |
|`L1_DEVELOPER`           |`platform_level`                                 |سوابق سازنده — اثرش روی پروژه ولی متعلق به سازنده        |
|`L2_PROJECT`             |`project_specific`                               |اتم‌هایی که فقط درباره‌ی پروژه‌ی مشخص هستند                 |
|`L3_…`                   |از `config/l3_l4_classification.csv` خوانده می‌شود|اگر atom_id در فایل نباشد، halt                          |
|`L4_…`                   |`platform_level`                                 |اپراتورها (Tabreed، Bank Muscat) — factual نه synthesized|

**فایل classification برای L3/L4 (در ریپوی `dot-internal-decision-pack`):**

```
config/l3_l4_classification.csv
---
atom_id,target_level,note
EA_L3_…,project_specific,raw factual about phase delivery
EA_L3_…,analytical_insight,operator judgment about brand strategy
…
```

bridge قبل از start با یک discovery pass فهرست L3/L4 atomهای موجود را تولید می‌کند، اپراتور CSV را پر می‌کند، bridge دوباره اجرا می‌شود. اگر هیچ L3/L4 موجود نیست، فایل classification لازم نیست.

**نگاشت criterion_type → section:**

|SQLite `criterion_type`    |Postgres `section`         |
|---------------------------|---------------------------|
|`gate_blocker`             |`gate_board`               |
|`signal_escalation_trigger`|`escalation`               |
|`scoring_criterion`        |`score_core`               |
|`modifier`                 |`developer_modifier`       |
|`descriptive_marker`       |`descriptive`              |
|(ناشناخته)                 |`descriptive` + log warning|

**نگاشت source_class TEXT → INTEGER:**

|SQLite `source_class`            |Postgres `source_class`                            |
|---------------------------------|---------------------------------------------------|
|`class_1_primary_authoritative`  |`1`                                                |
|`class_2_official_but_interested`|`2`                                                |
|`class_3_credible_third_party`   |`3`                                                |
|`class_4_broker_secondary`       |`4` (اگر در SQLite ظاهر شود)                       |
|`none`                           |`NULL` (نیازمند نرمش CHECK constraint — به بخش بعد)|

برای رسیدن به `NULL` در `source_class`، CHECK constraint موجود `BETWEEN 1 AND 4` در migration G6a به این تبدیل می‌شود:

```sql
ALTER TABLE private.sources DROP CONSTRAINT sources_source_class_check;
ALTER TABLE private.sources ADD CONSTRAINT sources_source_class_check
    CHECK (source_class IS NULL OR source_class BETWEEN 1 AND 4);
```

این تنها استثنای additive-only است که توجیه می‌خواهد: SQLite برخی منابع placeholder دارد (مثل `SRC_PRISM_NO_PUBLIC_EVIDENCE_FOUND`) با `source_class = none`. این placeholderها برای ثبت «شواهد عمومی پیدا نشد» در contradiction_register ضروری‌اند و باید منتقل شوند.

**نگاشت atom status (دوگانه‌ی مهم):**

|SQLite `status`      |Postgres `status`|Postgres `evidence_quality`|
|---------------------|-----------------|---------------------------|
|`confirmed`          |`active`         |`confirmed`                |
|`partially_supported`|`active`         |`partially_supported`      |
|`not_established`    |`active`         |`not_established`          |

`status` در Postgres «چرخه‌ی عمر» است، نه «کیفیت شواهد». همه‌ی اتم‌های import‌شده `active` هستند چون current. کیفیت در ستون typed جدید نگه‌داری می‌شود.

**نگاشت unit_id → entity:**

این یکی نیاز به یک فایل curation دارد چون cockpit نام‌های زیبا می‌خواهد (مثل «Al Mouj Muscat» نه `u_developer_al_mouj`).

```
config/unit_id_to_entity.csv
---
unit_id,canonical_name,entity_type,jurisdiction,status
u_jurisdiction_oman,Sultanate of Oman,country,OM,active
u_developer_dar_global_plc,Dar Global PLC,developer,OM,active
u_developer_al_mouj,Al Mouj Muscat S.A.O.C.,jv,OM,active
u_developer_omran,OMRAN Group SAOC,developer,OM,active
u_developer_diamond,Diamond / SEE Holding,developer,OM,active
u_developer_muriya,Muriya Tourism,developer,OM,active
u_developer_mhid,MHID,developer,OM,active
u_project_pilot_001,Pilot Project 001,project,OM,off_plan
…
```

bridge این فایل را در شروع می‌خواند، entityها را upsert می‌کند (اگر legacy_id موجود است در Postgres ولی unit_id نه، یعنی entity Azura که در seed Phase 1 ساخته شد — به آن legacy_id نمی‌چسبانیم و یک check ضمنی برقرار می‌کنیم). اگر unit_id در فایل نیست ولی در atomها استفاده شده، halt با لیست.

**نگاشت provenance/Merkle (یک‌یک):**

|SQLite         |Postgres                                                     |
|---------------|-------------------------------------------------------------|
|`_content_hash`|`content_hash` (atoms only) یا `legacy_content_hash` (همه جا)|
|`_chain_prev`  |`legacy_chain_prev`                                          |
|`_chain_hash`  |`legacy_chain_hash`                                          |
|`_inserted_at` |`legacy_inserted_at`                                         |

برای atomهای موجود (که Postgres ستون `content_hash` typed دارد)، مقدار SQLite در `content_hash` می‌نشیند. ستون‌های زنجیره به ستون‌های جدید `legacy_chain_*` می‌روند.

-----

## بخش چهار — معماری bridge script (G6b)

**زبان و مکان:**

- Python 3.10+ (مطابق با باقی `app/` در ریپوی `dot-internal-decision-pack`).
- مسیر فایل: `app/bridge_to_postgres_v0_1.py`.
- وابستگی‌ها: `psycopg2-binary`. این به `pyproject.toml` یا `requirements.txt` اضافه می‌شود.

**ورودی:**

- خواندن CSVها از `data/prism/` (source of truth).
- خواندن دو فایل config: `config/unit_id_to_entity.csv` و (در صورت وجود L3/L4) `config/l3_l4_classification.csv`.
- خواندن `POSTGRES_DSN` از env (service_role key لازم است چون به `private.*` می‌نویسد).

**خروجی:**

- یک گزارش run در `logs/bridge_runs/run_<ISO_timestamp>.md` با: تعداد سطرهای منتقل‌شده per table، خطاهای dry-run (اگر), validation results، Postgres root hash بعد از import.
- exit code 0 برای موفقیت، غیرصفر برای halt.

**سکوئنس درون transaction:**

۱. discovery pass: فقط READ از CSVها، لیست unit_idهای جدید و L3/L4 atomها را generate کن. اگر classification CSV لازم است و موجود نیست، halt با لیست.

۲. begin transaction.

۳. upsert entities (از `config/unit_id_to_entity.csv`).

۴. upsert criteria (از `criterion_registry.csv` با نگاشت criterion_type → section).

۵. upsert source_strategy_registry (از `source_strategy_registry.csv`، FK به criteria).

۶. upsert sources (از `source_record.csv`، FK به criteria + source_strategy).

۷. upsert atoms (از `evidence_atom.csv`، با نگاشت layer→level، status→active+evidence_quality، FK به entities/criteria/sources).

۸. upsert missingness (از `missingness_register.csv`، FK به entities/criteria).

۹. upsert contradictions (از `contradiction_register.csv`، با اطلاعات SQLite extra در metadata، FK به atoms via `related_evidence_atom_ids`).

۱۰. upsert contradiction_statements (از `contradiction_statements.csv`، FK به contradictions/sources).

۱۱. upsert question_back_tickets (از `question_back_ticket.csv`، FK به entities/criteria/missingness/contradictions).

۱۲. validation queries (بخش بعد).

۱۳. اگر validation pass، commit. اگر fail، rollback و گزارش error.

**Halt conditions:**

- CSV های لازم در `data/prism/` نیستند.
- `POSTGRES_DSN` set نیست یا اتصال شکست خورد.
- migration G6a روی Postgres apply نشده (یعنی ستون `legacy_id` در جدول‌های مقصد نیست) — bridge با یک check اولیه این را تشخیص می‌دهد.
- یک unit_id در atomها هست که در `config/unit_id_to_entity.csv` نیست.
- یک L3/L4 atom هست بدون classification.
- یک criterion_type ناشناخته که در فهرست mapping نیست.
- FK violation در هر upsert.
- validation fail بعد از import (row count mismatch، orphan FK).

-----

## بخش پنج — تست‌های پذیرش (در پایان G6b run)

این کوئری‌ها در گزارش run درج می‌شوند. همه باید pass شوند تا G6 closed شود.

**یک، parity تعداد سطر:**

```sql
SELECT
  (SELECT COUNT(*) FROM private.atoms WHERE legacy_id IS NOT NULL)            AS atoms,            -- باید ۱۹۱
  (SELECT COUNT(*) FROM private.sources WHERE legacy_id IS NOT NULL)          AS sources,          -- باید ۱۵۶
  (SELECT COUNT(*) FROM private.criteria WHERE legacy_id IS NOT NULL)         AS criteria,         -- باید ۵۳
  (SELECT COUNT(*) FROM private.source_strategy_registry)                     AS strategies,        -- باید ۴۶
  (SELECT COUNT(*) FROM private.missingness WHERE legacy_id IS NOT NULL)      AS missingness,      -- باید ۴۱
  (SELECT COUNT(*) FROM private.question_back_tickets)                        AS tickets,          -- باید ۳۸
  (SELECT COUNT(*) FROM private.contradictions WHERE legacy_id IS NOT NULL)   AS contradictions,   -- باید ۱۵
  (SELECT COUNT(*) FROM private.contradiction_statements)                     AS statements;       -- باید ۲۴
```

**دو، FK integrity:**

```sql
-- atoms with broken entity FK
SELECT COUNT(*) FROM private.atoms a
LEFT JOIN private.entities e ON e.entity_id = a.entity_id
WHERE a.legacy_id IS NOT NULL AND e.entity_id IS NULL;
-- باید صفر
```

(و مشابه برای criterion_id، source_id در atoms؛ entity_id در missingness و tickets؛ …)

**سه، hash preservation:**

```sql
-- atomها همه باید content_hash داشته باشند
SELECT COUNT(*) FROM private.atoms
WHERE legacy_id IS NOT NULL AND (content_hash IS NULL OR content_hash = '');
-- باید صفر
```

**چهار، evidence_quality distribution:**

```sql
SELECT evidence_quality, COUNT(*)
FROM private.atoms
WHERE legacy_id IS NOT NULL
GROUP BY evidence_quality;
-- باید سه سطر: confirmed، partially_supported، not_established
```

-----

## بخش شش — رویه‌ی post-bridge (G6c)

بعد از G6b موفق:

۱. **Archive snapshot SQLite قبل از freeze.** Claude Code در ریپوی `dot-internal-decision-pack`:

```bash
TS=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
mkdir -p archive
python -c "from app.prism_core_store_v0_1 import create_store; \
  create_store(f'archive/sqlite_prism_pre_bridge_{TS}.db', \
               'data/prism/contracts_schema', 'data/prism/datapackage.json')"
SHA=$(sha256sum archive/sqlite_prism_pre_bridge_${TS}.db | awk '{print $1}')

cat >> archive/MANIFEST.md << EOF

## archive/sqlite_prism_pre_bridge_${TS}.db
- sha256: ${SHA}
- generated_at: ${TS}
- merkle_root: dd1c4bfe1248d459abd91f5e9a040c931a650bb13795c97003486bf2fa9cba6a
- event_count: 564
- post_bridge: یعنی این snapshot قبل از freeze گرفته شده و state SQLite در لحظه‌ی bridge را reproduce می‌کند
EOF

git add archive/
git commit -m "P2.G6c: Archive SQLite snapshot pre-freeze"
git push
```

۲. **Freeze SQLite در سطح repo.** یک فایل `FROZEN.md` به ریشه‌ی ریپوی `dot-internal-decision-pack` اضافه می‌شود:

```markdown
# dot-internal-decision-pack — FROZEN

این repo از تاریخ <ISO_timestamp> به‌صورت read-only فریز شده.
Source of truth جدید: Postgres Prism در ریپوی -dot-Big.
هیچ‌گونه نوشتنی به data/prism/ مجاز نیست. اگر تغییری لازم است،
مستقیماً در Postgres اعمال می‌شود.

برای trace به state pre-bridge: archive/MANIFEST.md
```

۳. **commit نهایی G6.** هر دو ریپو در یک ساعت push می‌شوند: `-dot-Big` (migration + run logs)، `dot-internal-decision-pack` (archive + FROZEN.md).

-----

## بخش هفت — مرز DO NOT

**برای Claude Code در G6a:**

- هیچ migration موجود تغییر نمی‌کند (`20260606000000`, `20260606000100`, `20260606010000`, `20260607000000_p2g1_dossier_api`).
- هیچ view موجود بازنویسی نمی‌شود.
- هیچ FK جدید بین جدول‌های موجود اضافه نمی‌شود (فقط FK های مربوط به جدول‌های جدید).
- تابع `public_serving.get_project_dossier` byte-identical می‌ماند.
- هیچ GRANT جدید به `anon`/`authenticated` (همه‌ی جدول‌های جدید RLS deny-by-default).

**برای Claude Code در G6b:**

- هیچ تغییری به CSVهای `data/prism/`.
- هیچ تغییری به `app/prism_core_store_v0_1.py`.
- هیچ نوشتنی به SQLite (.db files).
- هیچ استفاده از کلید anon Postgres (فقط service_role).
- هیچ web search، هیچ external API call.
- هیچ سرکشی به ریپوی `-dot-Big`.
- bridge فقط یک‌جا می‌نویسد: Postgres production.

**برای اپراتور (Mr. H):**

- قبل از اجرای G6b در production، یک dry-run با flag `--dry-run` لازم است که فقط validate می‌کند بدون commit.
- G6c (archive + freeze) فقط بعد از تأیید G6b با همه‌ی acceptance tests pass انجام می‌شود.
- بعد از freeze، هیچ‌گونه edit در `data/prism/` انجام نمی‌شود — هرگونه تغییر باید مستقیم در Postgres بنشیند.

-----

## بخش هشت — قدم بعدی

با merge G6a و G6b و اجرای موفق G6c، گیت ۶ closed و G2 (operator-side API contract + اتصال cockpit به Postgres) آغاز می‌شود. در G2، تابع‌های جدید مشابه `get_project_dossier` ساخته می‌شوند که داده‌ی operator-side را به cockpit می‌رسانند — شامل source URL، source class، contradiction details، gap map و pipeline data.