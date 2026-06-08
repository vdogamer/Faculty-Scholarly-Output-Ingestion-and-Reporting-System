Purpose:
    Normalize OpenAlex Topics and Keywords separately.

Tables:
    OpenAlexTopic
    OpenAlexWorkTopic
    OpenAlexKeyword
    OpenAlexWorkKeyword 

Rules:
    - Topics represent OpenAlex research classifications.
    - Keywords are short phrases associated with works.
    - Both are many-to-many relationships with works.
    - Do not store topic1/topic2/keyword1/keyword2 columns in OpenAlexWork.

Acceptance Criteria:
    - A work can have multiple topics.
    - A work can have multiple keywords.
    - Topics and keywords can be reported by department.
    - Duplicate topic/keyword rows are prevented.