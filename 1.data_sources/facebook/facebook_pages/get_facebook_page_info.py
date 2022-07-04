def get_fb_pages_info(fb_pages, fb_cookies, dir_name, dir_name_long):
    """[Extract information about Facebook pages]

    Args:
        fb_pages ([list]): [description]
        fb_cookies ([json]): [description]
        dir_name ([string]): [description]
        dir_name_long ([string]): [description]
    """
    # Import dependencies
    import pandas as pd
    import os
    from facebook_scraper import get_page_info
    from time import sleep
    from random import uniform

    # Create empty list to which append dictionaries
    list_dict = []
    # Check if file already exist and which account are already in it (both absolute or relative directory to be sure)
    if (os.path.exists(dir_name + "/facebook_pages_info.feather") or os.path.exists(dir_name_long + "/facebook_pages_info.feather")):
        print(
            "Dataset already exists, will load it and check what accounts are already in it")
        old_df = pd.read_feather(dir_name + "/facebook_pages_info.feather")
        fb_pages_old = old_df["name"].tolist()
        # We need to convert both lists to sets before doing set diff
        fb_pages = set(fb_pages) - set(fb_pages_old)
        # Remove empty values if input object list or set (default)
        fb_pages = [i for i in fb_pages if i != "NA"]
        for i, fb_account in enumerate(fb_pages):
            print(
                f"Medium nr. {i + 1} of {(len(fb_pages))}: {fb_account}", flush=True)
            # Store the result in a temporary dictionary
            dict_temp = get_page_info(account=fb_account,
                                      cookies=fb_cookies)
            # Since the page name is sometimes not scraped, we specify it manually
            dict_temp.update({"name": fb_account})
            # Append the temporary dictionary to the list
            list_dict.append(dict_temp)
            # Wait between loops
            sleep(uniform(2, 4))
        # List of Dictionaries to dataframe
        df = pd.DataFrame(list_dict)
        # Appending old dataset rows to the new one
        df = df.append(old_df, ignore_index=True)
    else:
        print("Dataset does not yet exist in the specified location")
    # Remove empty values if input object panda series
    # fb_pages = fb_pages[~fb_pages.isin(["NA", "NaN"])]
    # Remove empty values if input object list (default)
        fb_pages = [i for i in fb_pages if i != "NA"]
        for i, fb_account in enumerate(fb_pages):
            print(
                f"Medium nr. {i + 1} of {(len(fb_pages))}: {fb_account}", flush=True)
            # With each loop, append the dataframe with results from scraper call
            # df = df.append(get_page_info(account = fb_pages[i],
            #                          cookies = fb_cookies),
            #                          ignore_index = True)
            dict_temp = get_page_info(account=fb_account,
                                      cookies=fb_cookies)
            # Since the page name is sometimes not scraped, we specify it manually
            dict_temp.update({"name": fb_account})
            # Append the temporary dictionary to the list
            list_dict.append(dict_temp)
            # Wait between loops
            sleep(uniform(2, 4))
        # List of Dictionaries to dataframe
        df = pd.DataFrame(list_dict)

    # Save resulting dataframe into a feather format
    df.to_feather(dir_name + "/facebook_pages_info.feather")
