# Import gensim library and arrow
import json
import re
import gensim
import pandas as pd

with open("2.data_transformations/media_articles/data/stopwords_cs.json") as json_file:
    stop_words = json.load(json_file)

df = pd.read_feather(
    "1.data_sources/media_articles/data/disinfo_articles.feather")


def preprocess(sentence):
    return [word for word in re.sub(r"[^ěščřžýáíéóúůďťňĎŇŤŠČŘŽÝÁÍÉÚŮĚÓa-zA-Z ]", " ", sentence).strip().lower().split() if word not in stop_words]


doc_1 = preprocess(df["full_text"][1])
doc_2 = preprocess(df["full_text"][2])

# Load local pretrained Word2Vec model (this should better be a generalized model of the entire corpora)
model = gensim.models.KeyedVectors.load_word2vec_format(
    "4.data_analysis/word_embeddings/data/models/mainstream_2022", binary=True)
# Word Mover’s Distance (WMD) as an alternative to Doc2Vec
model.wmdistance(["migrant", "imigrant"], ["uprchlík", "azylant"])
distance = model.wmdistance(doc_1, doc_2)

print('distance = %.4f' % distance)
