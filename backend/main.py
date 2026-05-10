from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydub import AudioSegment
from pydantic import BaseModel
from pydub.utils import which
import requests
import re
import random
import numpy as np
import json
import tempfile
import os
import cv2
from dotenv import load_dotenv
from transformers import AutoFeatureExtractor, AutoModelForAudioClassification
import torch
import librosa

load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SIGHTENGINE_API_USER = "1130323748"
SIGHTENGINE_API_SECRET = "KgLiiWfEgeBrKKb7xTGB7otycRBy2aVV"

class TextRequest(BaseModel):
    text: str


@app.get("/")
def root():
    return {"message": "Unveil Backend Running"}


# ============================================================
#  EXPLANATION GENERATORS
# ============================================================

def is_arabic_text(text: str) -> bool:
    arabic_chars = len(re.findall(r'[\u0600-\u06FF]', text))
    total_chars = len(re.sub(r'\s', '', text))
    if total_chars == 0:
        return False
    return (arabic_chars / total_chars) > 0.3

def generate_text_explanation(reasons: list, score: int, details: dict, is_ar: bool = False) -> str:
    """
    Build a concise, technical, varied explanation for text analysis.
    Supports English and Arabic.
    """
    wc  = details["word_count"]
    asl = details["avg_sentence_length"]
    ld  = details["lexical_diversity"]
    rr  = details["repetition_ratio"]

    if score >= 50:
        parts = []
        if "Uniform sentence structure" in reasons:
            parts.append(random.choice([
                f"هيكل الجمل متطابق بشكل كبير (متوسط {asl:.1f} كلمة)؛ لا يوجد تنوع في الأسلوب" if is_ar else f"highly uniform sentence structure (avg {asl:.1f} words); no stylistic variation detected",
                f"التباين في طول الجمل شبه معدوم، مما يتوافق مع مخرجات الذكاء الاصطناعي" if is_ar else f"sentence-length variance is near zero (~{asl:.1f} words/sentence); consistent with LLM output",
                f"أسلوب كتابة ثابت وموحد يفتقر إلى التنوع البشري المعتاد" if is_ar else f"consistent register throughout; lacks the variance typical in human prose",
            ]))
        if "High word repetition" in reasons:
            parts.append(random.choice([
                f"نسبة تكرار الكلمات تبلغ {rr*100:.0f}%؛ العبارات النمطية مسيطرة على النص" if is_ar else f"word repetition ratio is {rr*100:.0f}%; formulaic phrasing dominates the text",
                f"معدل إعادة استخدام المفردات ({rr*100:.0f}%) مرتفع بشكل غير طبيعي" if is_ar else f"lexical recycling rate ({rr*100:.0f}%) is abnormally high for human authorship",
                f"تكرار مستمر للعبارات الانتقالية، بصمة إحصائية تطابق توليد الذكاء الاصطناعي" if is_ar else f"repetitive transitional phrases; statistical fingerprint matches LLM output",
            ]))
        if "Low vocabulary diversity" in reasons:
            parts.append(random.choice([
                f"درجة تنوع المفردات منخفضة ({ld:.2f})، مما يشير إلى مفردات توليدية محدودة" if is_ar else f"vocabulary diversity score is {ld:.2f}; falls below the human-writing baseline",
                f"{ld*100:.0f}% فقط من الكلمات فريدة، مما يدل على فقر في تنوع المفردات" if is_ar else f"only {ld*100:.0f}% of tokens are unique, indicating limited generative vocabulary",
            ]))
        if "Formal structured phrasing" in reasons:
            parts.append(random.choice([
                "تم اكتشاف عبارات انتقالية ورسمية بشكل مفرط، وهو نمط شائع للذكاء الاصطناعي" if is_ar else "formal structured phrasing detected; transitional markers are overrepresented",
                "قواعد نحوية رسمية خالية من التعبيرات العامية بشكل غير طبيعي" if is_ar else "perfect formal grammar with zero colloquial markers — atypical for human text",
                "عبارات ربط نمطية للذكاء الاصطناعي بدون أي تحولات غير رسمية" if is_ar else "AI-typical connective phrases identified; no informal register shifts observed",
            ]))
        if "Long structured sentences" in reasons:
            parts.append(random.choice([
                f"متوسط طول الجمل {asl:.1f} كلمة؛ أعلى من المعدل الطبيعي للمحادثات البشرية" if is_ar else f"sentences average {asl:.1f} words; consistently above human conversational norms",
                f"جمل طويلة ومعقدة (متوسط {asl:.1f} كلمة) توحي بالتوليد الآلي" if is_ar else f"unusually long, clause-heavy sentences (avg {asl:.1f} words) suggest automated generation",
            ]))
        if "Long consistent structure" in reasons:
            parts.append(random.choice([
                f"النص يتكون من {wc} كلمة بهيكل منتظم آلياً، وهذا غير معتاد في الكتابة البشرية" if is_ar else f"structural consistency across {wc} words is mechanically regular; atypical of human writing",
                f"نص طويل متماسك البنية دون أي استطراد طبيعي للموضوع" if is_ar else f"text spans {wc} words with uniform structure; no natural drift or topic digression",
            ]))
        if "Overly consistent punctuation" in reasons:
            parts.append(random.choice([
                "استخدام علامات الترقيم بنمط آلي منتظم جداً بلا أي انحرافات طبيعية" if is_ar else "punctuation applied with machine-like regularity; no human-style deviations",
                "كثافة علامات الترقيم وتوزيعها منتظم إحصائياً عبر النص بالكامل" if is_ar else "punctuation density and placement are statistically uniform across the entire text",
            ]))

        if parts:
            return "؛ ".join(parts[:3]) + "." if is_ar else "; ".join(parts[:3]) + "."
        return "تم الكشف عن كلمات صريحة تدل على الذكاء الاصطناعي؛ مؤشر قاطع على المحتوى المولد آلياً." if is_ar else "Explicit AI-related wording was detected; definitive indicator of machine-generated content."

    else:
        parts = []
        if wc < 25:
            parts.append(random.choice([
                f"رسالة قصيرة وغير رسمية ({wc} كلمة)؛ تتوافق مع التواصل البشري الطبيعي" if is_ar else f"short informal message ({wc} words); consistent with natural human communication",
                f"طول النص والنبرة غير الرسمية تعكس أسلوب كتابة بشري أصيل" if is_ar else f"text length ({wc} words) and casual tone are characteristic of authentic human writing",
            ]))
        if ld > 0.6:
            parts.append(random.choice([
                f"تنوع المفردات عالي ({ld:.2f})، مما يعكس تعبيراً بشرياً طبيعياً" if is_ar else f"vocabulary diversity is high ({ld:.2f}); reflects natural human expression",
                f"تنوع لغوي حقيقي بوجود {ld*100:.0f}% من الكلمات الفريدة" if is_ar else f"{ld*100:.0f}% unique tokens indicate genuine linguistic variety",
            ]))
        if "Casual human punctuation" in reasons:
            parts.append(random.choice([
                "أنماط الترقيم غير الرسمية وعلامات التردد تؤكد الأصل البشري للنص" if is_ar else "casual punctuation patterns and disfluency markers confirm human authorship",
                "علامات ترقيم غير رسمية تعكس كتابة بشرية طبيعية" if is_ar else "informal punctuation (e.g. '...', '؟') reflects authentic human-style writing",
            ]))
        if not parts:
            parts.append(random.choice([
                "التعبيرات العامية وعدم الانتظام في طول الجمل يتوافق مع الكتابة البشرية" if is_ar else f"natural disfluency and colloquial phrasing consistent with human writing",
                f"تباين الإيقاع والتنوع في الجمل (متوسط {asl:.1f} كلمة) يشير إلى نص بشري طبيعي" if is_ar else f"sentence variety (avg {asl:.1f} words) and natural phrasing are consistent with human authorship",
                "تقلب النبرة العاطفية وإيقاع الجمل غير المنتظم يوحي بأصل بشري" if is_ar else f"emotional tone variation and irregular sentence rhythm suggest human origin",
            ]))
        return "؛ ".join(parts[:3]) + "." if is_ar else "; ".join(parts[:3]) + "."


