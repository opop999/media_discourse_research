################################################################################
#                                   Packages                                   #
################################################################################
from webdriver_manager.chrome import ChromeDriverManager
from selenium.common.exceptions import NoSuchElementException
from selenium import webdriver
import pandas as pd
import os
import time
from dotenv import load_dotenv
load_dotenv()

# Set up docker container with Selenium
address = "localhost"
host_port = 4445
container_port = 4444

os.system("docker run --rm -d --name selenium_headless --shm-size=2g -p " + str(host_port)
          + ":" + str(container_port) + " selenium/standalone-chrome")


################################################################################
#                                  Main Code                                   #
################################################################################

# Asking the client for the username or hashtag he wants to scrap
account = input(
    "[INFO]: Please type the username you want to scrap stories from:")
story_link = "https://www.instagram.com/stories/{}/".format(account)
login_page = "https://www.instagram.com/accounts/login/"
project_direc = "1.data_sources/visual_data/instagram_images_videos/"

# Specify Chrome driver options
options = webdriver.ChromeOptions()
options.add_argument("--window-size=1920,1080")
options.add_argument("--ignore-certificate-errors")
options.add_argument("--allow-running-insecure-content")
options.add_argument(
    "user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36")
options.add_argument("--headless")

# Or webdriver.Chrome for local execution
driver = webdriver.Remote(
    command_executor="http://localhost:4445/wd/hub", options=options)
driver.get(login_page)
time.sleep(4)

# What is our user agent? Execute the JavaScript to get it.
driver.execute_script("return navigator.userAgent;")

# Accept the website cookies
driver.find_element_by_xpath("/html/body/div[4]/div/div/button[1]").click()

# Login with a random account since we can't scrap stories without being logged
driver.find_element_by_name("username").send_keys(os.environ.get("INSTA_USER"))
driver.find_element_by_name("password").send_keys(os.environ.get("INSTA_PASS"))
driver.find_element_by_xpath(
    "//*[@id='loginForm']/div/div[3]/button/div").click()
time.sleep(6)
print("\n[SUCCESS]: Logged into the website. \n")

# Have access to the story link
driver.get(story_link)
time.sleep(2)

# Check if there are any stories for the last 24h, if so start scraping all stories
if driver.current_url != story_link:
    print("\n[ERROR]: No stories are available for the last 24h.\n")
else:
    rows = []
    print("\n[SUCCESS]: Got into the story link. \n")
    driver.find_element_by_xpath(
        "/html/body/div[1]/section/div[1]/div/section/div/div[1]/div/div/div/div[3]/button").click()
    time.sleep(3)
    while driver.current_url != "https://www.instagram.com/":
        # Collect the link to the video content of the story if it exists, otherwise take the image link
        is_video = True
        try:
            content_link = driver.find_element_by_xpath("//*[@id='react-root']/section/div[1]/div/section"
                                                        "/div/div[1]/div/div/video/source").get_attribute("src")
        except NoSuchElementException:
            content_link = driver.find_element_by_xpath("//*[@id='react-root']/section/div[1]/div/"
                                                        "section/div/div[1]/div/div/img").get_attribute("src")
            is_video = False

        # Get the link of the story
        insta_link = driver.current_url
        # Get the date of the story
        date = driver.find_element_by_xpath("//*[@id='react-root']/section/div[1]/div/"
                                            "section/div/header/div[2]/div[1]/div/div/"
                                            "div/time").get_attribute("datetime")
        # Append all collected information into a row
        rows.append(
            {
                'Instagram URL': insta_link,
                'Content URL': content_link,
                'Date': date,
                'is_video': is_video
            }
        )
        # Click on the next button
        driver.find_element_by_xpath(
            "//*[@id='react-root']/section/div[1]/div/section/div/button[2]").click()
        time.sleep(3)

    # Save scrapped data into a dataframe
    df = pd.DataFrame(rows)
    df.to_csv(os.path.join(project_direc, "data/stories_{}.csv".format(account)))
    print("\n[SUCCESS]: Scrapped all stories for the last 24h.\n")
