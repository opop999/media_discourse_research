# This script demonstrates the utility of using SHAP library to explain inferences
# of deep learning models (XAI:Explainable Artificial Intelligence)

import os
import shap
from torch import cuda
from transformers import AutoTokenizer, AutoModelForSequenceClassification, pipeline
from pyreadr import read_r

# This is an example of a fine tuned binary text classification model, downloaded from:
# https://huggingface.co/horychtom/czech_media_bias_classifier
# Its tokenizer config, special tokens map and vocab are downloaded from:
# https://huggingface.co/fav-kky/FERNET-C5
MODEL_PATH = "4.data_analysis/sentiment_analysis/data/model"
PATH_TO_INPUT = "2.data_transformations/media_articles/data/udpipe_processed/chunks/"

# Get list with all of the .rds files in the input directory.
udpipe_files = [file for file in os.listdir(
    PATH_TO_INPUT) if file.endswith(".rds")]
udpipe_files.sort()

# Load one Czech text article from one dataset to serve as a demonstration example for SHAP.
udpipe_articles = read_r(PATH_TO_INPUT + udpipe_files[0])[None][["doc_id", "sentence_id", "token"]] \
    .groupby(['doc_id', "sentence_id"], sort=False, as_index=False) \
    .agg(
    tokens=("token", " ".join)) \
    .groupby(['doc_id'], sort=False, as_index=False) \
    .agg(
    text=("tokens", list)
).iloc[0, 1][:10]  # get first 10 sentences, since SHAP calculation takes some time.


# Testing with text (not token!) classification models, as SHAP does not seem to support them.
tokenizer = AutoTokenizer.from_pretrained(
    pretrained_model_name_or_path=MODEL_PATH, model_max_length=512)
model = AutoModelForSequenceClassification.from_pretrained(MODEL_PATH)
# Note that we have set top_k=3 for the pipeline so we can observe the model’s behavior for all classes, not just the top output.
classifier = pipeline("sentiment-analysis",
                      model=model,
                      tokenizer=tokenizer,
                      device=0 if cuda.is_available() else -1,
                      max_length=512,
                      padding="longest",
                      truncation=True,
                      top_k=3)

# Set up SHAP pipeline
explainer = shap.Explainer(classifier)

# Model inference
results = classifier(udpipe_articles)
print(results)
# Get values for SHAP
shap_values = explainer(udpipe_articles)

# Visualize the results (works in Jupyter or other IPython environments)
shap.plots.text(shap_values[0, :, :])
shap.plots.bar(shap_values[0, :, "LABEL_0"])
