# Testing the speed of regex matching on a large dataset in Julia

using DataFrames
using Arrow

pwd();

df = DataFrame(Arrow.Table("1.data_sources/twitter/data/binded_tweets.feather"));

df_migration = filter(
    x -> any(occursin.(r"(?i)(běženec\w*)|(běženk\w*)|(imigrant\w*)|(migra\w*)|(imigra\w*)|(přistěhoval\w*)|(uprchl\w*)|(utečen\w*)|(azylant\w*)", x.text)),
    df
);

Arrow.write("julia_migration_filtered.feather", df_migration)

# When using package RCall, we can enter R with $ and then refer to the variable using $variable_name.

