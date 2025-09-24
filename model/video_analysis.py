import cv2
import mediapipe as mp
from model.utils import calculate_angle, check_anomaly

USER_HIP_TO_ANKLE_CM = 90  # adjust to user

def analyze_video_file(file_path):
    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5)
    mp_drawing = mp.solutions.drawing_utils

    cap = cv2.VideoCapture(file_path)

    situp_count = 0
    situp_stage = None
    down_frames = 0
    up_frames = 0

    jump_stage = "down"
    min_hip_y = None
    max_hip_y = None
    initial_hip_ankle_pixel = None
    jump_height = 0
    anomaly_detected = False

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        frame_h, frame_w, _ = frame.shape
        image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(image_rgb)

        if not results.pose_landmarks:
            continue

        lm = results.pose_landmarks.landmark

        def get_coords(idx):
            l = lm[idx]
            return (l.x, l.y)

        left_hip = get_coords(mp_pose.PoseLandmark.LEFT_HIP.value)
        right_hip = get_coords(mp_pose.PoseLandmark.RIGHT_HIP.value)
        left_knee = get_coords(mp_pose.PoseLandmark.LEFT_KNEE.value)
        right_knee = get_coords(mp_pose.PoseLandmark.RIGHT_KNEE.value)
        left_shoulder = get_coords(mp_pose.PoseLandmark.LEFT_SHOULDER.value)
        right_shoulder = get_coords(mp_pose.PoseLandmark.RIGHT_SHOULDER.value)
        left_ankle = get_coords(mp_pose.PoseLandmark.LEFT_ANKLE.value)
        right_ankle = get_coords(mp_pose.PoseLandmark.RIGHT_ANKLE.value)

        # -------------------------
        # Torso angle for situps
        # -------------------------
        left_torso_angle = calculate_angle(left_shoulder, left_hip, left_knee)
        right_torso_angle = calculate_angle(right_shoulder, right_hip, right_knee)
        torso_angle = (left_torso_angle + right_torso_angle) / 2

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

        # -------------------------
        # Jump height calculation
        # -------------------------
        hip_y = (left_hip[1] + right_hip[1]) / 2
        hip_y_pixel = int(hip_y * frame_h)

        if initial_hip_ankle_pixel is None:
            initial_hip_pixel = int(((left_hip[1] + right_hip[1])/2)*frame_h)
            initial_ankle_pixel = int(((left_ankle[1]+right_ankle[1])/2)*frame_h)
            initial_hip_ankle_pixel = initial_ankle_pixel - initial_hip_pixel

        jump_thresh = int(0.2 * initial_hip_ankle_pixel)

        if jump_stage == "down":
            if min_hip_y is None or hip_y_pixel < min_hip_y:
                min_hip_y = hip_y_pixel
            if max_hip_y is None or hip_y_pixel > max_hip_y:
                max_hip_y = hip_y_pixel
            if (max_hip_y - hip_y_pixel) > jump_thresh:
                jump_stage = "up"
                min_hip_y = hip_y_pixel
        elif jump_stage == "up":
            if hip_y_pixel < min_hip_y:
                min_hip_y = hip_y_pixel
            if (max_hip_y - hip_y_pixel) < (jump_thresh*0.3):
                jump_height = max_hip_y - min_hip_y
                jump_stage = "down"
                min_hip_y = hip_y_pixel
                max_hip_y = hip_y_pixel

        # Convert pixels to cm
        jump_height_cm = jump_height * (USER_HIP_TO_ANKLE_CM / initial_hip_ankle_pixel) if initial_hip_ankle_pixel else 0

        # -------------------------
        # Anomaly detection
        # -------------------------
        features = {
            "left_knee_angle": calculate_angle(left_hip, left_knee, left_ankle),
            "right_knee_angle": calculate_angle(right_hip, right_knee, right_ankle),
        }
        anomaly_detected = check_anomaly(features)

    cap.release()
    pose.close()

    return situp_count, jump_height_cm, anomaly_detected
