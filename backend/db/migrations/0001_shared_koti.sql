CREATE TABLE "likhita"."shared_entries" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"shared_koti_id" uuid NOT NULL,
	"device_id" text NOT NULL,
	"display_name" text,
	"place" text,
	"country" text,
	"cadence_signature" text NOT NULL,
	"flagged" boolean DEFAULT false NOT NULL,
	"committed_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "likhita"."shared_kotis" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"name_local" text NOT NULL,
	"target_count" bigint NOT NULL,
	"current_count" bigint DEFAULT 0 NOT NULL,
	"custodian" text NOT NULL,
	"destination" text NOT NULL,
	"estimated_ship_date" text NOT NULL,
	"started_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "likhita"."shared_entries" ADD CONSTRAINT "shared_entries_shared_koti_id_shared_kotis_id_fk" FOREIGN KEY ("shared_koti_id") REFERENCES "likhita"."shared_kotis"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "shared_entries_koti_ts" ON "likhita"."shared_entries" USING btree ("shared_koti_id","committed_at");--> statement-breakpoint
CREATE INDEX "shared_entries_device" ON "likhita"."shared_entries" USING btree ("device_id");--> statement-breakpoint
CREATE INDEX "shared_entries_country" ON "likhita"."shared_entries" USING btree ("shared_koti_id","country");