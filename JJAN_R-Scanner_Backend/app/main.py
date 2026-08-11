from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi import FastAPI, File, UploadFile, HTTPException, Form
import os
import shutil
import cv2
import numpy as np
from ultralytics import YOLO
import easyocr
from fuzzywuzzy import fuzz
from tensorflow.keras.models import load_model
import re
import tempfile


# -------------------------
# SET WRITABLE PATHS FOR CONTAINERS
# -------------------------
# EasyOCR needs a writable model directory
os.makedirs("/tmp/EasyOCR", exist_ok=True)
# YOLO config directory
os.environ['YOLO_CONFIG_DIR'] = "/tmp/Ultralytics"

# -------------------------
# CONFIG / GLOBALS
# -------------------------
UPLOAD_FOLDER = os.path.join(tempfile.gettempdir(), "uploads")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

PRENAME_KEYWORDS = sorted([
    "AMOUNT DUE", "TOTAL AMOUNT", "TOTAL AMOUNT DUE",
    "BALANCE DUE", "TOTAL DUE", "SALES AMOUNT",
    "GRAND TOTAL", "TOTAL", "AMOUNT", "SUMME",
], key=len, reverse=True)

STORE_NAME_PASS_THRESHOLD = 0.90
counts = {"Store Name": 0, "Total": 0}


# -------------------------
# INIT MODELS
# -------------------------
digital_model = YOLO("app/best_epoch31_0.919_0.911_0.945_0.658_theBest.pt")
hw_snT_model = YOLO("app/best_hw_exclusive_snT.pt")
#handwritten_model = YOLO("app/handwritten_digits_best.pt")
handwritten_model = YOLO("app/best_handwritten3.pt")


os.makedirs("/tmp/EasyOCR/user_network", exist_ok=True)
reader = easyocr.Reader(
    lang_list=['en'],
    gpu=False,
    model_storage_directory="/tmp/EasyOCR",
    user_network_directory="/tmp/EasyOCR/user_network"
)

os.environ['YOLO_CONFIG_DIR'] = "/tmp/Ultralytics"
os.environ['MPLCONFIGDIR'] = "/tmp/matplotlib"
os.makedirs("/tmp/Ultralytics", exist_ok=True)
os.makedirs("/tmp/matplotlib", exist_ok=True)


# -------------------------
# UTILITY FUNCTIONS
# -------------------------
def collapse_repeats_and_normalize(s):
    if not s: return ""
    s = re.sub(r'\s+', '', s)
    if not s: return ""
    collapsed = [s[0]]
    for ch in s[1:]:
        if ch != collapsed[-1]:
            collapsed.append(ch)
    return "".join(collapsed).upper()

def contains_prename(text):
    if not text: return False
    txt = text.upper()
    return any(kw.upper() in txt for kw in PRENAME_KEYWORDS)

def fix_ocr_numbers(text):
    if not text: return ""
    text = re.sub(r"[^0-9OoUuIl\|\(\)\[\],.]", "", text)
    replacements = {
        'O':'0','o':'0','D':'0','d':'0','U':'0','u':'0',
        'I':'1','l':'1','E':'6','e':'6','|':'1','(':'1',
        '[':'1',']':'1',',':'.','$':'','₱':''
    }
    for wrong, correct in replacements.items():
        text = text.replace(wrong, correct)
    parts = text.split('.')
    if len(parts)==1:
        text = ''.join(filter(str.isdigit, parts[0]))
    elif len(parts)>=2:
        integer_part = ''.join(filter(str.isdigit, parts[0]))
        decimal_part = ''.join(filter(str.isdigit, parts[1]))
        text = integer_part + '.' + decimal_part[:2]
    return text

def predict_digits_with_mnist(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    _, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    digit_images = []

    for cnt in contours:
        x, y, w, h = cv2.boundingRect(cnt)
        if w > 5 and h > 10:
            digit = cv2.resize(thresh[y:y+h, x:x+w], (28,28))
            digit = digit.astype("float32")/255.0
            digit = np.expand_dims(digit, axis=(0,-1))
            pred = np.argmax(handwritten_model.predict(digit, verbose=0))
            digit_images.append((x, pred))
    digit_images = sorted(digit_images, key=lambda x: x[0])
    return "".join(str(d[1]) for d in digit_images)

# -------------------------
# FASTAPI APP
# -------------------------
app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"]
)
app.mount("/uploads", StaticFiles(directory=UPLOAD_FOLDER), name="uploads")

