from pyreadr import read_r, write_rds
import os
from time import time
from pprint import pprint
from datasets import Features, Value, Dataset
from transformers import AutoTokenizer, AutoModelForTokenClassification, pipeline
from transformers.pipelines.pt_utils import KeyDataset
import pandas as pd
from tqdm.auto import tqdm

# Specify path to input and output files
path_to_input = "2.data_transformations/media_articles/data/regex_processed/chunks/"
model_path = "4.data_analysis/sentiment_analysis/data/model"

regex_files = [file for file in os.listdir(
    path_to_input) if file.endswith(".rds")]
regex_files.sort()

file_loaded = read_r(path_to_input + regex_files[0])[None].iloc[:128]

dataset = Dataset.from_pandas(file_loaded, features=Features(
    {'article_id': Value('string'), 'text': Value('string')}))

# Specify the sentiment_analysis model parameters.
tokenizer = AutoTokenizer.from_pretrained(
    pretrained_model_name_or_path=model_path, model_max_length=512, padding="longest", truncation=True, max_length=512)
model = AutoModelForTokenClassification.from_pretrained(
    pretrained_model_name_or_path=model_path)
# 0 and higher are CUDA devices and -1 is CPU
get_sentiment = pipeline("token-classification",
                         model=model, tokenizer=tokenizer, device=0)

# Testing speed for different batch sizes
for batch_size in [1, 2,  4, 8, 16, 32, 64]:
    print("-" * 30)
    print(f"Streaming batch_size={batch_size}")
    for _ in tqdm(get_sentiment(KeyDataset(dataset, "text"), batch_size=batch_size), total=len(dataset)):
        pass

# def encode(batch):
#     return tokenizer(batch["text"], padding="longest", truncation=True, max_length=512, return_tensors="pt")
# dataset.set_transform(encode)
# dataset.format

encoded_dataset = dataset.map(lambda examples: tokenizer(
    examples['text'], padding="longest", truncation=True, max_length=512), batched=True)
# Use get_sentiment to get the sentiment scores from the encoded_dataset.
sentiment_scores = encoded_dataset.map(get_sentiment)

#encoded_dataset = dataset.map(lambda examples: tokenizer(dataset["text"]), batched=True)

start = time()
test_output = get_sentiment(encoded_dataset, batch_size=100)
print(f"Article {id} took {time() - start} seconds.", flush=True)

sentiment_dict = {id: text.split(".") for id, text in zip(
    dataset["article_id"][:10], dataset["text"][:10])}

sentiment_df = pd.DataFrame(test_output)
