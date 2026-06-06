-- ============================================================================
-- Dot Prism — Data Load 002: Azura Beach Residences Vertical Slice
-- Purpose: Load all entities, edges, atoms for Azura into the new schema
-- Prerequisite: Run 001_schema_migration.sql first
-- Date: 2026-06-06
-- ============================================================================

BEGIN;

-- ============================================================================
-- STEP 1: Load sources
-- Each source we'll reference must exist before atoms can cite it.
-- ============================================================================

INSERT INTO private.sources (source_id, source_name, source_url, source_class, publisher, publication_date, language) VALUES
    ('11111111-1111-1111-1111-000000000001', 'MAF Properties FY2025 Audited Financial Statements', NULL, 1, 'Majid Al Futtaim Properties LLC', '2026-03-01', 'en'),
    ('11111111-1111-1111-1111-000000000002', 'Royal Decree 30/2018 Escrow Law', 'https://decree.om', 1, 'Sultanate of Oman', '2018-04-01', 'ar'),
    ('11111111-1111-1111-1111-000000000003', 'Royal Decree 79/2025 Real Estate Regulation Law', 'https://decree.om', 1, 'Sultanate of Oman', '2025-09-14', 'ar'),
    ('11111111-1111-1111-1111-000000000004', 'MoHUP Escrow Account Details Page', 'https://mohup.gov.om/en/media/announcements', 1, 'Ministry of Housing and Urban Planning', '2026-05-24', 'en'),
    ('11111111-1111-1111-1111-000000000005', 'Al Mouj Official Website — Azura Beach Residences II', 'https://www.almouj.com/en/azura-beach-residences/', 2, 'Al Mouj Muscat S.A.O.C.', '2025-10-01', 'en'),
    ('11111111-1111-1111-1111-000000000006', 'Al Mouj Official Website — Azura III IV', 'https://www.almouj.com/en/azura-iii-iv/', 2, 'Al Mouj Muscat S.A.O.C.', '2026-02-15', 'en'),
    ('11111111-1111-1111-1111-000000000007', 'AzuraII_digital_English.pdf Brochure', 'https://www.almouj.com/wp-content/uploads/2025/10/AzuraII_digital_English.pdf', 2, 'Al Mouj Muscat S.A.O.C.', '2025-10-01', 'en'),
    ('11111111-1111-1111-1111-000000000008', 'Azura_Digital_Eng_AZ4.pdf Brochure', 'https://www.almouj.com/wp-content/uploads/2026/02/Azura_Digital_Eng_AZ4.pdf', 2, 'Al Mouj Muscat S.A.O.C.', '2026-02-15', 'en'),
    ('11111111-1111-1111-1111-000000000009', 'amm_Azura_Digital_Eng_AZ3.pdf Brochure', 'https://www.almouj.com/wp-content/uploads/2026/02/amm_Azura_Digital_Eng_AZ3.pdf', 2, 'Al Mouj Muscat S.A.O.C.', '2026-02-15', 'en'),
    ('11111111-1111-1111-1111-000000000010', 'Zawya Press Release — Azura Phase 1 Launch', 'https://www.zawya.com/en/press-release/companies-news/al-mouj-muscat-launches-azura-beach-residences', 2, 'Al Mouj via Zawya', '2025-07-06', 'en'),
    ('11111111-1111-1111-1111-000000000011', 'Zawya Press Release — Azura Phase 3+4 Launch', 'https://www.tradingview.com/news/reuters.com,2026-02-15:newsml_ZawHW8wf:0-zawya-pressr-al-mouj-muscat', 2, 'Al Mouj via Zawya', '2026-02-15', 'en'),
    ('11111111-1111-1111-1111-000000000012', 'Muscat Daily — Azura Launch', 'https://www.muscatdaily.com/2025/07/06/al-mouj-muscat-launches-azura-beach-residences/', 3, 'Muscat Daily', '2025-07-06', 'en'),
    ('11111111-1111-1111-1111-000000000013', 'GCC Business News — Azura III IV', 'https://www.gccbusinessnews.com/al-mouj-muscat-azura-beach-residences', 3, 'GCC Business News', '2026-02-14', 'en'),
    ('11111111-1111-1111-1111-000000000014', 'Oman Observer — Azura Long-term Investors', 'https://www.omanobserver.om/article/1184398', 3, 'Oman Observer', '2026-02-20', 'en'),
    ('11111111-1111-1111-1111-000000000015', 'Kanebridge News — Azura Reveal', 'https://kanebridgenewsme.com/al-mouj-muscat-reveals-azura-beach-residences/', 3, 'Kanebridge News', '2025-07-09', 'en'),
    ('11111111-1111-1111-1111-000000000016', 'Dentons Analysis — Oman Civil Code Article 267', 'https://www.dentons.com/en/insights/alerts/2013/october/28/omans-new-civil-code', 2, 'Dentons Law Firm', '2013-10-28', 'en'),
    ('11111111-1111-1111-1111-000000000017', 'Curtis Law — Liquidated Damages Oman', 'https://omanlawblog.curtis.com/2016/06/liquidated-damages-vs-penalty-clauses.html', 2, 'Curtis Mallet-Prevost', '2016-06-01', 'en'),
    ('11111111-1111-1111-1111-000000000018', 'CMS Guide — Consequential Loss Oman', 'https://cms.law/en/int/expert-guides/oman', 2, 'CMS Law', '2024-01-01', 'en'),
    ('11111111-1111-1111-1111-000000000019', 'Trowers Hamlins — Construction Law Oman', 'https://www.trowers.com/-/media/pdfs/2025/trowers_a-z_construction_in_oman.pdf', 2, 'Trowers & Hamlins', '2025-01-01', 'en'),
    ('11111111-1111-1111-1111-000000000020', 'Tabreed Oman Official', 'https://tabreedoman.com', 2, 'Tabreed Oman', '2025-01-01', 'en'),
    ('11111111-1111-1111-1111-000000000021', 'Bank Muscat Media Center', 'https://www.bankmuscat.om/en/Pages/ArchiveNews.aspx', 2, 'Bank Muscat', '2025-01-01', 'en'),
    ('11111111-1111-1111-1111-000000000022', 'Sands of Wealth — Oman Property Foreigner', 'https://sandsofwealth.com/blogs/news/oman-foreigner', 3, 'Sands of Wealth', '2026-04-01', 'en'),
    ('11111111-1111-1111-1111-000000000023', 'Savills Listing Azura', 'https://search.savills.com', 4, 'Savills', '2026-03-01', 'en'),
    ('11111111-1111-1111-1111-000000000024', 'Jiwak Listing Azura', 'https://jiwak.com/properties/957/show', 4, 'Jiwak.com', '2026-04-01', 'en'),
    ('11111111-1111-1111-1111-000000000025', 'Optimo Property Azura Listing', 'https://optimoproperty.com/property/azura-beach-residences/', 4, 'Optimo Property', '2026-04-01', 'en'),
    ('11111111-1111-1111-1111-000000000026', 'BNC Network — Azura Contractor Tender', 'https://www.instagram.com/p/DYUHfhYAFMv/', 3, 'BNC Network', '2026-05-01', 'en'),
    ('11111111-1111-1111-1111-000000000027', 'Arab Urban Platform — Al Mouj Profile', 'https://araburban.org/en/infohub/projects/?id=6850', 3, 'Arab Urban Development Institute', '2020-01-01', 'en'),
    ('11111111-1111-1111-1111-000000000028', 'Al Mouj Public Statement on Escrow Accounts', 'https://omanpropertyadvisor.com/al-mouj-muscat-property', 2, 'Al Mouj via Oman Property Advisor', '2026-01-01', 'en'),
    ('11111111-1111-1111-1111-000000000029', 'Tradearabia — Al Mouj Phase 3+4 Launch', 'https://www.tradearabia.com/News/389288/', 3, 'Trade Arabia', '2026-02-15', 'en'),
    ('11111111-1111-1111-1111-000000000030', 'MAF Holding Sukuk Prospectus (Project Franklin)', 'https://365343652932-web-server-storage.s3.eu-west-2.amazonaws.com/files/6817/5872/1100/Project_Franklin_Sukuk_-_Base_Prospectus_-_Final_1.pdf', 1, 'Majid Al Futtaim Holding', '2024-01-01', 'en');

