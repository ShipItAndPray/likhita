CREATE SCHEMA "likhita";
--> statement-breakpoint
CREATE TABLE "likhita"."devices" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"apns_token" text NOT NULL,
	"app_origin" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "likhita"."entries" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"koti_id" uuid NOT NULL,
	"sequence_number" bigint NOT NULL,
	"committed_at" timestamp with time zone NOT NULL,
	"cadence_signature" text NOT NULL,
	"client_session_id" uuid,
	"flagged" boolean DEFAULT false NOT NULL,
	CONSTRAINT "entries_unique_seq" UNIQUE("koti_id","sequence_number")
);
--> statement-breakpoint
CREATE TABLE "likhita"."idempotency_keys" (
	"koti_id" uuid NOT NULL,
	"key" text NOT NULL,
	"request_hash" text NOT NULL,
	"response_json" jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "idempotency_keys_koti_id_key_pk" PRIMARY KEY("koti_id","key")
);
--> statement-breakpoint
CREATE TABLE "likhita"."koti_ship_batches" (
	"koti_id" uuid NOT NULL,
	"batch_id" uuid NOT NULL,
	"position_in_batch" integer,
	"individual_photo_url" text,
	"individual_receipt_url" text,
	CONSTRAINT "koti_ship_batches_koti_id_batch_id_pk" PRIMARY KEY("koti_id","batch_id")
);
--> statement-breakpoint
CREATE TABLE "likhita"."kotis" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"app_origin" text NOT NULL,
	"tradition_path" text NOT NULL,
	"mantra_string" text NOT NULL,
	"rendered_script" text NOT NULL,
	"input_mode" text DEFAULT 'romanized' NOT NULL,
	"mode" text NOT NULL,
	"target_count" bigint NOT NULL,
	"current_count" bigint DEFAULT 0 NOT NULL,
	"stylus_color" text,
	"stylus_signature_hash" text,
	"theme" text,
	"dedication_text" text,
	"dedication_to" text,
	"started_at" timestamp with time zone DEFAULT now() NOT NULL,
	"completed_at" timestamp with time zone,
	"locked" boolean DEFAULT true NOT NULL,
	"ship_temple" boolean DEFAULT false NOT NULL,
	"temple_destination" text,
	"ship_home" boolean DEFAULT false NOT NULL,
	"shipping_address" jsonb,
	"payment_id" text,
	"printed_at" timestamp with time zone,
	"shipped_at" timestamp with time zone,
	"delivered_at" timestamp with time zone,
	"photo_url" text,
	"receipt_url" text
);
--> statement-breakpoint
CREATE TABLE "likhita"."payments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"koti_id" uuid,
	"provider" text NOT NULL,
	"provider_id" text NOT NULL,
	"amount_cents" integer NOT NULL,
	"currency" text NOT NULL,
	"type" text NOT NULL,
	"status" text DEFAULT 'pending' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "likhita"."ship_batches" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"batch_quarter" text NOT NULL,
	"temple_destination" text NOT NULL,
	"status" text DEFAULT 'pending' NOT NULL,
	"representative_id" uuid,
	"trip_started_at" timestamp with time zone,
	"trip_completed_at" timestamp with time zone,
	"photos_url" text,
	"receipt_url" text
);
--> statement-breakpoint
CREATE TABLE "likhita"."users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"clerk_id" text NOT NULL,
	"name" text NOT NULL,
	"gotra" text,
	"native_place" text,
	"email" text NOT NULL,
	"phone" text,
	"ui_language" text,
	"primary_app" text,
	"linked_apps" text[],
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "users_clerk_id_unique" UNIQUE("clerk_id")
);
--> statement-breakpoint
ALTER TABLE "likhita"."devices" ADD CONSTRAINT "devices_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "likhita"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "likhita"."entries" ADD CONSTRAINT "entries_koti_id_kotis_id_fk" FOREIGN KEY ("koti_id") REFERENCES "likhita"."kotis"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "likhita"."idempotency_keys" ADD CONSTRAINT "idempotency_keys_koti_id_kotis_id_fk" FOREIGN KEY ("koti_id") REFERENCES "likhita"."kotis"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "likhita"."koti_ship_batches" ADD CONSTRAINT "koti_ship_batches_koti_id_kotis_id_fk" FOREIGN KEY ("koti_id") REFERENCES "likhita"."kotis"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "likhita"."koti_ship_batches" ADD CONSTRAINT "koti_ship_batches_batch_id_ship_batches_id_fk" FOREIGN KEY ("batch_id") REFERENCES "likhita"."ship_batches"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "likhita"."kotis" ADD CONSTRAINT "kotis_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "likhita"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "likhita"."payments" ADD CONSTRAINT "payments_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "likhita"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "likhita"."payments" ADD CONSTRAINT "payments_koti_id_kotis_id_fk" FOREIGN KEY ("koti_id") REFERENCES "likhita"."kotis"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "entries_koti_seq" ON "likhita"."entries" USING btree ("koti_id","sequence_number");--> statement-breakpoint
CREATE INDEX "kotis_user" ON "likhita"."kotis" USING btree ("user_id");