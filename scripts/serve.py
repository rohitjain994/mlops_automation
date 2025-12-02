import os
import joblib
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import numpy as np
import uvicorn
from typing import List

app = FastAPI()
MODEL_PATH = "/mnt/data/model.pkl"

print(f"Loading model from {MODEL_PATH}...")
try:
    model = joblib.load(MODEL_PATH)
    print("Model loaded successfully.")
except Exception as e:
    print(f"Error loading model: {e}")
    model = None

class PredictionRequest(BaseModel):
    features: List[float]

@app.post("/predict")
def predict(request: PredictionRequest):
    if not model:
        raise HTTPException(status_code=500, detail="Model not loaded")
    
    try:
        features = np.array(request.features).reshape(1, -1)
        prediction = model.predict(features)
        return {"prediction": int(prediction[0])}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": model is not None}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)
