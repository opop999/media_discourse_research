def get_journalists_on_twitter(source_page="https://www.nfnz.cz/novinari-na-twitteru/", ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36"):
    """[Scrape journalist twitter names using BeautifulSoup]

    Args:
        source_page (str, optional): [description]. Defaults to "https://www.nfnz.cz/novinari-na-twitteru/".
        ua (str, optional): [description]. Defaults to "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36".
    """
    from bs4 import BeautifulSoup
    import pandas as pd
    import requests

    full_page = requests.get(source_page, headers={'User-Agent': ua})
    soup = BeautifulSoup(full_page.content, 'lxml')

    list_of_dictionaries = []
    rows = len(soup.find_all('span', class_='AuthorSignature-note'))

    for i, (name, full_text) in enumerate(zip(soup.find_all('span', class_='AuthorSignature-note'), soup.find_all('td', class_='align-right view-smaller')[::2])):
        list_of_dictionaries.append({"name": name.get_text().strip(),
                                    "full_text": full_text.get_text().strip()})
        print(f"Item {i + 1} out of {rows} finished scraping", flush=True)
    print("Extraction Finished", flush=True)

    return pd.DataFrame(list_of_dictionaries)