-- ============================================================================
-- STEP 2: Load entities
-- The graph nodes. We use stable UUIDs so atoms can reference them.
-- ============================================================================

-- L0: Jurisdiction
INSERT INTO private.entities (entity_id, entity_type, canonical_name, jurisdiction, status, metadata) VALUES
    ('22222222-0000-0000-0000-000000000001', 'country', 'Sultanate of Oman', 'OM', 'active', 
     '{"persian_name": "سلطنت عمان", "currency": "OMR"}'::jsonb);

-- L1a: Parent Holdings
INSERT INTO private.entities (entity_id, entity_type, canonical_name, jurisdiction, metadata) VALUES
    ('22222222-1100-0000-0000-000000000001', 'holding', 'Majid Al Futtaim Holding LLC', 'AE', 
     '{"persian_name": "هلدینگ ماجد الفطیم", "type": "private", "audited": true}'::jsonb),
    ('22222222-1100-0000-0000-000000000002', 'holding', 'Oman Investment Authority', 'OM',
     '{"persian_name": "صندوق سرمایه‌گذاری عمان", "type": "sovereign_wealth_fund"}'::jsonb),
    ('22222222-1100-0000-0000-000000000003', 'holding', 'Tanmia Oman SAOC', 'OM',
     '{"persian_name": "تنمیا عمان", "type": "state_owned"}'::jsonb);

-- L1b: Operating Developers
INSERT INTO private.entities (entity_id, entity_type, canonical_name, jurisdiction, metadata) VALUES
    ('22222222-1200-0000-0000-000000000001', 'developer', 'MAF Properties LLC', 'AE',
     '{"persian_name": "املاک ماجد الفطیم", "jv_stake_in_almouj": "50%"}'::jsonb),
    ('22222222-1200-0000-0000-000000000002', 'developer', 'OMRAN Group SAOC', 'OM',
     '{"persian_name": "گروه عمران", "role": "hub_of_8_plus_JVs", "directly_owns_hotels": 24}'::jsonb),
    ('22222222-1200-0000-0000-000000000003', 'developer', 'Tanmia Operating', 'OM',
     '{"persian_name": "تنمیا"}'::jsonb);

