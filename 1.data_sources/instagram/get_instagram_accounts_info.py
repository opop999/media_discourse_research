def instagram_accounts_info(instagram_pages, dir_name, dir_name_full):
    """[Function that extracts instagram accounts info.]
    Args:
        instagram_pages ([list]): [description]
        dir_name ([string]): [description]
        dir_name_full ([string]): [description]
    """
    # Import dependencies
    from igramscraper.instagram import Instagram
    import pandas as pd
    from time import sleep
    from random import uniform
    import os

    instagram = Instagram()

    # Create empty list, to which we will append dictionaries with every loop
    rows_list = []
    # Check if file already exist and which account are already in it (both absolute or relative directory to be sure)
    if os.path.exists(f"{dir_name_full}/instagram_accounts_info.feather") or os.path.exists(f"{dir_name}/instagram_accounts_info.feather"):
        # Load existing dataset
        print("Dataset already exists, will load it and check what accounts are already in it", flush=True)

        old_df = pd.read_feather(f"{dir_name}/instagram_accounts_info.feather")

        # Remove empty values
        instagram_pages = [i for i in instagram_pages if i != "NA"]
        print(
            f"The total of {len(instagram_pages)} valid Instagram accounts were provided", flush=True)

        inst_pages_old = old_df["chr_id"].tolist()
        # We need to convert both lists to sets before doing set diff
        instagram_pages = list(set(instagram_pages) - set(inst_pages_old))

        # Filter for values existing in the dataset
        print(
            f"A total of {len(instagram_pages)} valid Instagram accounts do not yet exist in the dataset", flush=True)

        # Loop over every item of the instagram accounts list
        for i, account in enumerate(instagram_pages):
            print(
                f"Medium nr. {i+1} of {len(instagram_pages)}: {account}", flush=True)
            acc = instagram.get_account(username=account)
            dict1 = dict({"num_id": acc.identifier, "chr_id": acc.username, "full_name": acc.full_name, "bio": acc.biography, "profile_pic_url": acc.profile_pic_url,
                         "external_url": acc.external_url, "posts": acc.media_count, "followers": acc.followed_by_count, "follows": acc.follows_count, "private": acc.is_private, "verified": acc.is_verified})

            # Append dictionary to the list of dictionaries
            rows_list.append(dict1)
            # Wait between loops
            if ((i != 0) and (i % 10 == 0)):
                print("Long 5-10 min pause between each 10 requests", flush=True)
                sleep(uniform(300, 600))
            elif ((i % 10) != 0):
                print("Short 30s pause between each account", flush=True)
                sleep(uniform(30, 35))
        # Construct dataframe from the list of dictionaries
        new_df = pd.DataFrame(rows_list)

        # Append new rows to the old dataset while ignoring possible duplicates
        merged_df = old_df.append(new_df, ignore_index=True)
        merged_df = merged_df.drop_duplicates()

        # Save resulting dataframe into a feather format
        merged_df.to_feather(f"{dir_name}/instagram_accounts_info.feather")

    else:
        print("Dataset does not yet exist in the specified location")
        # Remove empty values
        instagram_pages = [i for i in instagram_pages if i != "NA"]
        print(
            f"The total of {len(instagram_pages)} valid Instagram accounts were provided", flush=True)

        # Loop over every item of the instagram accounts list
        for i, account in enumerate(instagram_pages):
            print(
                f"Medium nr. {i+1} of {len(instagram_pages)}: {account}", flush=True)
            acc = instagram.get_account(username=account)
            dict1 = dict({"num_id": acc.identifier, "chr_id": acc.username, "full_name": acc.full_name, "bio": acc.biography, "profile_pic_url": acc.profile_pic_url,
                         "external_url": acc.external_url, "posts": acc.media_count, "followers": acc.followed_by_count, "follows": acc.follows_count, "private": acc.is_private, "verified": acc.is_verified})

            # Append dictionary to the list of dictionaries
            rows_list.append(dict1)
            # Wait between loops
            if ((i != 0) and (i % 10 == 0)):
                print("Long 5-10 min pause between each 10 requests", flush=True)
                sleep(uniform(300, 600))
            elif ((i % 10) != 0):
                print("Short 30s pause between each account", flush=True)
                sleep(uniform(30, 35))
        # Construct dataframe from the list of dictionaries
        new_df = pd.DataFrame(rows_list)

        # Save resulting dataframe into a feather format
        new_df.to_feather(f"{dir_name}/instagram_accounts_info.feather")
