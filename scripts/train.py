import os
import joblib
from sklearn.datasets import make_classification
from sklearn.linear_model import LogisticRegression

print("Generating dummy dataset...")
X, y = make_classification(n_samples=100, n_features=4, random_state=42)

print("Training model...")
clf = LogisticRegression()
clf.fit(X, y)

output_dir = "/mnt/data"
os.makedirs(output_dir, exist_ok=True)
output_path = os.path.join(output_dir, "model.pkl")

print(f"Saving model to {output_path}...")
joblib.dump(clf, output_path)
print("Done.")
