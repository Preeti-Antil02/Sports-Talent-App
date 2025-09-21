# sports_metrics_hackathon_final.py
import cv2
import mediapipe as mp
from math import atan2, degrees

# -------------------------
# Helper functions
# -------------------------
def calculate_angle(a, b, c):
    """Calculate angle at point b"""
    ax, ay = a
    bx, by = b
    cx, cy = c
    v1 = (ax - bx, ay - by)
    v2 = (cx - bx, cy - by)
    dot = v1[0]*v2[0] + v1[1]*v2[1]
    mag1 = (v1[0]**2 + v1[1]**2)**0.5
    mag2 = (v2[0]**2 + v2[1]**2)**0.5
    if mag1*mag2 == 0: return 0.0
    angle_rad = atan2(v1[0]*v2[1] - v1[1]*v2[0], dot)
    return abs(degrees(angle_rad))

# -------------------------
# MediaPipe setup
# -------------------------
mp_drawing = mp.solutions.drawing_utils
mp_pose = mp.solutions.pose
pose = mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5)

# -------------------------
# Anomaly thresholds
# -------------------------
rules = {
    "left_knee_angle": (70, 180),
    "right_knee_angle": (70, 180),
    "left_elbow_angle": (30, 170),
    "right_elbow_angle": (30, 170),
}

def check_anomaly(features):
    for key, (low, high) in rules.items():
        if features.get(key, 0) < low or features.get(key, 0) > high:
            return True
    return False

# -------------------------
# Variables
# -------------------------
situp_count = 0
situp_stage = None
jump_stage = "down"
min_hip_y = None
max_hip_y = None
jump_height = 0
first_frame_detected = False

# -------------------------
# Start webcam
# -------------------------
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)

cv2.namedWindow('Sports Metrics & Anomaly', cv2.WINDOW_NORMAL)
cv2.setWindowProperty('Sports Metrics & Anomaly', cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN)