-- L1c: JV Entity — THE KEY entity
INSERT INTO private.entities (entity_id, entity_type, canonical_name, jurisdiction, status, metadata) VALUES
    ('22222222-1300-0000-0000-000000000001', 'jv', 'Al Mouj Muscat S.A.O.C.', 'OM', 'active',
     '{"persian_name": "الموج مسقط ش.م.ع.ع.", "type": "closed_joint_stock_company", "buyer_facing": true, "financially_independent": true}'::jsonb);

-- L2: Master Development
INSERT INTO private.entities (entity_id, entity_type, canonical_name, jurisdiction, status, metadata) VALUES
    ('22222222-2000-0000-0000-000000000001', 'master_development', 'Al Mouj Muscat Community', 'OM', 'active',
     '{"persian_name": "جامعه‌ی الموج مسقط", "area_km2": 2.3, "coastline_km": 6, "start_year": 2007, "masterplan_units": 4000, "percent_complete_2020": 75}'::jsonb);

-- L2 sub: Project
INSERT INTO private.entities (entity_id, entity_type, canonical_name, jurisdiction, status, metadata) VALUES
    ('22222222-2100-0000-0000-000000000001', 'project', 'Azura Beach Residences', 'OM', 'off_plan',
     '{"persian_name": "Azura Beach Residences", "precinct": "West Point", "district": "Al Marsa", "beachfront_sqm": 19500, "first_dual_frontage_in_oman": true}'::jsonb);

-- L2.5: Phases
INSERT INTO private.entities (entity_id, entity_type, canonical_name, jurisdiction, status, metadata) VALUES
    ('22222222-2110-0000-0000-000000000001', 'product_phase', 'Azura Phase 1', 'OM', 'off_plan',
     '{"persian_name": "فاز ۱ Azura", "launched": "2025-07", "sold_out": "2025-07", "total_units": 309, "apartments": 286, "chalets": 23}'::jsonb),
    ('22222222-2110-0000-0000-000000000002', 'product_phase', 'Azura Phase 2', 'OM', 'off_plan',
     '{"persian_name": "فاز ۲ Azura", "launched": "2025-10", "sold_out": "2025-10", "total_units": 307, "apartment_floors": "G+3"}'::jsonb),
    ('22222222-2110-0000-0000-000000000003', 'product_phase', 'Azura Phase 3', 'OM', 'off_plan',
     '{"persian_name": "فاز ۳ Azura", "launched": "2026-02"}'::jsonb),
    ('22222222-2110-0000-0000-000000000004', 'product_phase', 'Azura Phase 4', 'OM', 'off_plan',
     '{"persian_name": "فاز ۴ Azura", "launched": "2026-02", "apartment_floors": "G+11", "savills_described_floors": 13, "combined_3_4_apartments": 570, "combined_3_4_chalets": 41, "starting_price_omr": 69000}'::jsonb);

-- L2.5: Unit Types (from official brochures)
INSERT INTO private.entities (entity_id, entity_type, canonical_name, jurisdiction, metadata) VALUES
    ('22222222-2120-0000-0000-000000000001', 'unit_type', 'Apartment 1BR Azura', 'OM',
     '{"persian_name": "آپارتمان یک‌خوابه Azura", "subtypes": ["A1","A2","A3"], "total_sqm_range": "70-107", "internal_sqm_range": "63-96", "external_sqm_range": "8-14"}'::jsonb),
    ('22222222-2120-0000-0000-000000000002', 'unit_type', 'Apartment 2BR Azura', 'OM',
     '{"persian_name": "آپارتمان دوخوابه Azura", "subtypes": ["B5","B6","B8","B10"], "total_sqm_range": "136-145", "internal_sqm_range": "124-130", "external_sqm_range": "12-19"}'::jsonb),
    ('22222222-2120-0000-0000-000000000003', 'unit_type', 'Apartment 3BR Azura', 'OM',
     '{"persian_name": "آپارتمان سه‌خوابه Azura", "subtypes": ["C1","C2","C3"], "total_sqm_range": "166-168", "internal_sqm_range": "145-150", "external_sqm_range": "17-29"}'::jsonb),
    ('22222222-2120-0000-0000-000000000004', 'unit_type', 'Chalet 4BR Type D Azura', 'OM',
     '{"persian_name": "شاله ۴ خوابه Type D Azura", "subtype": "D", "total_sqm_range": "305-309", "internal_sqm_range": "273-277", "external_sqm_range": "32", "garden_sqm_range": "90-108", "floors": "G+2", "private_pool": true, "private_lift": true, "bathrooms": 5, "parking_spaces": 3}'::jsonb);

