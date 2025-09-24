from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
import os
from model.video_analysis import analyze_video_file  # we'll create this

app = FastAPI()

# Make sure videos folder exists
os.makedirs("videos", exist_ok=True)

@app.post("/analyze_video")
async def analyze_video(file: UploadFile = File(...)):
    # Save uploaded video
    video_path = f"videos/{file.filename}"
    with open(video_path, "wb") as f:
        f.write(await file.read())

    # Run ML analysis
    situp_count, jump_height_cm, anomaly_detected = analyze_video_file(video_path)

    return JSONResponse({
        "situp_count": situp_count,
        "jump_height_cm": jump_height_cm,
        "anomaly_detected": anomaly_detected
    })