# -------------------------
# Main loop
# -------------------------
while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    image.flags.writeable = False
    results = pose.process(image)
    image.flags.writeable = True
    image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)

    frame_h, frame_w, _ = image.shape
    features = {}

    # -------------------------
    # Draw head & feet guides (frame-relative)
    # -------------------------
    head_top = int(0.05*frame_h)
    head_bottom = int(0.2*frame_h)
    foot_top = int(0.8*frame_h)
    foot_bottom = int(0.95*frame_h)
    cv2.rectangle(image, (int(0.4*frame_w), head_top), (int(0.6*frame_w), head_bottom), (200,200,200), 2)
    cv2.putText(image, "Head Here", (int(0.42*frame_w), head_top-5), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200,200,200), 2)
    cv2.rectangle(image, (int(0.35*frame_w), foot_top), (int(0.65*frame_w), foot_bottom), (200,200,200), 2)
    cv2.putText(image, "Feet Here", (int(0.37*frame_w), foot_top-5), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200,200,200), 2)

    if results.pose_landmarks:
        first_frame_detected = True
        lm = results.pose_landmarks.landmark

        def get_coords(idx):
            l = lm[idx]
            return (l.x, l.y)

        # Key landmarks
        left_hip = get_coords(mp_pose.PoseLandmark.LEFT_HIP.value)
        right_hip = get_coords(mp_pose.PoseLandmark.RIGHT_HIP.value)
        left_knee = get_coords(mp_pose.PoseLandmark.LEFT_KNEE.value)
        right_knee = get_coords(mp_pose.PoseLandmark.RIGHT_KNEE.value)
        left_shoulder = get_coords(mp_pose.PoseLandmark.LEFT_SHOULDER.value)
        right_shoulder = get_coords(mp_pose.PoseLandmark.RIGHT_SHOULDER.value)
        left_elbow = get_coords(mp_pose.PoseLandmark.LEFT_ELBOW.value)
        right_elbow = get_coords(mp_pose.PoseLandmark.RIGHT_ELBOW.value)
        left_wrist = get_coords(mp_pose.PoseLandmark.LEFT_WRIST.value)
        right_wrist = get_coords(mp_pose.PoseLandmark.RIGHT_WRIST.value)
        nose = get_coords(mp_pose.PoseLandmark.NOSE.value)
        left_ankle = get_coords(mp_pose.PoseLandmark.LEFT_ANKLE.value)
        right_ankle = get_coords(mp_pose.PoseLandmark.RIGHT_ANKLE.value)

        # -------------------------
        # Angle features
        # -------------------------
        features['left_knee_angle'] = calculate_angle(left_hip, left_knee, get_coords(mp_pose.PoseLandmark.LEFT_ANKLE.value))
        features['right_knee_angle'] = calculate_angle(right_hip, right_knee, get_coords(mp_pose.PoseLandmark.RIGHT_ANKLE.value))
        features['left_elbow_angle'] = calculate_angle(left_shoulder, left_elbow, left_wrist)
        features['right_elbow_angle'] = calculate_angle(right_shoulder, right_elbow, right_wrist)

        # -------------------------
        # Anomaly detection only after first frame
        # -------------------------
        if first_frame_detected:
            is_anomaly = check_anomaly(features)
            anomaly_text = "Anomaly Detected!" if is_anomaly else "Normal"
            color = (0,0,255) if is_anomaly else (0,255,0)
            cv2.putText(image, anomaly_text, (30,50), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 3)

        # -------------------------
        # Sit-up counting using hip+shoulder
        # -------------------------
        hip_y = (left_hip[1] + right_hip[1])/2
        shoulder_y = (left_shoulder[1] + right_shoulder[1])/2
        torso_angle = calculate_angle((left_hip[0], left_hip[1]), ((left_shoulder[0]+right_shoulder[0])/2, shoulder_y), (nose[0], nose[1]))

        if hip_y > 0.65 and torso_angle < 70:
            situp_stage = "down"
        if hip_y < 0.5 and torso_angle > 100 and situp_stage == "down":
            situp_stage = "up"
            situp_count +=1
        cv2.putText(image, f"Sit-ups: {situp_count}", (30, 100), cv2.FONT_HERSHEY_SIMPLEX, 1, (0,255,0), 3)

        # -------------------------
        # Jump detection
        # -------------------------
        hip_y_pixel = int(hip_y * frame_h)
        if min_hip_y is None or max_hip_y is None:
            min_hip_y = hip_y_pixel
            max_hip_y = hip_y_pixel

        if jump_stage == "down" and hip_y_pixel < max_hip_y - 20:  # jump up
            jump_stage = "up"
            min_hip_y = hip_y_pixel
        if jump_stage == "up" and hip_y_pixel > min_hip_y + 20:  # landing
            jump_height = max_hip_y - min_hip_y
            jump_stage = "down"
            max_hip_y = hip_y_pixel
        if hip_y_pixel < min_hip_y:
            min_hip_y = hip_y_pixel
        if hip_y_pixel > max_hip_y:
            max_hip_y = hip_y_pixel

        cv2.putText(image, f"Jump height (px): {jump_height}", (30,150), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255,0,0), 2)

        # -------------------------
        # Check head & feet in guide
        # -------------------------
        nose_y = int(nose[1] * frame_h)
        if nose_y < head_top or nose_y > head_bottom:
            cv2.putText(image, "Adjust Head!", (30,200), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0,0,255), 3)

        left_ankle_y = int(left_ankle[1]*frame_h)
        right_ankle_y = int(right_ankle[1]*frame_h)
        if left_ankle_y < foot_top or left_ankle_y > foot_bottom or right_ankle_y < foot_top or right_ankle_y > foot_bottom:
            cv2.putText(image, "Adjust Feet!", (30,250), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0,0,255), 3)

        # Draw skeleton
        mp_drawing.draw_landmarks(image, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)

    # -------------------------
    # Display frame
    # -------------------------
    cv2.imshow('Sports Metrics & Anomaly', image)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
pose.close()
