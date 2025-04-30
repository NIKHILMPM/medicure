from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import time
import tempfile
import os

# Create a temporary directory for Chrome user data
user_data_dir = tempfile.mkdtemp()

# Set Chrome options for headless mode
chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")
chrome_options.add_argument(f"--user-data-dir={user_data_dir}")

# Launch the browser
driver = webdriver.Chrome(options=chrome_options)

# Get the URL from environment variable (or use default fallback)
url = os.getenv("APP_URL", "http://localhost:30081")  # 30081 matches NodePort

print(f"Testing URL: {url}")
driver.get(url)

# Wait for the page to load
time.sleep(5)

# Take a screenshot
driver.save_screenshot("homepage.png")

# Quit the browser
driver.quit()
