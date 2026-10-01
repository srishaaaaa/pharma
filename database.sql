-- =============================================================================
-- AK PHARMA POS — complete database schema (all migrations 0000–0003 merged)
--
-- Run this once in the Neon SQL Editor to set up a NEW, empty database.
-- Safe to re-run: it skips anything that already exists and never deletes data.
--
-- The current Neon database is already set up, so you do NOT need to run this
-- there. Sample medicines, customers and suppliers are not included; load
-- those with:  npx tsx scripts/seed.ts
-- =============================================================================

-- Counters used for bill numbers (1, 2, 3 …) and customer IDs (AKP000001 …)
CREATE SEQUENCE IF NOT EXISTS "public"."bill_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1;
CREATE SEQUENCE IF NOT EXISTS "public"."customer_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1;

-- Tables
CREATE TABLE IF NOT EXISTS "batches" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"medicine_id" uuid NOT NULL,
	"supplier_id" uuid,
	"brand_name" text DEFAULT '' NOT NULL,
	"manufacturer" text DEFAULT '' NOT NULL,
	"invoice_no" text DEFAULT '' NOT NULL,
	"purchase_date" date NOT NULL,
	"batch_no" text NOT NULL,
	"mfg_date" text DEFAULT '' NOT NULL,
	"exp_date" text DEFAULT '' NOT NULL,
	"box" text DEFAULT '' NOT NULL,
	"purchase_unit_type" text NOT NULL,
	"pack_size" integer DEFAULT 1 NOT NULL,
	"qty_packs" integer DEFAULT 0 NOT NULL,
	"stock_added" integer DEFAULT 0 NOT NULL,
	"stock_qty" integer DEFAULT 0 NOT NULL,
	"purchase_rate" numeric(12, 2) DEFAULT '0' NOT NULL,
	"mrp" numeric(12, 2) DEFAULT '0' NOT NULL,
	"selling_price" numeric(12, 2) DEFAULT '0' NOT NULL,
	"gst_percent" numeric(5, 2) DEFAULT '0' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "bill_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"bill_id" text NOT NULL,
	"medicine_id" uuid,
	"batch_id" uuid,
	"generic_name" text NOT NULL,
	"brand_name" text DEFAULT '' NOT NULL,
	"manufacturer" text DEFAULT '' NOT NULL,
	"schedule" text NOT NULL,
	"hsn_code" text DEFAULT '' NOT NULL,
	"batch_no" text DEFAULT '' NOT NULL,
	"mfg_date" text DEFAULT '' NOT NULL,
	"exp_date" text DEFAULT '' NOT NULL,
	"box" text DEFAULT '' NOT NULL,
	"purchase_unit_type" text NOT NULL,
	"pack_size" integer DEFAULT 1 NOT NULL,
	"qty" integer NOT NULL,
	"mrp_per_unit" numeric(12, 2) NOT NULL,
	"per_unit_price" numeric(12, 2) NOT NULL,
	"line_mrp" numeric(12, 2) NOT NULL,
	"line_amount" numeric(12, 2) NOT NULL,
	"line_discount" numeric(12, 2) NOT NULL,
	"gst_percent" numeric(5, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS "bills" (
	"id" text PRIMARY KEY NOT NULL,
	"customer_id" text,
	"customer_name" text DEFAULT '' NOT NULL,
	"customer_phone" text DEFAULT '' NOT NULL,
	"customer_address" text DEFAULT '' NOT NULL,
	"doctor_name" text DEFAULT '' NOT NULL,
	"bill_date" date NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"sub_total" numeric(12, 2) NOT NULL,
	"discount" numeric(12, 2) NOT NULL,
	"taxable_amount" numeric(12, 2) NOT NULL,
	"gst_amount" numeric(12, 2) NOT NULL,
	"gst_percent" numeric(5, 2) NOT NULL,
	"grand_total" numeric(12, 2) NOT NULL,
	"received_amount" numeric(12, 2) DEFAULT '0' NOT NULL,
	"change_amount" numeric(12, 2) DEFAULT '0' NOT NULL,
	"payment_method" text NOT NULL,
	"status" text DEFAULT 'COMPLETED' NOT NULL
);

CREATE TABLE IF NOT EXISTS "customers" (
	"id" text PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"phone" text DEFAULT '' NOT NULL,
	"address" text DEFAULT '' NOT NULL,
	"doctor_name" text DEFAULT '' NOT NULL,
	"quick_bill" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "medicines" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"generic_name" text NOT NULL,
	"brand_name" text DEFAULT '' NOT NULL,
	"manufacturer" text DEFAULT '' NOT NULL,
	"salt" text DEFAULT '' NOT NULL,
	"schedule" text NOT NULL,
	"hsn_code" text DEFAULT '' NOT NULL,
	"gst_percent" numeric(5, 2) DEFAULT '0' NOT NULL,
	"purchase_unit_type" text NOT NULL,
	"low_stock_threshold" integer DEFAULT 20 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "settings" (
	"id" integer PRIMARY KEY DEFAULT 1 NOT NULL,
	"shop_name" text NOT NULL,
	"full_name" text DEFAULT '' NOT NULL,
	"address" text NOT NULL,
	"phone" text NOT NULL,
	"shop_contact_number" text DEFAULT '' NOT NULL,
	"email" text DEFAULT '' NOT NULL,
	"gstin" text NOT NULL,
	"dl_no" text NOT NULL,
	"colour_theme" text DEFAULT 'green' NOT NULL,
	"logo" text DEFAULT '' NOT NULL,
	"instagram_id" text DEFAULT '' NOT NULL,
	"default_gst" numeric(5, 2) DEFAULT '12' NOT NULL,
	"low_stock_threshold" integer DEFAULT 20 NOT NULL,
	"expiry_alert_months" integer DEFAULT 6 NOT NULL
);

CREATE TABLE IF NOT EXISTS "suppliers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"phone" text DEFAULT '' NOT NULL,
	"gstin" text DEFAULT '' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);

-- Links between tables (added only if missing)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'batches_medicine_id_medicines_id_fk') THEN
    ALTER TABLE "batches" ADD CONSTRAINT "batches_medicine_id_medicines_id_fk" FOREIGN KEY ("medicine_id") REFERENCES "public"."medicines"("id") ON DELETE cascade ON UPDATE no action;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'batches_supplier_id_suppliers_id_fk') THEN
    ALTER TABLE "batches" ADD CONSTRAINT "batches_supplier_id_suppliers_id_fk" FOREIGN KEY ("supplier_id") REFERENCES "public"."suppliers"("id") ON DELETE set null ON UPDATE no action;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'bill_items_bill_id_bills_id_fk') THEN
    ALTER TABLE "bill_items" ADD CONSTRAINT "bill_items_bill_id_bills_id_fk" FOREIGN KEY ("bill_id") REFERENCES "public"."bills"("id") ON DELETE cascade ON UPDATE no action;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'bills_customer_id_customers_id_fk') THEN
    ALTER TABLE "bills" ADD CONSTRAINT "bills_customer_id_customers_id_fk" FOREIGN KEY ("customer_id") REFERENCES "public"."customers"("id") ON DELETE set null ON UPDATE no action;
  END IF;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS "batches_medicine_idx" ON "batches" USING btree ("medicine_id");