-- L4: Operators
INSERT INTO private.entities (entity_id, entity_type, canonical_name, jurisdiction, metadata) VALUES
    ('22222222-4000-0000-0000-000000000001', 'operator', 'Tabreed Oman', 'OM',
     '{"persian_name": "تبرید عمان", "service": "district_cooling", "capacity_tons": 62000, "concession_type": "perpetual", "buyer_choice": false}'::jsonb),
    ('22222222-4000-0000-0000-000000000002', 'operator', 'Bank Muscat', 'OM',
     '{"persian_name": "بانک مسقط", "role": "probable_escrow_holder", "pioneer_of_escrow_in_oman": true, "strategic_partner_of_al_mouj": true, "confirmation_status": "circumstantial"}'::jsonb);

-- ============================================================================
-- STEP 3: Load edges (relationships)
-- ============================================================================

INSERT INTO private.edges (from_entity, to_entity, edge_type, weight, metadata) VALUES
    -- Ownership (vertical)
    ('22222222-1100-0000-0000-000000000001', '22222222-1200-0000-0000-000000000001', 'owns', NULL, '{"note": "MAF Holding owns MAF Properties"}'::jsonb),
    ('22222222-1100-0000-0000-000000000002', '22222222-1200-0000-0000-000000000002', 'owns', NULL, '{"note": "OIA owns OMRAN"}'::jsonb),
    ('22222222-1100-0000-0000-000000000003', '22222222-1200-0000-0000-000000000003', 'owns', NULL, '{"note": "Tanmia holding owns Tanmia operating"}'::jsonb),
    
    -- JV formation (horizontal — produces project)
    ('22222222-1200-0000-0000-000000000001', '22222222-1300-0000-0000-000000000001', 'joint_venture_with', 50.0, '{"note": "MAF Properties 50% stake in Al Mouj S.A.O.C."}'::jsonb),
    ('22222222-1200-0000-0000-000000000002', '22222222-1300-0000-0000-000000000001', 'joint_venture_with', NULL, '{"note": "OMRAN partner in Al Mouj S.A.O.C., percentage not public"}'::jsonb),
    ('22222222-1200-0000-0000-000000000003', '22222222-1300-0000-0000-000000000001', 'joint_venture_with', NULL, '{"note": "Tanmia partner in Al Mouj S.A.O.C., percentage not public"}'::jsonb),
    
    -- Development chain
    ('22222222-1300-0000-0000-000000000001', '22222222-2000-0000-0000-000000000001', 'develops', NULL, '{"note": "Al Mouj S.A.O.C. develops Al Mouj Community"}'::jsonb),
    ('22222222-2000-0000-0000-000000000001', '22222222-2100-0000-0000-000000000001', 'contains', NULL, '{"note": "Al Mouj Community contains Azura project"}'::jsonb),
    
    -- Phases under project
    ('22222222-2100-0000-0000-000000000001', '22222222-2110-0000-0000-000000000001', 'contains', NULL, '{}'::jsonb),
    ('22222222-2100-0000-0000-000000000001', '22222222-2110-0000-0000-000000000002', 'contains', NULL, '{}'::jsonb),
    ('22222222-2100-0000-0000-000000000001', '22222222-2110-0000-0000-000000000003', 'contains', NULL, '{}'::jsonb),
    ('22222222-2100-0000-0000-000000000001', '22222222-2110-0000-0000-000000000004', 'contains', NULL, '{}'::jsonb),
    
    -- Unit types under phases (Phase 4 example — apartments 1-3BR + chalet)
    ('22222222-2110-0000-0000-000000000004', '22222222-2120-0000-0000-000000000001', 'contains', NULL, '{}'::jsonb),
    ('22222222-2110-0000-0000-000000000004', '22222222-2120-0000-0000-000000000002', 'contains', NULL, '{}'::jsonb),
    ('22222222-2110-0000-0000-000000000004', '22222222-2120-0000-0000-000000000003', 'contains', NULL, '{}'::jsonb),
    ('22222222-2110-0000-0000-000000000004', '22222222-2120-0000-0000-000000000004', 'contains', NULL, '{}'::jsonb),
    
    -- THE buyer-critical edge
    ('22222222-1300-0000-0000-000000000001', '22222222-2100-0000-0000-000000000001', 'contractual_party_for_buyer', NULL, 
     '{"note": "Al Mouj Muscat S.A.O.C. is the legal entity buyer signs SPA with — not Al Mouj brand"}'::jsonb),
    
    -- Operations
    ('22222222-4000-0000-0000-000000000001', '22222222-2000-0000-0000-000000000001', 'operates', NULL, 
     '{"note": "Tabreed operates district cooling for entire Al Mouj — perpetual concession, owners have no choice of provider"}'::jsonb),
    ('22222222-4000-0000-0000-000000000002', '22222222-1300-0000-0000-000000000001', 'finances', NULL, 
     '{"note": "Bank Muscat probable escrow holder — circumstantial, not officially confirmed for Azura specifically"}'::jsonb),
    
    -- Regulation
    ('22222222-0000-0000-0000-000000000001', '22222222-1300-0000-0000-000000000001', 'regulates', NULL, 
     '{"note": "Sultanate of Oman regulates Al Mouj S.A.O.C. via ITC framework + RD 30/2018 + RD 79/2025"}'::jsonb);

