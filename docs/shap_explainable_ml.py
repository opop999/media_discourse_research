# This script demonstrates the utility of using SHAP library to explain inferences
# of deep learning models (XAI:Explainable Artificial Intelligence)

import os
import shap
from transformers import AutoTokenizer, AutoModelForSequenceClassification, pipeline
from pyreadr import read_r

# This is an example of a fine tuned binary text classification model, downloaded from:
# https://huggingface.co/horychtom/czech_media_bias_classifier
# Its tokenizer config, special tokens map and vocab are downloaded from:
# https://huggingface.co/fav-kky/FERNET-C5
model_path = "4.data_analysis/sentiment_analysis/data/model"
path_to_input = "2.data_transformations/media_articles/data/regex_processed/chunks/"

# Get list with all of the .rds files in the input directory.
regex_files = [file for file in os.listdir(
    path_to_input) if file.endswith(".rds")]
regex_files.sort()

# Load one Czech text article from one dataset to serve as a demonstration example for SHAP.
example_article = read_r(path_to_input + regex_files[0])[None].iloc[0, 1]

# Testing with text (not token!) classification models, as SHAP does not seem to support them.
tokenizer = AutoTokenizer.from_pretrained(
    pretrained_model_name_or_path=model_path, model_max_length=512)
model = AutoModelForSequenceClassification.from_pretrained(model_path)
# Note that we have set top_k=1 for the pipeline so we can observe the model’s behavior for all classes, not just the top output.
classifier = pipeline('text-classification', model=model, tokenizer=tokenizer,
                      top_k=1)
# Set up SHAP pipeline
explainer = shap.Explainer(classifier)

# Because the model only accepts a maximum of 512 tokens, we need to shorten the length of the text.
# Since SHAP calculation takes some time, we will use only first 50 words.
short_text = [tokenizer.decode(tokenizer.encode(
    example_article, truncation=True, max_length=50, add_special_tokens=False))]

# Model inference
classifier(short_text)
# Get values for SHAP
shap_values = explainer(short_text)

# Visualize the results (works in Jupyter or other IPython environments)
shap.plots.text(shap_values[:, :, ])
shap.plots.bar(shap_values[0, :, "LABEL_0"])
