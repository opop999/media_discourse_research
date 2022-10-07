from bertopic import BERTopic
from sklearn.datasets import fetch_20newsgroups

# Load the 20 newsgroups dataset
docs = fetch_20newsgroups(subset='all',  remove=(
    'headers', 'footers', 'quotes'))['data']

# Summary statistics on the docs list
print(f"Number of documents: {len(docs)}")
print(f"Number of unique documents: {len(set(docs))}")
print(
    f"Number of documents with length 0: {len([doc for doc in docs if len(doc) == 0])}")


topic_model = BERTopic(language="multilingual")
topics, probs = topic_model.fit_transform(docs)