# -------------------------
# ENDPOINTS
# -------------------------
@app.post("/upload-digital-image/")
async def upload_digital_image(file: UploadFile = File(...),storeName: str = Form(...)):
    try:
        store_name_reference = storeName  # use store name received from frontend
        print(store_name_reference)
        file_path = os.path.join(UPLOAD_FOLDER, file.filename)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        image = cv2.imread(file_path)
        if image is None:
            raise HTTPException(status_code=400, detail="Could not read uploaded image.")

        results = digital_model.predict(source=file_path, imgsz=1024, conf=0.2, iou=0.45)
        class_names = digital_model.names
        total_candidates, store_name_candidates = [], []

        # Iterate detected boxes
        for box in results[0].boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            cls_id, conf = int(box.cls[0]), float(box.conf[0])
            label = class_names[cls_id]
            margin = 3
            x1m, y1m = max(0, x1-margin), max(0, y1-margin)
            x2m, y2m = min(image.shape[1], x2+margin), min(image.shape[0], y2+margin)
            cropped = image[y1m:y2m, x1m:x2m]

            if label in ["Store Name","Total"]:
                ocr_results = reader.readtext(cropped, detail=1)
                simplified = [(txt, float(conf)) if len(item)>=3 else (str(txt),0.0) for item in ocr_results for _, txt, conf in [item]]
                if not simplified: simplified=[("",0.0)]

                for txt, ocr_conf in simplified:
                    candidate = {
                        "raw_text": txt.upper(),
                        "ocr_conf": ocr_conf,
                        "box_conf": conf,
                        "combined_score": conf*ocr_conf,
                        "has_prename": contains_prename(txt),
                        "box_coords": (x1m,y1m,x2m,y2m),
                        "label": label
                    }
                    if label=="Total": total_candidates.append(candidate)
                    else: store_name_candidates.append(candidate)

                counts[label] += 1

        # STORE NAME
        ref_reformatted = collapse_repeats_and_normalize(store_name_reference)
        best_store, best_score = None, -1
        for cand in store_name_candidates:
            sim = fuzz.ratio(collapse_repeats_and_normalize(cand["raw_text"]), ref_reformatted)/100.0
            if sim>best_score: best_score, best_store = sim, cand

        if best_store and best_score>=STORE_NAME_PASS_THRESHOLD:
            final_store_name, store_passed = store_name_reference, True
        elif best_store:
            final_store_name, store_passed = best_store["raw_text"], False
        else:
            final_store_name, store_passed = None, False

        # TOTAL
        selected_total = None
        prename_candidates = [c for c in total_candidates if c["has_prename"]]
        if prename_candidates:
            prename_with_numbers = [c for c in prename_candidates if any(ch.isdigit() for ch in c["raw_text"])]
            selected_total = max(prename_with_numbers or prename_candidates, key=lambda c: c["combined_score"])
        elif total_candidates:
            selected_total = max(total_candidates, key=lambda c: c["combined_score"])

        cleaned_total_num, cleaned_total_raw = None, None
        if selected_total:
            x1,y1,x2,y2 = selected_total["box_coords"]
            cropped_box = image[y1:y2, x1:x2]
            mid_x = int(cropped_box.shape[1] * 0.6)
            right_crop = cropped_box[:, mid_x:]
            ocr_results = reader.readtext(right_crop, detail=1)
            best_number, best_conf = None, -1
            for _, txt, conf in ocr_results:
                fixed = fix_ocr_numbers(txt)
                if fixed and conf > best_conf:
                    best_number, best_conf = fixed, conf
            cleaned_total_raw = best_number
            try:
                cleaned_total_num = float(re.sub(r'[^0-9.]', '', best_number)) if best_number else None
            except:
                cleaned_total_num = None

        if final_store_name is None or cleaned_total_num is None:
            return JSONResponse(content={"status":"error","message":"Could not detect both store name and total."}, status_code=400)

        return JSONResponse(content={
            "status":"ok",
            "filename":os.path.basename(file_path),
            "total_raw":cleaned_total_raw,
            "total_numeric":cleaned_total_num,
            "store_name":final_store_name.upper(),
            "store_match_passed":store_passed,
            "cashflow":1 if store_passed else 0
        })

    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)