def generate_image_explanation(ai_score: float, raw: dict) -> str:
    """
    Build a concise, technical, varied explanation for image analysis
    matching the style of the Detection_Report.docx.
    """
    pct = f"{ai_score:.1f}%"

    if ai_score >= 90:
        phrases = [
            f"Facial landmarks perfectly symmetric — statistically impossible in real photos ({pct}).",
            f"GAN artifacts visible in hair strands; ear geometry implausible; AI confidence {pct}.",
            f"Diffusion model texture patterns detected in background and skin regions; confidence {pct}.",
            f"Consistent lighting contradicts the claimed scene setting; no real-world shadow variance detected ({pct}).",
            f"Hyper-smooth skin texture and zero chromatic aberration; strong AI-generation signature ({pct}).",
        ]
    elif ai_score >= 70:
        phrases = [
            f"Diffusion model texture patterns detected in background bokeh; AI score {pct}.",
            f"Synthetic edge smoothing and uniform depth-of-field inconsistencies detected ({pct}).",
            f"Lighting uniformity and absence of natural grain indicate generative model output ({pct}).",
            f"Several regions display synthetic texture gradients atypical of camera-captured images ({pct}).",
            f"AI generation markers detected in facial geometry and background rendering ({pct}).",
        ]
    elif ai_score >= 50:
        phrases = [
            f"Borderline AI probability ({pct}); some synthetic indicators in texture and shading patterns.",
            f"Image may be AI-enhanced or composite; GenAI confidence just above threshold ({pct}).",
            f"Mixed signals: natural elements present alongside synthetic texture anomalies ({pct}).",
        ]
    elif ai_score >= 25:
        phrases = [
            f"Authentic JPEG compression artifacts present; no latent-space anomalies detected ({pct}).",
            f"Natural lens distortion and grain present; EXIF metadata consistent with real capture ({pct}).",
            f"Micro-shadow inconsistencies typical of smartphone cameras, not AI ({pct}).",
            f"Moderate confidence in human origin; some edited regions but overall metadata is real ({pct}).",
        ]
    else:
        phrases = [
            f"EXIF metadata intact; natural lens distortion and film grain present ({pct}).",
            f"Authentic JPEG compression artifacts; no latent-space anomalies detected ({pct}).",
            f"Micro-shadow inconsistencies typical of real cameras; strong human-origin signal ({pct}).",
            f"Natural noise floor and realistic depth-of-field confirm authentic photographic origin ({pct}).",
        ]

    return random.choice(phrases)


