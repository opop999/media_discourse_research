"""Function to replace text in the column of Pandas dataframe using regex pattern"""
import pandas as pd


def pattern_preprocessing_cs(input_df: pd.DataFrame, column: str, pattern: str) -> pd.DataFrame:
    """

    Args:
        input_df (pd.DataFrame): Pandas dataframe to be processed.
        column (str): Column to be processed.
        pattern (str): Pattern to be used.

    Returns:
        pd.DataFrame: Processed dataframe.
    """

    input_df[column] = input_df[column].str.replace(pattern, " ", regex=True) \
        .str.replace(r"\.{2,}", ".", regex=True) \
        .str.strip() \
        .str.replace(r"  +", " ", regex=True)
    return input_df
