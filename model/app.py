# sports_metrics_hackathon_final_fixed.py
import cv2
import mediapipe as mp
from math import atan2, degrees
from utils import calculate_angle, check_anomaly
import time
last_jump_time = 0  # Add this near your variables section



# -------------------------
# MediaPipe setup
# -------------------------
mp_drawing = mp.solutions.drawing_utils
mp_pose = mp.solutions.pose
pose = mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5)



# -------------------------
# Variables
# -------------------------
situp_count = 0
situp_stage = None
down_frames = 0
up_frames = 0

jump_stage = "down"
min_hip_y = None
max_hip_y = None
jump_height = None  # Do NOT initialize with 0

first_frame_detected = False
setup_done = False
initial_hip_y = None
initial_ankle_y = None
initial_hip_ankle_pixel = None  # Add to variables section

USER_HIP_TO_ANKLE_CM = 90  # <-- Set this to the user's real hip-to-ankle length in cm

last_jump_time = 0  # Add this near your variables section

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
    # Setup guides (head & feet) until user aligns
    # -------------------------
    if not setup_done:
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
        features['left_knee_angle'] = calculate_angle(left_hip, left_knee, left_ankle)
        features['right_knee_angle'] = calculate_angle(right_hip, right_knee, right_ankle)
        features['left_elbow_angle'] = calculate_angle(left_shoulder, left_elbow, left_wrist)
        features['right_elbow_angle'] = calculate_angle(right_shoulder, right_elbow, right_wrist)

        # -------------------------
        # Anomaly detection
        # -------------------------
        if first_frame_detected:
            is_anomaly = check_anomaly(features)
            anomaly_text = "Anomaly Detected!" if is_anomaly else "Normal"
            color = (0,0,255) if is_anomaly else (0,255,0)
            cv2.putText(image, anomaly_text, (30,50), cv2.FONT_HERSHEY_SIMPLEX, 1, color, 3)

        # -------------------------
        # Setup completion check
        # -------------------------
        if not setup_done:
            nose_y = int(nose[1] * frame_h)
            left_ankle_y = int(left_ankle[1]*frame_h)
            right_ankle_y = int(right_ankle[1]*frame_h)
            if (head_top < nose_y < head_bottom) and (foot_top < left_ankle_y < foot_bottom) and (foot_top < right_ankle_y < foot_bottom):
                setup_done = True
                # Calculate initial hip and ankle positions in pixels
                initial_hip_pixel = int(((left_hip[1] + right_hip[1]) / 2) * frame_h)
                initial_ankle_pixel = int(((left_ankle[1] + right_ankle[1]) / 2) * frame_h)
                initial_hip_ankle_pixel = initial_ankle_pixel - initial_hip_pixel  # always positive, in pixels
        else:
            # -------------------------
            # Sit-up detection (shoulder–hip–knee angle)
            # -------------------------
            left_torso_angle = calculate_angle(left_shoulder, left_hip, left_knee)
            right_torso_angle = calculate_angle(right_shoulder, right_hip, right_knee)
            torso_angle = (left_torso_angle + right_torso_angle) / 2

            # Thresholds: adjust as needed for your setup
            down_thresh = 150  # lying down: angle is open
            up_thresh = 90     # sitting up: angle is closed

            # Stage detection with debounce
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

            cv2.putText(image, f"Sit-ups: {situp_count}", (30, 100), cv2.FONT_HERSHEY_SIMPLEX, 1, (0,255,0), 3)

            # -------------------------
            # Jump detection (improved)
            # -------------------------
                        # -------------------------
            # Jump detection (fixed, all in pixels)
            # -------------------------
            hip_y = (left_hip[1] + right_hip[1]) / 2
            hip_y_pixel = int(hip_y * frame_h)

            # Initialize extremes if None
            if min_hip_y is None or max_hip_y is None:
                min_hip_y = hip_y_pixel
                max_hip_y = hip_y_pixel

            # Set jump detection threshold as a fraction of hip-ankle length
            jump_thresh = int(0.2 * initial_hip_ankle_pixel) if initial_hip_ankle_pixel else 15

            if jump_stage == "down":
                # Update standing max
                if hip_y_pixel > max_hip_y:
                    max_hip_y = hip_y_pixel
                # Reset min_hip_y to current standing
                min_hip_y = hip_y_pixel

                # Detect jump: hip moves up enough
                if (max_hip_y - hip_y_pixel) > jump_thresh:
                    jump_stage = "up"
                    min_hip_y = hip_y_pixel  # start tracking min in air

            elif jump_stage == "up":
                # Update min_hip_y while in air (highest point)
                if hip_y_pixel < min_hip_y:
                    min_hip_y = hip_y_pixel

                # Detect landing: hip returns near standing position
                if (max_hip_y - hip_y_pixel) < (jump_thresh * 0.3):
                    jump_height = max_hip_y - min_hip_y
                    jump_stage = "down"
                    # Reset extremes for next jump
                    min_hip_y = hip_y_pixel
                    max_hip_y = hip_y_pixel

            # Convert jump height from pixels to centimeters and display
            if (
                initial_hip_ankle_pixel
                and initial_hip_ankle_pixel > 0
                and jump_height is not None
            ):
                jump_height_cm = jump_height * (USER_HIP_TO_ANKLE_CM / initial_hip_ankle_pixel)
            else:
                jump_height_cm = 0

            cv2.putText(image, f"Jump height: {jump_height_cm:.1f} cm", (30,150), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0,255,0), 2)


        # -------------------------
        # Draw skeleton
        # -------------------------
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
