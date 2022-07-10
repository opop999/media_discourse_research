"""Function to replace text in the column of Pandas dataframe using regex pattern"""

import pandas as pd


def pattern_preprocessing_cs(input_column: "pd.Series[str]", pattern: str) -> "pd.Series[str]":
    """

    Args:
        input_column (pd.DataFrame): Pandas series of strings to be preprocessed.
        pattern (str): Pattern to be used.

    Returns:
        pd.Series[str]: Processed Pandas series.
    """

    return input_column.str.replace(pattern, " ", regex=True) \
        .str.replace(r"\.{2,}", ".", regex=True) \
        .str.strip() \
        .str.replace(r"  +", " ", regex=True)
