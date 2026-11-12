import json
from pathlib import Path

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression


class SmartDocumentIntelligence:
    """
    AI prototype for classifying citizen documents.

    Uses TF-IDF + Logistic Regression to identify
    the likely type of a document from extracted text.
    """

    def __init__(self):
        self.vectorizer = TfidfVectorizer(
            lowercase=True,
            stop_words="english",
            ngram_range=(1, 2)
        )

        self.model = LogisticRegression(max_iter=1000)
        self.is_trained = False

    def train_from_file(self, file_path: str):
        """Load sample documents and train the ML model."""

        path = Path(file_path)

        if not path.exists():
            raise FileNotFoundError(
                f"Training data not found: {file_path}"
            )

        with open(path, "r", encoding="utf-8") as file:
            documents = json.load(file)

        texts = [item["text"] for item in documents]
        labels = [item["type"] for item in documents]

        features = self.vectorizer.fit_transform(texts)
        self.model.fit(features, labels)

        self.is_trained = True

    def analyze_document(self, document_text: str) -> dict:
        """
        Predict document type and return confidence.
        """

        if not self.is_trained:
            raise RuntimeError(
                "AI model is not trained. "
                "Call train_from_file() first."
            )

        features = self.vectorizer.transform([document_text])

        prediction = self.model.predict(features)[0]
        probabilities = self.model.predict_proba(features)[0]

        confidence = float(max(probabilities) * 100)

        return {
            "predicted_type": prediction,
            "confidence": round(confidence, 2)
        }