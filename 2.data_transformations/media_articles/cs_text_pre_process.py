# Function to replace text in the column of Pandas dataframe using regex
def pattern_preprocessing_cs(df, column, pattern):
    """_summary_

    Args:
        df (_type_): _description_
        column (_type_): _description_
        pattern (_type_): _description_

    Returns:
        _type_: _description_
    """
    import pandas as pd
    
    df[column] = df[column].str.replace(pattern, " ", regex=True) \
                .str.replace(r"\.{2,}", ".", regex=True) \
                .str.strip() \
                .str.replace(r"  +", " ", regex=True)
    return df