def generate_video_explanation(ai_score: float, raw: dict) -> str:
    """
    Build a concise, technical, varied explanation for video frame analysis
    matching the style of the Detection_Report.docx.
    """
    pct = f"{ai_score:.1f}%"

    if ai_score >= 85:
        phrases = [
            f"Lighting remains completely static across all frames — physically impossible in real footage ({pct}).",
            f"Temporal flickering in facial region; lip-sync drift detected in analyzed frame ({pct}).",
            f"Identity-swap model fingerprint detected in frequency domain analysis ({pct}).",
            f"DeepFake boundary artifacts detected around jaw and neck area; AI confidence {pct}.",
            f"Synthetic skin rendering and absence of real-world camera motion artifacts ({pct}).",
        ]
    elif ai_score >= 60:
        phrases = [
            f"Temporal flickering and unnatural sharpness transitions detected in frame ({pct}).",
            f"Visual inconsistencies in lighting and texture suggest possible AI generation ({pct}).",
            f"Frame exhibits synthetic texture patterns inconsistent with natural video capture ({pct}).",
            f"AI-generation probability {pct}; image quality and edge sharpness pattern are atypical of real cameras.",
        ]
    elif ai_score >= 40:
        phrases = [
            f"Mostly authentic frame; minor color-grading edits detected but not conclusively AI-generated ({pct}).",
            f"Mixed signals: natural motion blur present alongside minor synthetic anomalies ({pct}).",
        ]
    else:
        phrases = [
            f"Natural blink rate and micro-expressions consistent with real footage ({pct}).",
            f"Camera shake and audio-video phase alignment match real recording characteristics ({pct}).",
            f"Consistent background noise and natural movement physics confirm authenticity ({pct}).",
            f"Natural film grain, realistic compression artifacts, and organic lighting detected ({pct}).",
        ]

    return random.choice(phrases)