@app.post("/upload-handwritten-image/")
async def upload_handwritten_image(file: UploadFile = File(...),storeName: str = Form(...)):
    try:
        store_name_reference = storeName  # use store name received from frontend
        # Save uploaded file temporarily
        print(store_name_reference)
        file_path = os.path.join(UPLOAD_FOLDER, file.filename)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        image = cv2.imread(file_path)
        if image is None:
            raise HTTPException(status_code=400, detail="Could not read uploaded image.")

        results = hw_snT_model.predict(source=file_path, imgsz=1024, conf=0.2, iou=0.45)
        class_names = hw_snT_model.names
        total_candidates, store_name_candidates = [], []

        for box in results[0].boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            cls_id, conf = int(box.cls[0]), float(box.conf[0])
            label = class_names[cls_id]
            margin = 3
            x1m, y1m = max(0, x1-margin), max(0, y1-margin)
            x2m, y2m = min(image.shape[1], x2+margin), min(image.shape[0], y2+margin)
            cropped = image[y1m:y2m, x1m:x2m]

            if label in ["Store Name","Total"]:
                ocr_results = reader.readtext(cropped, detail=1)
                simplified = [(txt, float(conf)) if len(item)>=3 else (str(txt),0.0) for item in ocr_results for _, txt, conf in [item]]
                if not simplified: simplified=[("",0.0)]

                for txt, ocr_conf in simplified:
                    candidate = {
                        "raw_text": txt.upper(),
                        "ocr_conf": ocr_conf,
                        "box_conf": conf,
                        "combined_score": conf*ocr_conf,
                        "has_prename": contains_prename(txt),
                        "box_coords": (x1m,y1m,x2m,y2m),
                        "label": label
                    }
                    if label=="Total": total_candidates.append(candidate)
                    else: store_name_candidates.append(candidate)

                counts[label] += 1

        # STORE NAME
        ref_reformatted = collapse_repeats_and_normalize(store_name_reference)
        best_store, best_score = None, -1
        for cand in store_name_candidates:
            sim = fuzz.ratio(collapse_repeats_and_normalize(cand["raw_text"]), ref_reformatted)/100.0
            if sim>best_score: best_score, best_store = sim, cand

        if best_store and best_score>=STORE_NAME_PASS_THRESHOLD:
            final_store_name, store_passed = store_name_reference, True
        elif best_store:
            final_store_name, store_passed = best_store["raw_text"], False
        else:
            final_store_name, store_passed = None, False

        # TOTAL
        selected_total = None
        prename_candidates = [c for c in total_candidates if c["has_prename"]]
        if prename_candidates:
            prename_with_numbers = [c for c in prename_candidates if any(ch.isdigit() for ch in c["raw_text"])]
            selected_total = max(prename_with_numbers or prename_candidates, key=lambda c: c["combined_score"])
        elif total_candidates:
            selected_total = max(total_candidates, key=lambda c: c["combined_score"])

        cleaned_total_num, cleaned_total_raw = None, None
        if selected_total:
            x1, y1, x2, y2 = selected_total["box_coords"]
            cropped_box = image[y1:y2, x1:x2]

            # cut in half, keep right side
            mid_x = int(cropped_box.shape[1] * 0.6)
            right_crop = cropped_box[:, mid_x:]
            

            # ==========================
            # YOLO HANDWRITTEN DIGIT DETECTION
            # ==========================
            results_hw = handwritten_model.predict(source=right_crop, imgsz=1024, conf=0.5, iou=0.7)
            
            # Mapping YOLO's class indices to real characters
            class_to_digit = {
                0: ".",  # period
                1: "0",
                2: "1",
                3: "2",
                4: "3",
                5: "4",
                6: "5",
                7: "6",
                8: "7",
                9: "8",
                10: "9"
            }

            # list of detected digits [(x_center, predicted_digit)]
            detected_digits = []
            if results_hw and len(results_hw[0].boxes) > 0:
                for box in results_hw[0].boxes:
                    x1, y1, x2, y2 = map(int, box.xyxy[0])
                    cls_id = int(box.cls[0])
                    conf = float(box.conf[0])
                    x_center = (x1 + x2) / 2

                    # ✅ decode using mapping
                    digit_label = class_to_digit.get(cls_id, "?")
                    detected_digits.append((x_center, digit_label))

            # Sort digits from left to right
            detected_digits.sort(key=lambda x: x[0])

            # Combine digits into the final number string
            final_number = "".join([d[1] for d in detected_digits])
            print("Detected digits:", [d[1] for d in detected_digits])
            print("Final number:", final_number)


            if final_number:
                cleaned_total_raw = final_number
                try:
                    cleaned_total_num = float(final_number)
                    print(f"final number ", cleaned_total_num)
                except:
                    cleaned_total_num = None
            else:
                cleaned_total_raw, cleaned_total_num = None, None

        if final_store_name is None or cleaned_total_num is None:
            return JSONResponse(content={"status":"error","message":"Could not detect both store name and total."}, status_code=400)

        return JSONResponse(content={
            "status":"ok",
            "filename":os.path.basename(file_path),
            "total_raw":cleaned_total_raw,
            "total_numeric":cleaned_total_num,
            "store_name":final_store_name.upper(),
            "store_match_passed":store_passed,
            "cashflow":1 if store_passed else 0
        })

    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)