CREATE INDEX IF NOT EXISTS "batches_exp_idx" ON "batches" USING btree ("exp_date");
CREATE INDEX IF NOT EXISTS "bill_items_bill_idx" ON "bill_items" USING btree ("bill_id");
CREATE INDEX IF NOT EXISTS "bills_created_idx" ON "bills" USING btree ("created_at");
CREATE INDEX IF NOT EXISTS "bills_customer_idx" ON "bills" USING btree ("customer_id");
CREATE INDEX IF NOT EXISTS "medicines_generic_idx" ON "medicines" USING btree ("generic_name");

-- AK Pharma shop settings (single row, id = 1).
-- GSTIN, DL No., Instagram ID and Shop Contact Number are intentionally
-- empty placeholders until the owner supplies the real values; set them in
-- the app's Settings screen.
INSERT INTO "settings" (
  "id", "shop_name", "full_name", "address", "phone", "shop_contact_number", "email",
  "gstin", "dl_no", "colour_theme", "logo", "instagram_id",
  "default_gst", "low_stock_threshold", "expiry_alert_months"
) VALUES (
  1, 'AK PHARMA', 'Aravinthan A',
  'NO 2 , Venugopalapuram , kill nachipattu post , Tiruvannamalai 606 611',
  '7259103278', '', 'akaravinthan2413@gmail.com',
  '', '', 'teal',
  '/logos/ak-pharma-logo-square.jpeg', '', '12', 20, 6
) ON CONFLICT ("id") DO NOTHING;
