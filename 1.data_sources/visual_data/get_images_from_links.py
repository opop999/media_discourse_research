# Download the images to a folder from a list of links using single thread
import concurrent.futures
import requests
import os


def get_images_from_links(platform, account, links, folder):
    """[This function downloads the images from a list of links and saves them to a folder]

    Args:
        platform ([string]): [The platform name]
        account ([string]): [The account name]
        links ([list]): [The list of links to the images]
        folder ([string]): [The folder to save the images]
    """
    for i, link in enumerate(links):
        try:
            res = requests.get(link)
            with open(folder + '/' + platform + "_" + account + "_" + str(i), 'wb') as img_file:
                img_file.write(res.content)
                print(f'Downloaded {i}', flush=True)
        except Exception as e:
            print(e)


# Test links
links = ['https://scontent-vie1-1.xx.fbcdn.net/v/t39.30808-6/263656515_4838122739560745_1579525288430356637_n.jpg?_nc_cat=101&_nc_rgb565=1&ccb=1-5&_nc_sid=730e14&_nc_ohc=4f6rJAY77qgAX_56Sj-&_nc_ht=scontent-vie1-1.xx&oh=0f9253f441744d312bf3d430c13f778d&oe=61B38E72',
         'https://external-vie1-1.xx.fbcdn.net/safe_image.php?d=AQE-euuSg5B8FjUE&w=1192&h=622&url=https%3A%2F%2Fa2larm.cz%2Fwp-content%2Fuploads%2F2021%2F12%2F8WGi04CW.jpg&cfs=1&ext=jpg&_nc_oe=6f2a5&_nc_sid=06c271&ccb=3-5&_nc_hash=AQHoEIXN9AV4qibO']

# Test setup
get_images_from_links(account="a2larm",
                      platform="fb",
                      links=links,
                      folder='1.data_sources/visual_data/facebook_images')

# Download the images to a folder from a list of links using multiple threads


def download_image(img_url):
    """[This function downloads the images from a list of links and saves them to a folder]

    Args:
        img_url ([list]): [The list of links to the images]
    """
    img_urls = links
    data_folder = '1.data_sources/visual_data/facebook_images'
    headers = {
        "Connection": "keep-alive",
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36"
    }
    try:
        img_bytes = requests.get(
            img_url, allow_redirects=True, headers=headers).content
        image_name = img_url.split('/')[-1][:52]
        with open(os.path.join(data_folder, image_name), "wb") as img_file:
            img_file.write(img_bytes)
    except Exception as e:
        print(e)


with concurrent.futures.ThreadPoolExecutor() as executor:
    executor.map(download_image, links)