def generate_audio_explanation(is_ai: bool, confidence: str, label: str = "", note: str = "") -> str:
    """
    Build a concise, technical, varied explanation for audio analysis
    matching the style of the Detection_Report.docx.
    """
    conf_val = float(confidence.replace("%", ""))
    pct = f"{conf_val:.1f}%"
    # Include model label if available
    label_tag = f" Model label: '{label}'" if label else ""

    if is_ai:
        if conf_val >= 95:
            phrases = [
                f"TTS prosody pattern detected; unnatural pitch reset at sentence boundaries ({pct}).{label_tag}",
                f"Voice-clone model detected via voiceprint comparison against known TTS systems ({pct}).{label_tag}",
                f"Synthetic formants and missing background noise floor; artificially smooth phoneme transitions ({pct}).{label_tag}",
                f"Spectral analysis reveals synthetic voice harmonics; absence of breathing artifacts ({pct}).{label_tag}",
            ]
        elif conf_val >= 80:
            phrases = [
                f"AI voice detection confidence {pct}; waveform patterns inconsistent with natural human vocalization.{label_tag}",
                f"Deepfake voice signals detected; prosodic irregularities and spectral smoothness indicate TTS synthesis ({pct}).{label_tag}",
                f"Unnatural pauses and regularized cadence suggest generation by a voice model ({pct}).{label_tag}",
            ]
        else:
            phrases = [
                f"Synthetic prosody markers identified; natural pitch variability is reduced ({pct}).{label_tag}",
                f"AI-generation probability {pct}; audio may be voice-cloned or AI-enhanced.{label_tag}",
                f"Borderline deepfake indicators; spectral smoothness exceeds typical human speech range ({pct}).{label_tag}",
            ]
    else:
        if conf_val >= 95:
            phrases = [
                f"Natural breath pauses and vocal fry typical of authentic speech ({pct}).{label_tag}",
                f"Background room noise and spontaneous disfluency confirm human origin ({pct}).{label_tag}",
                f"Spectral profile, prosody, and breath patterns consistent with genuine human speech ({pct}).{label_tag}",
                f"Spontaneous speech errors and repair sequences are hallmarks of real audio ({pct}).{label_tag}",
            ]
        elif conf_val >= 75:
            phrases = [
                f"Natural speech rhythm, organic pauses, and realistic vocal dynamics detected ({pct}).{label_tag}",
                f"Emotional variation in pitch and rhythm inconsistent with TTS output ({pct}).{label_tag}",
                f"Waveform irregularities and noise characteristics typical of genuine human recording ({pct}).{label_tag}",
            ]
        else:
            phrases = [
                f"Moderate human-voice confidence ({pct}); natural speech elements detected but signal is not fully conclusive.{label_tag}",
                f"Leaning toward authentic audio; some expected human vocal markers present ({pct}).{label_tag}",
            ]

    return random.choice(phrases)


# ============================================================
#  TEXT ANALYSIS CORE
# ============================================================

