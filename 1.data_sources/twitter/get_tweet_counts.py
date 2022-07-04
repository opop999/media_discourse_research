def get_tweet_counts_and_save(token, search_query, min_date, granularity, save_path):
    """[function to get the number of tweets given query and save to feather format]

    Args:
        token ([string]): [twitter token]
        search_query ([string]): [query to search]
        min_date ([string]): [min date to search]
        granularity ([string]): [granularity of search]
        save_path ([string]): [path to save]
    """
    import tweepy
    import pandas as pd
    from tweepy import pagination
    from tweepy.client import Response
    from dotenv import load_dotenv

    load_dotenv()
    print("Authenticating...", flush=True)
    client = tweepy.Client(token)

    list_of_pages = []
    print("Getting paginated response", flush=True)
    res = tweepy.Paginator(client.get_all_tweets_count,
                           query=search_query,
                           start_time=min_date,
                           granularity=granularity)

    print("Extracting data from the response to the list", flush=True)
    for i, page in enumerate(res):
        list_of_pages.append(page[0])
        print(f"Page {i} added to the list", flush=True)

    print("Flatten the list of lists", flush=True)
    flat_list = [item for sublist in list_of_pages for item in sublist]

    print("Convert list of dictionaries to a DataFrame", flush=True)
    df = pd.DataFrame(flat_list)

    df.to_feather(path=save_path)
    print("Dataset successfully saved", flush=True)
    