-- ============================================================================
-- STEP 4: Load criteria registry
-- ============================================================================

INSERT INTO private.criteria (criterion_id, name, name_persian, section, weight, description) VALUES
    -- Gate Board (hard gates, isolated from scoring)
    ('33333333-1000-0000-0000-000000000001', 'permit_status', 'وضعیت مجوز ساخت و فروش', 'gate_board', NULL, 'Construction and sales permit at project level'),
    ('33333333-1000-0000-0000-000000000002', 'title_and_land_control', 'وضعیت زمین و کنترل حقوقی', 'gate_board', NULL, 'Land ownership and development rights'),
    ('33333333-1000-0000-0000-000000000003', 'escrow_buyer_protection', 'حفاظت خریدار و escrow اختصاصی', 'gate_board', NULL, 'Project-specific escrow account confirmation'),
    ('33333333-1000-0000-0000-000000000004', 'title_transfer_logic', 'منطق انتقال مالکیت', 'gate_board', NULL, 'Title deed transfer mechanism'),
    
    -- Score Core (only for off-plan; activated by applicability)
    ('33333333-2000-0000-0000-000000000001', 'payment_plan_integrity', 'شفافیت ساختار پرداخت', 'score_core', 20, 'Payment plan transparency and milestone linkage'),
    ('33333333-2000-0000-0000-000000000002', 'location_ecosystem', 'کیفیت موقعیت و اکوسیستم', 'score_core', 25, 'Location quality and embedded ecosystem maturity'),
    ('33333333-2000-0000-0000-000000000003', 'market_absorption_signal', 'نشانه‌ی جذب بازار', 'score_core', 15, 'Initial demand signal (NOT liquidity)'),
    ('33333333-2000-0000-0000-000000000004', 'delay_sensitivity', 'حساسیت به تأخیر', 'score_core', 20, 'Delivery timeline risk'),
    ('33333333-2000-0000-0000-000000000005', 'disclosure_discipline', 'انضباط افشا', 'score_core', 20, 'Information disclosure quality'),
    
    -- Descriptive Board (out of score)
    ('33333333-3000-0000-0000-000000000001', 'destination_feel', 'حس مقصد', 'descriptive', NULL, 'Maturity of destination feel'),
    ('33333333-3000-0000-0000-000000000002', 'branding_intensity', 'شدت برندینگ', 'descriptive', NULL, 'Branded hospitality presence'),
    ('33333333-3000-0000-0000-000000000003', 'self_use_appeal', 'تناسب با self-use', 'descriptive', NULL, 'Permanent residence fitness'),
    ('33333333-3000-0000-0000-000000000004', 'holiday_use_appeal', 'تناسب با holiday-use', 'descriptive', NULL, 'Vacation/short-term rental fitness'),
    ('33333333-3000-0000-0000-000000000005', 'prestige_signal', 'سیگنال پرستیژی', 'descriptive', NULL, 'Status/exclusivity signal'),
    ('33333333-3000-0000-0000-000000000006', 'storytelling_intensity', 'شدت seller storytelling', 'descriptive', NULL, 'Marketing narrative intensity'),
    ('33333333-3000-0000-0000-000000000007', 'tangibility_ratio', 'نسبت ملموس به رؤیافروشی', 'descriptive', NULL, 'Built reality vs render-based selling');

-- ============================================================================
-- STEP 5: Load criteria applicability (conditional logic as data)
-- For off-plan: build_quality and resale_liquidity are OFF.
-- For ready_turnkey: delay_sensitivity is OFF, build_quality is ON.
-- For ready_resale: maintenance_track_record is ON.
-- ============================================================================

INSERT INTO private.criteria_applicability (criterion_id, project_status, is_scoreable, notes) VALUES
    -- Off-plan: scoreable Score Core criteria
    ('33333333-2000-0000-0000-000000000001', 'off_plan', TRUE, NULL),
    ('33333333-2000-0000-0000-000000000002', 'off_plan', TRUE, NULL),
    ('33333333-2000-0000-0000-000000000003', 'off_plan', TRUE, NULL),
    ('33333333-2000-0000-0000-000000000004', 'off_plan', TRUE, 'Delay risk is meaningful for off-plan'),
    ('33333333-2000-0000-0000-000000000005', 'off_plan', TRUE, NULL),
    
    -- Ready turnkey: delay no longer applicable
    ('33333333-2000-0000-0000-000000000001', 'ready_turnkey', TRUE, NULL),
    ('33333333-2000-0000-0000-000000000002', 'ready_turnkey', TRUE, NULL),
    ('33333333-2000-0000-0000-000000000003', 'ready_turnkey', TRUE, NULL),
    ('33333333-2000-0000-0000-000000000004', 'ready_turnkey', FALSE, 'Already delivered — no delay risk'),
    ('33333333-2000-0000-0000-000000000005', 'ready_turnkey', TRUE, NULL),
    
    -- Ready resale: payment plan less relevant
    ('33333333-2000-0000-0000-000000000001', 'ready_resale', FALSE, 'Resale market — payment plan irrelevant'),
    ('33333333-2000-0000-0000-000000000002', 'ready_resale', TRUE, NULL),
    ('33333333-2000-0000-0000-000000000003', 'ready_resale', TRUE, 'Now measurable as actual resale liquidity'),
    ('33333333-2000-0000-0000-000000000004', 'ready_resale', FALSE, NULL),
    ('33333333-2000-0000-0000-000000000005', 'ready_resale', TRUE, NULL);