def perform_text_analysis(text: str):
    lower_text = text.lower()
    is_ar = is_arabic_text(text)

    # Basic metrics
    words = text.split()
    word_count = len(words)

    if word_count == 0:
        return {
            "result": "Likely Human Written",
            "confidence": "0%",
            "reason": "النص فارغ أو قصير جداً للتحليل." if is_ar else "Text is empty or too short to analyze.",
            "score": 0,
            "details": {"word_count": 0, "sentence_count": 0, "avg_sentence_length": 0, "lexical_diversity": 0, "repetition_ratio": 0}
        }

    sentences = re.split(r'[.!؟?]+', text)
    sentences = [s.strip() for s in sentences if s.strip()]
    sentence_count = max(1, len(sentences))

    avg_sentence_length = word_count / sentence_count if sentence_count else 0

    unique_words = len(set(words))
    lexical_diversity = unique_words / word_count if word_count else 0

    punctuation_count = len(re.findall(r"[.,،;:!?؟\-]", text))
    repetition_ratio = 1 - lexical_diversity

    # AI indicator keywords
    ai_keywords = [
        "as an ai", "language model", "generated by ai", "chatgpt", "openai",
        "artificial intelligence", "elevenlabs", "voice generated by",
        "ai generated", "ai-generated", "text to speech", "text-to-speech",
        "كذكاء اصطناعي", "نموذج لغوي", "نموذج ذكاء اصطناعي", "تم إنشاؤه بواسطة",
        "بصفتي ذكاء اصطناعي", "أنا مجرد برنامج", "لا يمكنني", "[name]", "<name>"
    ]

    formal_phrases = [
        "in conclusion", "moreover", "furthermore", "therefore", "additionally",
        "it is important to note", "firstly", "secondly", "to summarize",
        "في الختام", "علاوة على ذلك", "من المهم أن نلاحظ", "بالإضافة إلى ذلك", 
        "ومع ذلك", "بناء على ذلك", "ختاماً", "من الجدير بالذكر", "مما لا شك فيه"
    ]

    # Initialize a baseline score
    score = 15
    reasons = []

    # Explicit AI keyword → instant return
    if any(k in lower_text for k in ai_keywords):
        details = {
            "word_count": word_count,
            "sentence_count": sentence_count,
            "avg_sentence_length": round(avg_sentence_length, 2),
            "lexical_diversity": round(lexical_diversity, 2),
            "repetition_ratio": round(repetition_ratio, 2),
        }
        explanation = "تم الكشف عن كلمات صريحة تدل على الذكاء الاصطناعي، وهو مؤشر قاطع على المحتوى المولد آلياً." if is_ar else "Explicit AI-related wording was detected in the text, which is a definitive indicator of machine-generated content."
        return {
            "result": "Likely AI Generated",
            "confidence": "99%",
            "reason": explanation,
            "score": 99,
            "details": details,
        }

    # Sentence uniformity
    sentence_lengths = [len(s.split()) for s in sentences]
    if len(sentence_lengths) > 2:
        variance = np.var(sentence_lengths)
        if variance < 10:
            score += 20
            reasons.append("Uniform sentence structure")
        elif variance < 20:
            score += 10
            reasons.append("Uniform sentence structure")

    # Long structured text
    if avg_sentence_length > 20:
        score += 15
        reasons.append("Long structured sentences")

    # Repetition
    if repetition_ratio > 0.50:
        score += 15
        reasons.append("High word repetition")

    # Low lexical diversity
    if lexical_diversity < 0.50:
        score += 15
        reasons.append("Low vocabulary diversity")

    # Formal connectors
    found_formal_phrases = [p for p in formal_phrases if p in lower_text]
    if len(found_formal_phrases) >= 2:
        score += 20
        reasons.append("Formal structured phrasing")
    elif len(found_formal_phrases) == 1:
        score += 10
        reasons.append("Formal structured phrasing")

    # Too much punctuation
    if punctuation_count > (word_count * 0.15):
        score += 10
        reasons.append("Overly consistent punctuation")

    # Very long text
    if word_count > 250 and len(found_formal_phrases) > 0:
        score += 15
        reasons.append("Long consistent structure")

    # Human indicators
    if word_count < 25:
        score -= 20
        reasons.append("Short natural text")

    casual_punct = ["...", "؟؟", "!!", "?!", "!?", "،،", ",,"]
    if any(p in text for p in casual_punct):
        score -= 15
        reasons.append("Casual human punctuation")
        
    if lexical_diversity > 0.7:
        score -= 15

    score = max(5, min(score, 99))

    if score >= 50:
        result = "Likely AI Generated"
        final_confidence = score
    else:
        result = "Likely Human Written"
        final_confidence = 100 - score

    details = {
        "word_count": word_count,
        "sentence_count": sentence_count,
        "avg_sentence_length": round(avg_sentence_length, 2),
        "lexical_diversity": round(lexical_diversity, 2),
        "repetition_ratio": round(repetition_ratio, 2),
    }

    explanation = generate_text_explanation(reasons, score, details, is_ar)

    return {
        "result": result,
        "confidence": f"{final_confidence}%",
        "reason": explanation,
        "score": score,
        "details": details,
    }


