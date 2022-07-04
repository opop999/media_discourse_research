import os
from time import time
import pandas as pd
from numpy.ma.core import mean
import torch
from transformers import AutoTokenizer, AutoModelForTokenClassification, pipeline

os.getcwd()


torch.cuda.is_available()

tokenizer = AutoTokenizer.from_pretrained(
    pretrained_model_name_or_path="4.data_analysis/sentiment_analysis/", model_max_length=512)

model = AutoModelForTokenClassification.from_pretrained(
    pretrained_model_name_or_path="4.data_analysis/sentiment_analysis/")

nlp = pipeline("token-classification", model=model, tokenizer=tokenizer)

example = """
Záchod, který využívá moč k výrobě elektřiny a dokáže nabít mobilní telefon, by už brzy mohl zlepšit život v uprchlických táborech.\n\nZáchod, který využívá moč k výrobě elektřiny a dokáže nabít mobilní telefon, by už brzy mohl zlepšit život v uprchlických táborech. Studenti v Británii testují nový vynález, který vznikl ve spolupráci s humanitární organizací Oxfam a Západoanglickou univerzitou v Bristolu.\n\nPrůkopnická toaleta využívá živé mikroby, kteří se živí močí a přeměňují ji na elektřinu.\n\"Život v uprchlickém táboře je dost tvrdý i bez hrozby toho, že vás někdo napadne uprostřed noci na temném místě. Potenciál tohoto vynálezu je velký,\" řekl Andy Bastable, šéf odboru pro vodu a sanitární vybavení Oxfam . \n\nPrvní nová toaleta bude do některého z uprchlických táborů poslána během šesti měsíců, a po zkušebním provozu se distribuce těchto zařízení rozšíří. Nejprve do táborů, a později možná i na další místa bez elektřiny. Kromě představy pomoci v uprchlických táborech vědci oceňují také to, že jde o naprosto ekologickou metodu výroby elektřiny, která nevyžaduje žádná fosilní paliva - jen spoustu moči.
"""

example = example.lower() \
    .replace(r"[^ěščřžýáíéóúůďťňa-z\.\?\! ]", " ") \
    .replace(r"\.{2,}", ".") \
    .strip() \
    .replace(r"  +", " ") \

example = ' '.join(example.split())

start = time()
ner_results = nlp(example)

print(f'Time taken to run: {time() - start} seconds')

df = pd.DataFrame(ner_results)
# arrange the dataframe by column values
df.sort_values("score", ascending=False, inplace=True)
print(df)

print(mean(df["score"]))
