DOCUMENT_REQUIREMENTS = {
    "National ID": [
        "name",
        "date of birth",
        "nid",
        "address"
    ],
    "Birth Certificate": [
        "name",
        "date of birth",
        "registration",
        "father",
        "mother"
    ],
    "Passport": [
        "passport",
        "name",
        "nationality",
        "date of birth"
    ],
    "Academic Certificate": [
        "student",
        "roll",
        "registration",
        "degree"
    ]
}


def analyze_document_quality(document_text: str,
                             document_type: str) -> dict:
    """
    Checks whether important fields appear to exist
    in the document text.
    """

    text = document_text.lower()

    required_fields = DOCUMENT_REQUIREMENTS.get(
        document_type,
        []
    )

    found_fields = []
    missing_fields = []

    for field in required_fields:
        if field.lower() in text:
            found_fields.append(field)
        else:
            missing_fields.append(field)

    total_fields = len(required_fields)

    if total_fields == 0:
        completeness_score = 0
    else:
        completeness_score = (
            len(found_fields) / total_fields
        ) * 100

    recommendations = []

    if completeness_score == 100:
        recommendations.append(
            "Document appears complete."
        )
    else:
        recommendations.append(
            "Some important information may be missing."
        )

    for field in missing_fields:
        recommendations.append(
            f"Please verify: {field}"
        )

    return {
        "document_type": document_type,
        "completeness_score": round(
            completeness_score, 2
        ),
        "found_fields": found_fields,
        "missing_fields": missing_fields,
        "recommendations": recommendations
    }