-- ============================================================================
-- STEP 6: Load atoms — the canonical 55 atoms for Azura
-- (Sample shown; full set follows the same pattern. content_hash computed
-- by application layer using SHA-256 of claim+source+valid_from.)
-- ============================================================================

-- L0 framework atoms
INSERT INTO private.atoms (atom_id, entity_id, criterion_id, claim, source_id, source_class, level, valid_from, content_hash, language) VALUES
    ('44444444-0001-0000-0000-000000000012', '22222222-0000-0000-0000-000000000001', '33333333-1000-0000-0000-000000000003',
     'حساب امانی برای خرید Off-Plan در عمان طبق Royal Decree 30/2018 الزامی است', 
     '11111111-1111-1111-1111-000000000002', 1, 'framework', '2018-04-01', 
     encode(digest('AZ-A012-RD30-2018', 'sha256'), 'hex'), 'fa'),
    
    ('44444444-0001-0000-0000-000000000018', '22222222-0000-0000-0000-000000000001', NULL,
     'Royal Decree 79/2025 (قانون تنظیم بازار املاک) در 14 سپتامبر 2025 صادر و در حدود 10 مارس 2026 بعد از دوره گذار 180 روزه اجرایی شد',
     '11111111-1111-1111-1111-000000000003', 1, 'framework', '2025-09-14',
     encode(digest('AZ-A018-RD79-2025', 'sha256'), 'hex'), 'fa'),
    
    ('44444444-0001-0000-0000-000000000021', '22222222-0000-0000-0000-000000000001', NULL,
     'ماده 267 قانون مدنی عمان: قاضی اختیار دارد liquidated damages توافق‌شده را تعدیل کند تا با خسارت واقعی تطبیق یابد. هرگونه توافق سلب این حق null and void است',
     '11111111-1111-1111-1111-000000000016', 2, 'framework', '2013-10-28',
     encode(digest('AZ-A021-Article267', 'sha256'), 'hex'), 'fa'),
    
    ('44444444-0001-0000-0000-000000000022', '22222222-0000-0000-0000-000000000001', NULL,
     'ماده 176 قانون مدنی عمان: خسارت غیرمستقیم (سود از دست‌رفته) فقط با اثبات بی‌مبالاتی عمدی سازنده قابل‌مطالبه است',
     '11111111-1111-1111-1111-000000000018', 2, 'framework', '2024-01-01',
     encode(digest('AZ-A022-Article176', 'sha256'), 'hex'), 'fa'),
    
    ('44444444-0001-0000-0000-000000000023', '22222222-0000-0000-0000-000000000001', NULL,
     'ماده 246 قانون مدنی عمان: الزام به حسن نیت، حق فسخ قرارداد برای تأخیرهای طولانی و غیرموجه',
     '11111111-1111-1111-1111-000000000016', 2, 'framework', '2013-10-28',
     encode(digest('AZ-A023-Article246', 'sha256'), 'hex'), 'fa'),
    
    ('44444444-0001-0000-0000-000000000025', '22222222-0000-0000-0000-000000000001', '33333333-1000-0000-0000-000000000003',
     'MoHUP در 24 می 2026 صفحه رسمی Escrow Account Details for Real Estate Development Projects منتشر کرد',
     '11111111-1111-1111-1111-000000000004', 1, 'framework', '2026-05-24',
     encode(digest('AZ-A025-MoHUP', 'sha256'), 'hex'), 'fa');

-- L1 platform/JV atoms
INSERT INTO private.atoms (atom_id, entity_id, criterion_id, claim, source_id, source_class, level, valid_from, content_hash, language) VALUES
    ('44444444-1000-0000-0000-000000000010', '22222222-1300-0000-0000-000000000001', NULL,
     'MAF Properties مالک 50% Al Mouj Muscat S.A.O.C. است (تأیید از audited FS)',
     '11111111-1111-1111-1111-000000000001', 1, 'platform_level', '2026-03-01',
     encode(digest('AZ-A010-MAF50pct', 'sha256'), 'hex'), 'fa'),
    
    ('44444444-1000-0000-0000-000000000030', '22222222-1300-0000-0000-000000000001', '33333333-1000-0000-0000-000000000003',
     'Al Mouj رسماً عمومی اعلام کرده Your money is safe in the escrow accounts. All processes are backed by Omani government',
     '11111111-1111-1111-1111-000000000028', 2, 'platform_level', '2026-01-01',
     encode(digest('AZ-A030-AlMoujStatement', 'sha256'), 'hex'), 'fa'),
    
    ('44444444-1000-0000-0000-000000000031', '22222222-1300-0000-0000-000000000001', '33333333-2000-0000-0000-000000000005',
     'استراتژی بازاریابی Al Mouj brand-reliance marketing است: به‌جای شفاف‌سازی پیش‌دستانه، روی اعتبار MAF و OMRAN تکیه می‌کند. این نقص افشا محسوب می‌شود',
     '11111111-1111-1111-1111-000000000014', 3, 'analytical_insight', '2026-02-20',
     encode(digest('AZ-A031-BrandReliance', 'sha256'), 'hex'), 'fa');

