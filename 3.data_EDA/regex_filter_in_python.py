import pandas as pd
df = pd.read_feather(
    "/home/andy/Media_discourse_research/1.data_sources/twitter/data/binded_tweets.feather")
df_migration = df[df['text'].str.contains(
    "(?i)(běženec\w*)|(běženk\w*)|(imigrant\w*)|(migra\w*)|(imigra\w*)|(přistěhoval\w*)|(uprchl\w*)|(utečen\w*)|(azylant\w*)")]
df_migration.shape
df_migration.reset_index().to_feather("python_migration_filtered.feather")
