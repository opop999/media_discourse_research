import fasttext

# Set thread to 1 if you want reproducible results
model = fasttext.train_unsupervised(
    '4.data_analysis/word_embedding/data/test_corp.txt', model='cbow', thread=12, verbose=2)

model.save_model('4.data_analysis/word_embedding/data/fasttext_model.bin')

model.predict("eu", k=3)
