# utils.py
from math import atan2, degrees

rules = {
    "left_knee_angle": (70, 180),
    "right_knee_angle": (70, 180),
    "left_elbow_angle": (30, 170),
    "right_elbow_angle": (30, 170),
}

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

def check_anomaly(features):
    for key, (low, high) in rules.items():
        if features.get(key, 0) < low or features.get(key, 0) > high:
            return True
    return False