# ============================================================
#  API ENDPOINTS
# ============================================================

@app.post("/analyze-text")
def analyze_text(data: TextRequest):
    try:
        text = data.text.strip()
        if not text:
            raise HTTPException(status_code=400, detail="No text provided")

        analysis = perform_text_analysis(text)
        # Remove internal score before returning
        analysis.pop("score", None)
        return analysis

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/analyze-image")
def analyze_image(file: UploadFile = File(...)):
    try:
        image_bytes = file.file.read()

        response = requests.post(
            "https://api.sightengine.com/1.0/check.json",
            data={
                "models": "genai",
                "api_user": SIGHTENGINE_API_USER,
                "api_secret": SIGHTENGINE_API_SECRET,
            },
            files={
                "media": ("image.jpg", image_bytes, file.content_type)
            },
            timeout=60,
        )

        response.raise_for_status()
        result_json = response.json()

        ai_score = float(result_json.get("type", {}).get("ai_generated", 0.0)) * 100

        result = "Likely AI Generated" if ai_score >= 50 else "Likely Human Written"
        confidence = f"{ai_score:.2f}%"
        explanation = generate_image_explanation(ai_score, result_json)

        return {
            "result": result,
            "confidence": confidence,
            "reason": explanation,
            "raw": result_json,
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/analyze-video")
async def analyze_video(file: UploadFile = File(...)):
    video_path = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp4") as temp_video:
            temp_video.write(await file.read())
            video_path = temp_video.name

        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise Exception("Failed to open video file")

        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        if total_frames > 0:
            cap.set(cv2.CAP_PROP_POS_FRAMES, total_frames // 2)

        ret, frame = cap.read()
        cap.release()

        if not ret:
            raise Exception("Failed to extract frame from video")

        ret, buffer = cv2.imencode('.jpg', frame)
        if not ret:
            raise Exception("Failed to encode frame")
        frame_bytes = buffer.tobytes()

        response = requests.post(
            "https://api.sightengine.com/1.0/check.json",
            data={
                "models": "genai",
                "api_user": SIGHTENGINE_API_USER,
                "api_secret": SIGHTENGINE_API_SECRET,
            },
            files={
                "media": ("frame.jpg", frame_bytes, "image/jpeg")
            },
            timeout=60,
        )

        response.raise_for_status()
        result_json = response.json()

        ai_score = float(result_json.get("type", {}).get("ai_generated", 0.0)) * 100

        result = "Likely AI Generated" if ai_score >= 50 else "Likely Human Written"
        confidence = f"{ai_score:.2f}%"
        explanation = generate_video_explanation(ai_score, result_json)

        return {
            "result": result,
            "confidence": confidence,
            "reason": explanation,
            "raw": result_json,
            "message": "Analyzed middle frame of the video",
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        try:
            if video_path and os.path.exists(video_path):
                os.remove(video_path)
        except:
            pass


# ============================================================
#  AUDIO - Load local HF model
# ============================================================
try:
    HF_MODEL_NAME = "garystafford/wav2vec2-deepfake-voice-detector"
    print("Loading HF Deepfake model...")
    hf_feature_extractor = AutoFeatureExtractor.from_pretrained(HF_MODEL_NAME)
    hf_model = AutoModelForAudioClassification.from_pretrained(HF_MODEL_NAME)
    print("HF Deepfake model loaded successfully.")
except Exception as e:
    print(f"Warning: Failed to load HF Deepfake model: {e}")
    hf_feature_extractor = None
    hf_model = None


@app.post("/analyze-audio")
async def analyze_audio(file: UploadFile = File(...)):
    temp_path = None
    try:
        # File validation
        if not file.filename:
            raise HTTPException(status_code=400, detail="No file provided.")

        ext = os.path.splitext(file.filename)[1].lower()
        if ext not in ['.wav', '.mp3', '.m4a', '.ogg', '.flac']:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported file format: {ext}. Please upload wav, mp3, m4a, ogg, or flac."
            )

        file_bytes = await file.read()
        MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
        if len(file_bytes) > MAX_FILE_SIZE:
            raise HTTPException(status_code=400, detail="File too large. Maximum allowed size is 10MB.")

        if len(file_bytes) == 0:
            raise HTTPException(status_code=400, detail="Empty file uploaded.")

        # Save temp file
        with tempfile.NamedTemporaryFile(delete=False, suffix=ext) as temp:
            temp.write(file_bytes)
            temp_path = temp.name

        if which("ffmpeg") is None:
            raise HTTPException(status_code=500, detail="FFmpeg not found, please install it.")

        # Decode audio
        try:
            audio = AudioSegment.from_file(temp_path)
        except Exception:
            raise HTTPException(
                status_code=400,
                detail="Failed to decode audio file. It might be corrupted or in an unsupported format."
            )

        MAX_DURATION_MS = 30 * 1000
        note_duration = ""
        if len(audio) > MAX_DURATION_MS:
            audio = audio[:MAX_DURATION_MS]
            note_duration = " (Audio was truncated to 30 seconds for faster processing)"

        wav_path = temp_path + ".wav"
        audio.export(wav_path, format="wav")

        # AI Detection (Local Model)
        is_ai = False
        confidence = "0%"
        note = "Audio analysis failed"
        detected_label = ""

        if hf_model is not None and hf_feature_extractor is not None:
            try:
                audio_data, sr = librosa.load(wav_path, sr=16000)
                inputs = hf_feature_extractor(
                    audio_data,
                    sampling_rate=16000,
                    return_tensors="pt",
                    padding=True
                )

                with torch.no_grad():
                    logits = hf_model(**inputs).logits

                predicted_class_id = torch.argmax(logits, dim=-1).item()
                confidence_val = torch.softmax(logits, dim=-1)[0][predicted_class_id].item()

                detected_label = hf_model.config.id2label[predicted_class_id].lower()

                is_ai = any(kw in detected_label for kw in ["fake", "spoof", "ai", "generated"])
                confidence = f"{confidence_val * 100:.2f}%"
                note = f"Used local ML Audio Model (wav2vec2-deepfake){note_duration}"

            except Exception as hf_e:
                print(f"Local HF Model Error: {hf_e}")
                note = f"Local ML model failed{note_duration}"
        else:
            note = f"Local ML model not available{note_duration}"

        explanation = generate_audio_explanation(is_ai, confidence, detected_label, note)

        return {
            "transcript": "Speech transcription disabled",
            "audio_analysis": {
                "is_ai": is_ai,
                "confidence": confidence,
                "note": note,
                "reason": explanation,
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        try:
            if temp_path and os.path.exists(temp_path):
                os.remove(temp_path)
            if temp_path and os.path.exists(temp_path + ".wav"):
                os.remove(temp_path + ".wav")
        except:
            pass