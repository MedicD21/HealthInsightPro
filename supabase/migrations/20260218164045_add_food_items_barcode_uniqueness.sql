-- Deduplicate existing rows by barcode, keeping newest row.
WITH ranked AS (
    SELECT
        id,
        ROW_NUMBER() OVER (
            PARTITION BY barcode
            ORDER BY created_at DESC NULLS LAST, id DESC
        ) AS row_num
    FROM public.food_items
    WHERE barcode IS NOT NULL
)
DELETE FROM public.food_items fi
USING ranked r
WHERE fi.id = r.id
  AND r.row_num > 1;

-- Enforce unique barcode for cached OFF products.
CREATE UNIQUE INDEX IF NOT EXISTS food_items_barcode_unique_idx
    ON public.food_items (barcode)
    WHERE barcode IS NOT NULL;
