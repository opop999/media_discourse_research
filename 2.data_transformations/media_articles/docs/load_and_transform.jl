using DataFrames, RData, CategoricalArrays, Tables;

newton_annotated_dataset = load("2.data_transformations/data/full_articles_subset.rds", convert = true)[1:10,:];

println("The type of the object is: ", typeof(newton_annotated_dataset));

first(newton_annotated_dataset, 5)

regex = r"\.\.\.|<(.|\n)*?>|[^ěščřžýáíéóúůďťňĎŇŤŠČŘŽÝÁÍÉÚŮĚÓa-zA-Z0-9\.\?\! ]"
newton_annotated_dataset[:, "Content"]

match(r"Do", newton_annotated_dataset[1, "Content"]).captures

for m in eachmatch(r"[ěščřžýáíéóúůďťňĎŇŤŠČŘŽÝÁÍÉÚŮĚÓa-zA-Z0-9\\.\\?\\! ]", "My cats and my ..dog?!")
    println("Matched $(m.match) at index $(m.offset)")
end


# Using CategoricalArrays

source_factor = categorical(newton_annotated_dataset[!, "sourceName"])

levels(source_factor)

# Using Tables.jl
rows = Tables.rows(newton_annotated_dataset);
# we can iterate through each row
for row in rows
    # example of getting all values in the row
    # don't worry, there are other ways to more efficiently process rows
    rowvalues = [Tables.getcolumn(row, col) for col in Tables.columnnames(row)]
end