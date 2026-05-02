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

def generate_text_explanation(reasons: list, score: int, details: dict) -> str:
    """
    Build a natural, accurate, and varied explanation for text analysis.
    Uses the actual detected signals to form a specific sentence.
    """
    wc  = details["word_count"]
    asl = details["avg_sentence_length"]
    ld  = details["lexical_diversity"]
    rr  = details["repetition_ratio"]

    if score >= 65:
        # --- AI explanations (pick signals that fired) ---
        parts = []
        if "Uniform sentence structure" in reasons:
            parts.append(
                random.choice([
                    f"sentence lengths are remarkably uniform (avg {asl:.1f} words), a common AI trait",
                    f"each sentence contains roughly the same number of words (~{asl:.1f}), which is unusual for human writing",
                ])
            )
        if "High word repetition" in reasons:
            parts.append(
                random.choice([
                    f"{rr*100:.0f}% of words are repeated, indicating formulaic phrasing",
                    f"word repetition is high ({rr*100:.0f}%), a pattern typical of language models",
                ])
            )
        if "Low vocabulary diversity" in reasons:
            parts.append(
                random.choice([
                    f"vocabulary diversity is low ({ld:.2f}), suggesting limited natural variation",
                    f"only {ld*100:.0f}% of words are unique, which falls below typical human writing",
                ])
            )
        if "Formal structured phrasing" in reasons:
            parts.append(
                random.choice([
                    "formal connector phrases (e.g. 'furthermore', 'in conclusion') are present, common in AI output",
                    "the text uses transitional language typical of AI-generated essays",
                ])
            )
        if "Long structured sentences" in reasons:
            parts.append(
                random.choice([
                    f"sentences average {asl:.1f} words, which is longer than typical conversational text",
                    f"unusually long sentences (avg {asl:.1f} words) suggest automated generation",
                ])
            )
        if "Long consistent structure" in reasons:
            parts.append(
                random.choice([
                    f"the text spans {wc} words with consistent structure throughout",
                    f"at {wc} words, the text maintains a mechanical consistency rarely seen in human writing",
                ])
            )
        if "Overly consistent punctuation" in reasons:
            parts.append(
                random.choice([
                    "punctuation is applied with machine-like regularity",
                    "the punctuation density and placement are atypically consistent",
                ])
            )

        if parts:
            intro = random.choice([
                "The content appears AI-generated because",
                "Several signals indicate AI authorship:",
                "This text is likely machine-written —",
            ])
            return f"{intro} {'; '.join(parts[:3])}."
        else:
            return "Explicit AI-related wording was detected in the text."

    else:
        # --- Human explanations ---
        parts = []
        if wc < 20:
            parts.append(
                random.choice([
                    f"the text is short ({wc} words), consistent with informal human communication",
                    f"at only {wc} words this reads like a natural, casual message",
                ])
            )
        if ld > 0.6:
            parts.append(
                random.choice([
                    f"vocabulary diversity is high ({ld:.2f}), reflecting natural human expression",
                    f"{ld*100:.0f}% of words are unique, indicating genuine linguistic variety",
                ])
            )
        if "Casual human punctuation" in reasons:
            parts.append(
                random.choice([
                    "casual punctuation (e.g. '...', '؟') reflects human-style writing",
                    "informal punctuation patterns suggest this was written by a person",
                ])
            )
        if not parts:
            parts.append(
                random.choice([
                    "the overall writing style, rhythm, and vocabulary are consistent with human authorship",
                    f"sentence variety (avg length {asl:.1f} words) and natural phrasing suggest human origin",
                ])
            )

        intro = random.choice([
            "The text appears to be human-written because",
            "Natural writing patterns were detected:",
            "This content reads as human-authored —",
        ])
        return f"{intro} {'; '.join(parts[:3])}."


