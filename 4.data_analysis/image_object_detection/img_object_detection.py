"""Detection of objects using Yolov5 model (Pytorch framework)"""
import torch
import cv2

# Resize image for faster processing
img_resized = cv2.resize(cv2.imread("person.jpg"), (416, 416), interpolation = cv2.INTER_LINEAR) # Also cv2.INTER_AREA / cv2.INTER_CUBIC 

model = torch.hub.load('ultralytics/yolov5', 'yolov5n')  # or yolov5n - yolov5x6, custom

detection = model(img_resized)

detection.print()

# The newest Yolo object recognition model is

"""Detection of objects using yolov4 model (Darknet framework)"""
import cv2
import cvlib as cv
import time
# Start time measurement
start_time = time.time()

# Resize image for faster processing
img_resized = cv2.resize(cv2.imread("person.jpg"), (416, 416), interpolation = cv2.INTER_LINEAR) # Also cv2.INTER_AREA / cv2.INTER_CUBIC 

# Detects objects using yolov4 on CPU
detection = cv.detect_common_objects(img_resized, confidence=0.5, model="yolov4", enable_gpu = False)

# 
for i in range(len(detection[1])):
    print(f"Detected object: {detection[1][i]} with confidence level of {round(detection[2][i],3)}\n")

print(f"--- {time.time() - start_time} seconds ---")

# On CPU, it takes about 0.4s to recognize objects on one image. The resolution seems not to matter much for speed, but for precision / number of objects detectedg

