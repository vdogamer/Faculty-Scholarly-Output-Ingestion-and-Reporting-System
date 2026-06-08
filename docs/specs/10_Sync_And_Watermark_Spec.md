Two sync modes:
    Mode 1: Full author refresh
    - Pull all works for a verified author.
    - Upsert by OpenAlexWorkId.
    - Compare RawJsonHash and OpenAlexUpdatedDate.
    - Safe for prototype.

    Mode 2: Incremental update
    - Use from_updated_date only if OpenAlex plan supports it.
    - Store per-author watermark.
    - Use overlap window.