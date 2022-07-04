import os
from time import time
import pandas as pd
import torch
from transformers import AutoTokenizer, AutoModelForTokenClassification, pipeline
from pyreadr import read_r, write_rds
from datasets import Features, Value, Dataset
from transformers.pipelines.pt_utils import KeyDataset
from tqdm.auto import tqdm
# Get python version
import sys
print(sys.version)
# Download the model section, run once
os.environ["MODEL_URL"] = "https://air.kiv.zcu.cz/public/CZERT-B_fb.zip"

os.system("""
mkdir model
wget $MODEL_URL -O model/model.zip
unzip -j -d model/ model/model.zip
rm model/model.zip
""")

# Specify path to input and output files
path_to_input = "2.data_transformations/media_articles/data/regex_processed/chunks/"
path_to_output = "4.data_analysis/sentiment_analysis/data/chunks/"
model_path = "4.data_analysis/sentiment_analysis/data/model"

# Detect if GPU availabe
if torch.cuda.is_available():
    print("GPU acceleration available")
    print("\nNr. of CUDA devices:")
    torch.cuda.device_count()
    print("\nCurrent device nr.:")
    torch.cuda.current_device()
    print("\nCurrent device name:")
    torch.cuda.get_device_name(0)
    print("\nCurrent device properties:")
    torch.cuda.get_device_properties(0)
else:
    print("GPU acceleration not available")
# Also, we could check for more details about the GPU:
os.system("nvidia-smi")

# Specify the sentiment_analysis model parameters.
tokenizer = AutoTokenizer.from_pretrained(
    pretrained_model_name_or_path=model_path, model_max_length=512)
model = AutoModelForTokenClassification.from_pretrained(
    pretrained_model_name_or_path=model_path)
# Choose pipeline based on whether GPU is available.
processing_device = 0 if torch.cuda.is_available() else -1
# 0 and higher are CUDA devices and -1 is CPU
get_sentiment = pipeline("token-classification",
                         model=model, tokenizer=tokenizer, device=processing_device)

# Get list with all of the .rds files in the input directory.
regex_files = [file for file in os.listdir(
    path_to_input) if file.endswith(".rds")][:1]
regex_files.sort()

# Outer loop over the files in the input directory.
for file in regex_files:
    # drive.mount('/content/drive', force_remount=True)
    # Reading one chunk from the input directory
    # Testing with first two texts.
    regex_chunk = read_r(path_to_input + file)[None]

    regex_chunk = Dataset.from_pandas(regex_chunk, features=Features(
        {'article_id': Value('string'), 'text': Value('string')}))

    print(
        f"Starting sentinment analysis for chunk {file}. File contains {regex_chunk.shape[0]} articles.", flush=True)
    # Inner loop over the individual texts in the dataframe. We can use batching, but for longer text sizes, it does not seem to make much (if any) difference.
    sentiment_dict = {id: sum(item['score'] for item in result) / len(result) for id, result in zip(tqdm(
        KeyDataset(regex_chunk, "article_id")), get_sentiment(KeyDataset(regex_chunk, "text"), batch_size=1))}

    sentiment_df = pd.DataFrame(sentiment_dict.items(), columns=[
        'article_id', 'sentiment'])
    write_rds(f"{path_to_output}sentiment_{file}", sentiment_df)
    print(f"Finished the sentiment analysis of the chunk {file}", flush=True)
    # drive.flush_and_unmount()
    print('All changes made in this Colab session should now be visible in Drive.', flush=True)
# End of outer loop.
print("Finished the sentiment analysis of all chunks.")
