# Exemplary backup script that moves the large files which are in .gitignore from one local reository to another
mv ../media_discourse_research/.Renviron .Renviron

mv --backup=t ../media_discourse_research/1.data_sources/media_articles/data/full/chunks 1.data_sources/media_articles/data/full/

mv --backup=t ../media_discourse_research/1.data_sources/media_articles/data/annotations/chunks/ 1.data_sources/media_articles/data/annotations/

mv --backup=t ../media_discourse_research/2.data_transformations/media_articles/data/regex_processed/chunks/ 2.data_transformations/media_articles/data/regex_processed/

mv --backup=t ../media_discourse_research/2.data_transformations/media_articles/data/udpipe_processed/chunks/ 2.data_transformations/media_articles/data/udpipe_processed/

mv --backup=t ../media_discourse_research/4.data_analysis/named_entity_recognition/data/chunks/ 4.data_analysis/named_entity_recognition/data/

mv --backup=t ../media_discourse_research/1.data_sources/twitter/data/ 1.data_sources/twitter/

mv --backup=t ../media_discourse_research/4.data_analysis/word_embeddings/data/models 4.data_analysis/word_embeddings/data/