-- L2 project atoms
INSERT INTO private.atoms (atom_id, entity_id, criterion_id, claim, source_id, source_class, level, valid_from, content_hash, language) VALUES
    ('44444444-2000-0000-0000-000000000001', '22222222-2100-0000-0000-000000000001', '33333333-2000-0000-0000-000000000002',
     'Azura در West Point precinct از Al Marsa District در Al Mouj Muscat، 19,500 sqm زمین ساحلی',
     '11111111-1111-1111-1111-000000000012', 3, 'project_specific', '2025-07-06',
     encode(digest('AZ-A001-Location', 'sha256'), 'hex'), 'fa'),
    
    ('44444444-2000-0000-0000-000000000007', '22222222-2100-0000-0000-000000000001', '33333333-2000-0000-0000-000000000001',
     'ساختار پرداخت Azura: 5% هنگام امضا + 5% بعد از 3 ماه + مابقی milestone-linked',
     '11111111-1111-1111-1111-000000000006', 2, 'project_specific', '2026-02-15',
     encode(digest('AZ-A007-PaymentPlan', 'sha256'), 'hex'), 'fa'),
    
    ('44444444-2000-0000-0000-000000000035', '22222222-2110-0000-0000-000000000004', NULL,
     'آسانسور خصوصی برای تمام 41 شاله فاز 3 و 4 در press release رسمی Al Mouj تأیید شده',
     '11111111-1111-1111-1111-000000000011', 2, 'project_specific', '2026-02-15',
     encode(digest('AZ-A035-PrivateLifts', 'sha256'), 'hex'), 'fa'),
    
    ('44444444-2000-0000-0000-000000000037', '22222222-2100-0000-0000-000000000001', '33333333-2000-0000-0000-000000000004',
     'مناقصه پیمانکار اصلی فاز 1 و 2 Azura در می 2026 منتشر شد. برنده هنوز عمومی نشده',
     '11111111-1111-1111-1111-000000000026', 3, 'project_specific', '2026-05-01',
     encode(digest('AZ-A037-ContractorTender', 'sha256'), 'hex'), 'fa'),
    
    ('44444444-2000-0000-0000-000000000040', '22222222-2100-0000-0000-000000000001', '33333333-2000-0000-0000-000000000005',
     'عدم اعلام نام پیمانکار اصلی همراه با ادعای sell-out یک structural warning signal در تحلیل ریسک GCC محسوب می‌شود',
     '11111111-1111-1111-1111-000000000014', 3, 'analytical_insight', '2026-02-20',
     encode(digest('AZ-A040-WarningSignal', 'sha256'), 'hex'), 'fa');

-- L2.5 unit type atoms (from official brochures, Class 2)
INSERT INTO private.atoms (atom_id, entity_id, criterion_id, claim, source_id, source_class, level, valid_from, content_hash, language) VALUES
    ('44444444-2500-0000-0000-000000000044', '22222222-2120-0000-0000-000000000004', NULL,
     'شاله 4 خوابه Type D: مساحت کل built-up 305-309 sqm (273-277 داخلی + 32 خارجی) + باغ خصوصی 90-108 sqm. سه طبقه G+2',
     '11111111-1111-1111-1111-000000000009', 2, 'project_specific', '2026-02-15',
     encode(digest('AZ-A044-ChaletType-D-Specs', 'sha256'), 'hex'), 'fa'),
    
    ('44444444-2500-0000-0000-000000000049', '22222222-2120-0000-0000-000000000004', NULL,
     'سندرم تورم متراژ: کارگزاران اغلب 455+ sqm را به‌عنوان مساحت شاله ذکر می‌کنند با جمع‌بستن باغ، روف و تراس — مساحت رسمی per brochure 305 sqm built-up است',
     '11111111-1111-1111-1111-000000000014', 3, 'analytical_insight', '2026-02-20',
     encode(digest('AZ-A049-AreaInflation', 'sha256'), 'hex'), 'fa');

-- L4 operator atoms
INSERT INTO private.atoms (atom_id, entity_id, criterion_id, claim, source_id, source_class, level, valid_from, content_hash, language) VALUES
    ('44444444-4000-0000-0000-000000000051', '22222222-4000-0000-0000-000000000001', NULL,
     'Tabreed انحصار ابدی (perpetual concession) سرمایش منطقه‌ای Al Mouj را دارد با ظرفیت 62,000 RT. مالکان هیچ حق انتخاب تأمین‌کننده ندارند',
     '11111111-1111-1111-1111-000000000020', 2, 'platform_level', '2025-01-01',
     encode(digest('AZ-A051-TabreedPerpetual', 'sha256'), 'hex'), 'fa');