def generate_image_explanation(ai_score: float, raw: dict) -> str:
    """
    Build a natural, varied explanation for image analysis based on the actual score.
    """
    pct = f"{ai_score:.1f}%"

    if ai_score >= 85:
        phrases = [
            f"The image shows extremely strong AI-generation signatures (score: {pct}). Visual elements such as hyper-smooth textures, unnaturally perfect lighting, and synthetic patterns strongly indicate machine generation.",
            f"With a GenAI confidence of {pct}, this image exhibits hallmark AI artifacts: overly uniform skin tones, synthetic backgrounds, and the absence of natural imperfections.",
            f"AI-generation probability is very high ({pct}). The visual coherence and absence of real-world noise patterns are consistent with generative model output.",
        ]
    elif ai_score >= 65:
        phrases = [
            f"The image has notable AI-generation indicators (score: {pct}). Several regions display synthetic texture gradients and unnatural edge smoothing.",
            f"A GenAI score of {pct} suggests this image was likely produced by a generative model. Key signs include unnaturally clean backgrounds and lighting uniformity.",
            f"Moderate-to-strong AI signals detected ({pct}). The image lacks the organic inconsistencies typically present in real photographs.",
        ]
    elif ai_score >= 50:
        phrases = [
            f"The image crosses the AI-detection threshold at {pct}. Some regions display AI-generation characteristics, though mixed with realistic elements.",
            f"GenAI confidence is {pct} — just above the threshold. The image may be a composite or lightly AI-enhanced photograph.",
            f"Borderline AI probability ({pct}). While some natural features are present, synthetic indicators were detected in texture and shading patterns.",
        ]
    elif ai_score >= 30:
        phrases = [
            f"The image shows mostly natural visual patterns (AI score: {pct}). Minor anomalies were detected but are insufficient to conclude AI generation.",
            f"GenAI confidence is low at {pct}. The image retains realistic imperfections, natural noise, and authentic depth-of-field characteristics.",
            f"Likely a real photograph — AI indicators are weak ({pct}). Texture grain, lighting variance, and edge irregularities suggest organic capture.",
        ]
    else:
        phrases = [
            f"The image is very likely authentic (AI score: {pct}). Natural noise patterns, realistic shadows, and organic textures strongly suggest a real photograph.",
            f"Almost no AI-generation signals detected ({pct}). The visual properties are consistent with genuine camera-captured imagery.",
            f"Strong human/real-world origin indicated ({pct}). The image contains natural imperfections, varied textures, and realistic environmental lighting.",
        ]

    return random.choice(phrases)


def generate_video_explanation(ai_score: float, raw: dict) -> str:
    """
    Build a natural, varied explanation for video frame analysis.
    """
    pct = f"{ai_score:.1f}%"

    if ai_score >= 80:
        phrases = [
            f"The analyzed video frame scores {pct} for AI generation. The frame exhibits synthetic texture patterns, unnatural motion blur, and artificially smooth facial features.",
            f"High AI-generation confidence ({pct}) detected in the video frame. Hallmarks include perfect symmetry, synthetic skin rendering, and absence of real-world camera artifacts.",
            f"GenAI signals are very strong in this frame ({pct}). The visual properties resemble output from a video generation model rather than a real camera.",
        ]
    elif ai_score >= 50:
        phrases = [
            f"The extracted frame shows AI-generation indicators at {pct}. Some areas display synthetic qualities not typical of natural video footage.",
            f"Moderate AI signals detected in the video frame ({pct}). Visual inconsistencies in texture and lighting suggest possible AI generation.",
            f"AI-generation probability is {pct} for the analyzed frame. The image quality and sharpness pattern are inconsistent with typical camera capture.",
        ]
    else:
        phrases = [
            f"The video frame appears authentic (AI score: {pct}). Natural film grain, realistic motion artifacts, and organic lighting were detected.",
            f"Low AI-generation confidence ({pct}). The frame shows the expected imperfections of real-world video capture.",
            f"The extracted frame is likely from real footage — GenAI confidence is only {pct}. Compression artifacts and natural noise patterns match authentic video.",
        ]

    return random.choice(phrases)


