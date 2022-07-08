# Workflow for sentiment analysis using BERT-like model on an individual sentence level.
# * This workflow is intended to be run in the cloud on GPU.
# * It uses UDPIPE processed data, which are separated by sentences.

"""Import necessary modules."""
import os
from pathlib import Path
from time import time
from json import dump
from torch import cuda
from transformers import AutoTokenizer, AutoModelForSequenceClassification, pipeline
from pyreadr import read_r
from datasets import Sequence, Features, Value, Dataset
from tqdm.auto import tqdm


def get_gpu_info():
    """Get the GPU information, if available."""
    if cuda.is_available():
        print("GPU acceleration available")
        print(f"\nNr. of CUDA devices: {cuda.device_count()}")
        print(f"\nCurrent device nr.: {cuda.current_device()}")
        print(f"\nCurrent device name: {cuda.get_device_name(0)}")
        print(f"\nCurrent device properties: {cuda.get_device_properties(0)}")
        # Also, we could check for more details about the GPU:
        print(os.system("nvidia-smi"))
    else:
        print("GPU acceleration not available")


def model_download(model_path: str, model_url: str, overwrite_existing: bool = False) -> None:
    """Downloads selected model from specified url if it does not exist already.

    Args:
        model_path (str): Path to the model.
        model_url (str): Url to the model.
        overwrite_existing (bool, optional): Defaults to False.
    """
    if not os.path.exists(model_path) or overwrite_existing:
        os.system(f"""
        mkdir -p {model_path}
        wget {model_url} -O {model_path}/model.zip
        unzip -j -d {model_path} {model_path}/model.zip
        rm {model_path}/model.zip
        """)
        print(f"Model downloaded to folder {model_path}")
    else:
        print("Model already downloaded.")


def configure_analytical_pipeline(model_path: str, processing_device: int):
    """Configures the pipeline for the sentiment analysis using the specified model.

    Args:
        model_path (str): Path to the model.
        processing_device (int): Device to use for processing. 0 for GPU, -1 for CPU.

    Returns:
        _type_: Pipeline
    """
    tokenizer = AutoTokenizer.from_pretrained(
        pretrained_model_name_or_path=model_path,
        model_max_length=512)
    model = AutoModelForSequenceClassification.from_pretrained(
        pretrained_model_name_or_path=model_path)
    return pipeline("sentiment-analysis",
                    model=model,
                    tokenizer=tokenizer,
                    device=processing_device,
                    max_length=512,
                    padding="longest",
                    truncation=True)


def get_only_new_files(path_to_input: str, path_to_output: str) -> list:
    """Get all files in the input directory that are not already in the output directory.

    Args:
        path_to_input (str): Path to the input directory.
        path_to_output (str): Path to the output directory.

    Returns:
        list: List of files in the input directory that are not already in the output directory.
    """
    if not os.path.exists(path_to_output):
        # create directory if it doesn't exist
        os.makedirs(path_to_output)
    existing_processed_files = {Path(file.replace("sentiment_", "")).stem for file in os.listdir(
        path_to_output) if file.endswith((".rds", ".json"))}
    return sorted(({Path(file).stem for file in os.listdir(
        path_to_input) if file.endswith(".rds")} - existing_processed_files))


def filter_by_years(input_files: list, year_filter: list) -> tuple:
    """Filter the files by the specified years.

    Args:
        input_files (list): List of files in the input directory.
        year_filter (list): List of years to filter by.

    Returns:
        tuple: Tuple of filtered files.
    """
    return tuple(file for file in input_files if any(
        year in file for year in year_filter))


# Outer loop over the files in the input directory.
def sentiment_analysis_workflow(path_to_input: str,
                                path_to_output: str,
                                model_pipeline,
                                input_files_filtered: tuple,
                                batch_by: int = 1) -> None:
    """Performs the sentiment analysis workflow on selected files from the input directory.

    Args:
        path_to_input (str): Path to the input directory.
        path_to_output (str): Path to the output directory.
        model_pipeline (_type_): Pipeline for the sentiment analysis.
        input_files_filtered (tuple): Tuple of filtered files.
        batch_by (int, optional): Size of the batch send to the model pipeline. Defaults to 1.
    """
    print(
        f"Starting sentiment analysis workflow on {len(input_files_filtered)} files.")
    for count, file in enumerate(input_files_filtered, start=1):
        # Reading one chunk from the input directory
        udpipe_chunk = read_r(f"{path_to_input + file}.rds")[None][["doc_id", "sentence_id", "token"]] \
            .groupby(['doc_id', "sentence_id"], sort=False, as_index=False) \
            .agg(
                tokens=("token", " ".join)) \
            .groupby(['doc_id'], sort=False, as_index=False) \
            .agg(
                text=("tokens", list)
        )

        udpipe_chunk = Dataset.from_pandas(udpipe_chunk[:100], features=Features(
            {"doc_id": Value(dtype="string", id=None),
             "text": Sequence(feature=Value(dtype='string', id=None),
                              length=-1, id=None)}))

        print(
            f"""Starting sentinment analysis for chunk {file}.
            File contains {udpipe_chunk.shape[0]} articles.""", flush=True)
        # Inner loop over the individual texts in the dataframe. We can use batching,
        # but for longer text sizes, it does not seem to make much (if any) difference.
        sentiment_dict = {document["doc_id"]: model_pipeline(
            document["text"], batch_size=batch_by) for document in tqdm(udpipe_chunk)}

        with open(file=f"{path_to_output}sentiment_{file}.json", mode="w", encoding="utf8") as out:
            dump(sentiment_dict, out, sort_keys=False)

        print(
            f"Finished the sentiment analysis of the chunk {file}, nr. {count} out of {len(input_files_filtered)}.",
            flush=True)
        print("All changes made in this session should now be visible locally.", flush=True)
# End of outer loop.
    print("Finished the sentiment analysis of all chunks.")


# Specify path to input and output files
PATH_TO_INPUT = "2.data_transformations/media_articles/data/udpipe_processed/chunks/"
PATH_TO_OUTPUT = "4.data_analysis/sentiment_analysis/data/chunks/"
MODEL_PATH = "4.data_analysis/sentiment_analysis/data/model"
MODEL_URL = "https://air.kiv.zcu.cz/public/CZERT-B_fb.zip"
YEAR_FILTER = ["udpipe_regex_full_articles_2015-01_part_1"]
DEVICE = 0 if cuda.is_available() else -1
BATCH_BY = 4

# Detect if GPU availabe
get_gpu_info()

# Download the model, run once
model_download(
    model_path=MODEL_PATH,
    model_url=MODEL_URL,
    overwrite_existing=False)

# Choose pipeline based on whether GPU is available. 0 and higher are CUDA devices and -1 is CPU
model_configured = configure_analytical_pipeline(
    model_path=MODEL_PATH, processing_device=DEVICE)

udpipe_files = get_only_new_files(
    path_to_input=PATH_TO_INPUT, path_to_output=PATH_TO_OUTPUT)

udpipe_files_filtered = filter_by_years(
    input_files=udpipe_files, year_filter=YEAR_FILTER)

start_time = time()
sentiment_analysis_workflow(
    path_to_input=PATH_TO_INPUT,
    path_to_output=PATH_TO_OUTPUT,
    model_pipeline=model_configured,
    input_files_filtered=udpipe_files_filtered,
    batch_by=BATCH_BY)
print(f"Finished sentiment analysis in {time() - start_time} seconds.")