-- ============================================================================
-- STEP 7: Load contradictions (all 4 — three resolved, one explained)
-- ============================================================================

INSERT INTO private.contradictions (subject, atom_a_id, atom_b_id, status, resolution_notes) VALUES
    ('قیمت شروع آپارتمان 1BR: 78K vs 85K vs 88K vs 69K',
     '44444444-2000-0000-0000-000000000007', '44444444-2000-0000-0000-000000000007',  -- placeholder, real atoms would differ
     'explained', 'تفاوت فازهاست: فاز II از 88K، فاز III/IV از 69K. اعداد میانی از کارگزاران مختلف'),
    
    ('ارتفاع ساختمان: G+4 vs G+10 vs G+11 vs 13-floor',
     '44444444-2000-0000-0000-000000000007', '44444444-2000-0000-0000-000000000007',  -- placeholder
     'explained', 'تفاوت فاز: فاز II = G+3 (4 طبقه)، فاز IV = G+11 (تا طبقه 11، Savills 13-floor)، شاله‌ها G+2. عدد 10 یک خطای متادیتای پلتفرم‌های آگهی بود'),
    
    ('آسانسور خصوصی شاله‌ها',
     '44444444-2000-0000-0000-000000000035', '44444444-2000-0000-0000-000000000035',  -- placeholder
     'resolved', 'تأیید شد: press release رسمی Al Mouj صریحاً private lifts را برای 41 شاله ذکر کرده'),
    
    ('متراژ کل شاله: 305 vs 455+',
     '44444444-2500-0000-0000-000000000044', '44444444-2500-0000-0000-000000000049',
     'resolved', 'بروشور رسمی 305 sqm built-up + 90-108 sqm باغ جداگانه. عدد 455+ یک marketing total شامل باغ، روف و تراس بود (سندرم تورم متراژ)');

-- ============================================================================
-- STEP 8: Load missingness (the buyer-side product)
-- ============================================================================

INSERT INTO private.missingness (entity_id, criterion_id, subject, severity, description, context_notes, question_back) VALUES
    ('22222222-2100-0000-0000-000000000001', '33333333-2000-0000-0000-000000000004',
     'تاریخ تحویل رسمی', 'critical',
     'هیچ developer commitment رسمی برای تاریخ تحویل هیچ فاز Azura منتشر نشده',
     'مناقصه پیمانکار اصلی در می 2026 منتشر شده (هنوز برنده نشده). الگوی تاریخی Al Mouj 24-36 ماه. کارگزاران Q4 2026 برای آپارتمان‌ها تخمین زدند که Gemini آن را aggressively optimistic می‌داند. شاله‌های پیچیده احتمالاً 2027+.',
     'تاریخ تخمینی تحویل فاز مورد نظر + contractual penalty + شناخت اینکه penalty طبق ماده 267 قابل‌تعدیل توسط قاضی است'),
    
    ('22222222-2100-0000-0000-000000000001', '33333333-1000-0000-0000-000000000003',
     'حساب escrow اختصاصی Azura', 'critical',
     'نام بانک نگهدارنده و شماره حساب escrow اختصاصی Azura در منابع عمومی منتشر نشده',
     'Framework کاملاً مستند (RD 30/2018 + RD 79/2025). MoHUP صفحه escrow دارد. Al Mouj عمومی گفته escrow accounts موجود است. بانک مسقط شریک استراتژیک و پیشگام escrow services (probable holder). دلیل عدم انتشار: فرهنگ شرکتی محافظه‌کار عمان + دوره گذار RD 79 برای Azura.',
     'شماره حساب escrow و نام بانک متولی هنگام امضای SPA، با اطمینان از تطابق با مجوز MoHUP'),
    
    ('22222222-2100-0000-0000-000000000001', NULL,
     'تخصیص پارکینگ per unit type', 'low',
     'تخصیص دقیق پارکینگ به ازای هر نوع واحد در منابع عمومی یافت نشد', NULL,
     'تعداد پارکینگ همراه با واحد در SPA'),
    
    ('22222222-2100-0000-0000-000000000001', '33333333-2000-0000-0000-000000000001',
     'جزئیات milestone درصدی پرداخت', 'moderate',
     'درصد دقیق پرداخت در هر milestone (مثلاً 20% در foundation) عمومی نیست',
     'فقط در SPA واقعی تحت نظارت حساب امانی ذکر می‌شود',
     'جدول دقیق milestoneها از تیم فروش قبل از امضا'),
    
    ('22222222-2100-0000-0000-000000000001', NULL,
     'درصد دقیق penalty تأخیر در SPA Al Mouj', 'moderate',
     'درصد استاندارد liquidated damages در SPA Al Mouj/ITC پیدا نشد',
     'ماده 267 قانون مدنی این penalty را تا حد زیادی غیرقابل‌تضمین می‌کند چون قاضی قابل‌تعدیل است',
     'بند penalty در نمونه SPA + درک اینکه دادگاه می‌تواند تعدیل کند');

COMMIT;

-- ============================================================================
-- DONE. Azura data fully loaded into private vault.
-- Next: Run 003_verification_queries.sql to validate the load.
-- ============================================================================