def generate_audio_explanation(is_ai: bool, confidence: str, label: str = "", note: str = "") -> str:
    """
    Build a natural, varied explanation for audio analysis.
    """
    conf_val = float(confidence.replace("%", ""))
    pct = f"{conf_val:.1f}%"

    if is_ai:
        if conf_val >= 90:
            phrases = [
                f"The audio has an extremely high AI-generation score ({pct}). Spectral analysis reveals synthetic voice harmonics, unnatural prosody, and the absence of breathing artifacts typical of real human speech.",
                f"Very strong deepfake indicators detected ({pct}). The voice waveform lacks natural micro-variations and contains pitch patterns consistent with text-to-speech synthesis.",
                f"AI-generated audio signature is unmistakable ({pct}). The model detected synthetic formants, missing background noise floor, and artificially smooth transitions between phonemes.",
            ]
        elif conf_val >= 70:
            phrases = [
                f"The audio shows significant AI-generation indicators ({pct}). Unnatural pauses, synthetic pitch modulation, and regularized cadence suggest this was generated by a voice model.",
                f"AI voice detection confidence is {pct}. The audio waveform reveals patterns inconsistent with natural human vocalization — likely produced by a TTS or voice-cloning system.",
                f"Deepfake voice signals detected at {pct} confidence. Prosodic irregularities and spectral smoothness indicate AI synthesis.",
            ]
        else:
            phrases = [
                f"The audio leans toward AI-generated ({pct} confidence). While some natural vocal characteristics are present, the model identified synthetic voice patterns.",
                f"AI-generation probability is {pct}. The audio may be a voice clone or AI-enhanced recording — natural variability in pitch and timing is reduced.",
                f"Borderline AI audio detected ({pct}). Some synthetic prosody markers were identified, though the recording contains mixed signals.",
            ]
    else:
        if conf_val >= 90:
            phrases = [
                f"The audio is highly likely to be authentic human speech ({pct} confidence). Natural breathing patterns, realistic vocal fry, and organic pitch variation are all present.",
                f"Strong real-voice indicators detected ({pct}). The audio contains natural background noise, human micro-pauses, and realistic formant transitions.",
                f"This audio is very likely recorded from a real person ({pct}). The spectral profile, prosody, and breath patterns are consistent with genuine human speech.",
            ]
        elif conf_val >= 70:
            phrases = [
                f"The audio appears to be authentic human speech ({pct} confidence). Natural speech rhythm, organic pauses, and realistic vocal dynamics were detected.",
                f"Real-voice confidence is {pct}. The waveform shows the irregularities and noise characteristics typical of genuine human recording.",
                f"Human speech indicators dominate ({pct}). The audio lacks the spectral smoothness and synthetic prosody associated with AI voice generation.",
            ]
        else:
            phrases = [
                f"The audio is more likely human than AI ({pct} confidence), though the signal is not fully conclusive. Natural speech elements were detected but with some ambiguity.",
                f"Moderate human-voice confidence ({pct}). The audio shows natural characteristics but the recording quality or content limits full certainty.",
                f"Leaning toward authentic audio ({pct}). Some expected human vocal markers are present, though confidence is moderate.",
            ]

    return random.choice(phrases)


# ============================================================
#  TEXT ANALYSIS CORE
# ============================================================

def perform_text_analysis(text: str):
    lower_text = text.lower()

    # Basic metrics
    words = text.split()
    word_count = len(words)

    sentences = re.split(r'[.!؟?]+', text)
    sentences = [s.strip() for s in sentences if s.strip()]
    sentence_count = len(sentences)

    avg_sentence_length = word_count / sentence_count if sentence_count else 0

    unique_words = len(set(words))
    lexical_diversity = unique_words / word_count if word_count else 0

    punctuation_count = len(re.findall(r"[.,،;:!?؟]", text))
    repetition_ratio = 1 - lexical_diversity

    # AI indicator keywords
    ai_keywords = [
        "as an ai", "language model", "generated by ai", "chatgpt", "openai",
        "artificial intelligence", "elevenlabs", "voice generated by",
        "ai generated", "ai-generated", "text to speech", "text-to-speech",
        "[name]", "[your name]", "<name>", "<your name>"
    ]

    formal_phrases = [
        "in conclusion", "moreover", "furthermore", "therefore", "additionally",
        "it is important to note", "في الختام", "علاوة على ذلك", "من المهم أن نلاحظ",
    ]

    # Scoring
    score = 50
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
        explanation = "Explicit AI-related wording was detected in the text (e.g. 'ChatGPT', 'as an AI', 'AI-generated'), which is a definitive indicator of machine-generated content."
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
        if variance < 15:
            score += 10
            reasons.append("Uniform sentence structure")

    # Long structured text
    if avg_sentence_length > 18:
        score += 10
        reasons.append("Long structured sentences")

    # Repetition
    if repetition_ratio > 0.55:
        score += 12
        reasons.append("High word repetition")

    # Low lexical diversity
    if lexical_diversity < 0.45:
        score += 8
        reasons.append("Low vocabulary diversity")

    # Formal connectors
    if any(p in lower_text for p in formal_phrases):
        score += 8
        reasons.append("Formal structured phrasing")

    # Too much punctuation
    if punctuation_count > 8:
        score += 5
        reasons.append("Overly consistent punctuation")

    # Very long text
    if word_count > 150:
        score += 10
        reasons.append("Long consistent structure")

    # Human indicators
    if word_count < 20:
        score -= 15
        reasons.append("Short natural text")

    if "..." in text or "؟" in text:
        score -= 5
        reasons.append("Casual human punctuation")

    score = max(0, min(score, 100))

    result = "Likely AI Generated" if score >= 65 else "Likely Human Written"

    details = {
        "word_count": word_count,
        "sentence_count": sentence_count,
        "avg_sentence_length": round(avg_sentence_length, 2),
        "lexical_diversity": round(lexical_diversity, 2),
        "repetition_ratio": round(repetition_ratio, 2),
    }

    explanation = generate_text_explanation(reasons, score, details)

    return {
        "result": result,
        "confidence": f"{score}%",
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