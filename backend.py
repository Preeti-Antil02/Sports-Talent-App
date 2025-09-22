# backend.py
from fastapi import FastAPI
from fastapi.responses import JSONResponse
import cv2
import mediapipe as mp
import threading
from math import atan2, degrees

# -------------------------
# Import functions from model/utils.py
# -------------------------
from model.utils import calculate_angle, check_anomaly

# -------------------------
# FastAPI app
# -------------------------
app = FastAPI()

# -------------------------
# MediaPipe setup
# -------------------------
mp_pose = mp.solutions.pose
pose = mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5)

# -------------------------
# Global metrics
# -------------------------
metrics = {
    "situp_count": 0,
    "jump_height_cm": 0.0,
    "anomaly_detected": False
}

# -------------------------
# Webcam processing function
# -------------------------
def process_webcam():
    global metrics
    cap = cv2.VideoCapture(0)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)

    # Sit-up variables
    situp_count = 0
    situp_stage = None
    down_frames = 0
    up_frames = 0

    # Jump variables
    jump_stage = "down"
    min_hip_y = None
    max_hip_y = None
    jump_height = None
    initial_hip_ankle_pixel = 100  # Example: adjust to your setup
    USER_HIP_TO_ANKLE_CM = 90

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        frame_h, frame_w, _ = frame.shape
        image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(image_rgb)

        features = {}

        if results.pose_landmarks:
            lm = results.pose_landmarks.landmark

            def get_coords(idx):
                l = lm[idx]
                return (l.x, l.y)

            left_hip = get_coords(mp_pose.PoseLandmark.LEFT_HIP.value)
            left_knee = get_coords(mp_pose.PoseLandmark.LEFT_KNEE.value)
            left_ankle = get_coords(mp_pose.PoseLandmark.LEFT_ANKLE.value)
            right_hip = get_coords(mp_pose.PoseLandmark.RIGHT_HIP.value)
            right_knee = get_coords(mp_pose.PoseLandmark.RIGHT_KNEE.value)
            right_ankle = get_coords(mp_pose.PoseLandmark.RIGHT_ANKLE.value)

            # -------------------------
            # Calculate knee angles
            # -------------------------
            features['left_knee_angle'] = calculate_angle(left_hip, left_knee, left_ankle)
            features['right_knee_angle'] = calculate_angle(right_hip, right_knee, right_ankle)

            # -------------------------
            # Anomaly detection
            # -------------------------
            is_anomaly = check_anomaly(features)
            metrics['anomaly_detected'] = is_anomaly

            # -------------------------
            # Sit-up detection (simplified)
            # -------------------------
            left_shoulder = get_coords(mp_pose.PoseLandmark.LEFT_SHOULDER.value)
            right_shoulder = get_coords(mp_pose.PoseLandmark.RIGHT_SHOULDER.value)

            left_torso_angle = calculate_angle(left_shoulder, left_hip, left_knee)
            right_torso_angle = calculate_angle(right_shoulder, right_hip, right_knee)
            torso_angle = (left_torso_angle + right_torso_angle)/2

            down_thresh = 150
            up_thresh = 90

            if torso_angle > down_thresh:
                down_frames += 1
                up_frames = 0
                if down_frames >= 3:
                    situp_stage = "down"
            elif torso_angle < up_thresh and situp_stage == "down":
                up_frames += 1
                down_frames = 0
                if up_frames >= 3:
                    situp_stage = "up"
                    situp_count += 1
            else:
                down_frames = 0
                up_frames = 0

            metrics['situp_count'] = situp_count

            # -------------------------
            # Jump detection (simplified)
            # -------------------------
            hip_y = (left_hip[1] + right_hip[1]) / 2
            hip_y_pixel = int(hip_y * frame_h)

            if min_hip_y is None or max_hip_y is None:
                min_hip_y = hip_y_pixel
                max_hip_y = hip_y_pixel

            jump_thresh = int(0.2 * initial_hip_ankle_pixel)

            if jump_stage == "down":
                if hip_y_pixel > max_hip_y:
                    max_hip_y = hip_y_pixel
                min_hip_y = hip_y_pixel
                if (max_hip_y - hip_y_pixel) > jump_thresh:
                    jump_stage = "up"
                    min_hip_y = hip_y_pixel
            elif jump_stage == "up":
                if hip_y_pixel < min_hip_y:
                    min_hip_y = hip_y_pixel
                if (max_hip_y - hip_y_pixel) < (jump_thresh * 0.3):
                    jump_height = max_hip_y - min_hip_y
                    jump_stage = "down"
                    min_hip_y = hip_y_pixel
                    max_hip_y = hip_y_pixel

            if jump_height is not None:
                metrics['jump_height_cm'] = jump_height * (USER_HIP_TO_ANKLE_CM / initial_hip_ankle_pixel)

# -------------------------
# Start webcam in background thread
# -------------------------
threading.Thread(target=process_webcam, daemon=True).start()

# -------------------------
# Endpoint to get live metrics
# -------------------------
@app.get("/metrics")
def get_metrics():
    return JSONResponse(content=metrics)
