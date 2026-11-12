from pathlib import Path

from document_intelligence import SmartDocumentIntelligence
from document_quality_analyzer import analyze_document_quality


def print_line():
    print("=" * 60)


def main():
    print_line()
    print("DISHARI - SMART DOCUMENT INTELLIGENCE")
    print("AI Research Prototype")
    print_line()

    base_path = Path(__file__).parent
    training_file = base_path / "sample_documents.json"

    # Initialize and train AI model
    ai = SmartDocumentIntelligence()

    print("\nTraining AI document classification model...")
    ai.train_from_file(str(training_file))

    print("AI model trained successfully!")

    # Sample document text
    document_text = """
    People's Republic of Bangladesh
    National ID

    Name: Sample Citizen
    Date of Birth: 01 January 2000
    NID Number: 1234567890
    Address: Dhaka, Bangladesh
    """

    print("\nAnalyzing document...")

    # AI classification
    ai_result = ai.analyze_document(document_text)

    # Quality analysis
    quality_result = analyze_document_quality(
        document_text,
        ai_result["predicted_type"]
    )

    print_line()
    print("AI ANALYSIS RESULT")
    print_line()

    print(
        f"Predicted Document Type: "
        f"{ai_result['predicted_type']}"
    )

    print(
        f"AI Confidence: "
        f"{ai_result['confidence']}%"
    )

    print(
        f"Document Completeness: "
        f"{quality_result['completeness_score']}%"
    )

    print("\nDetected Information:")

    for field in quality_result["found_fields"]:
        print(f"  ✓ {field}")

    if quality_result["missing_fields"]:
        print("\nMissing Information:")

        for field in quality_result["missing_fields"]:
            print(f"  ✗ {field}")

    print("\nSmart Recommendations:")

    for recommendation in quality_result["recommendations"]:
        print(f"  • {recommendation}")

    print_line()
    print(
        "Note: This is a standalone Python AI research "
        "prototype and does not run inside the Flutter app."
    )
    print_line()


if __name__ == "__main__":
    main()