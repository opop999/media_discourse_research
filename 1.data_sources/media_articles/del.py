import pandas as pd
from newsplease import NewsPlease
from newspaper import ArticleException


def get_disinfo_article_texts(disinfo_urls: list) -> pd.DataFrame:
    """[Extract article texts from disinfo url links]
    Args:
        disinfo_urls ([list]): [description]
    Returns:
        [DataFrame]: [description]
    """
    list_of_dictionaries: list = []
    for i, url in enumerate(disinfo_urls):
        try:
            article = NewsPlease.from_url(url, timeout=15)
        except ArticleException:
            print(f"Error, article nr. {i} not downloaded")
        else:
            dict_temp = {"title": article.title, "annotation": article.description,
                         "full_text": article.maintext, "extra_text": article.text}
            list_of_dictionaries.append(dict_temp)
            print(
                f"Article {i + 1} out of {len(disinfo_urls)} finished scraping", flush=True)
    print("Extraction Finished", flush=True)
    return pd.DataFrame(list_of_dictionaries)
