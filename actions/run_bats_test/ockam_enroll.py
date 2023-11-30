from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait

import os

# Login credentials
username = os.environ['EMAIL_ADDRESS']
password = os.environ['PASSWORD']
activation_code = os.environ['ACTIVATION_CODE']
# home = os.environ['HOME']

if len(activation_code) == 0:
    exit(1)

options = Options()
options.add_argument("--headless")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")

driver = webdriver.Chrome(options=options)

# Head to activation page
driver.get("https://account.ockam.io/activate")

driver.find_element(By.NAME, "code").send_keys(activation_code)
driver.find_element(By.NAME, "action").click()

code = driver.find_element(
    By.CSS_SELECTOR, '[aria-label="Secure code"]').get_attribute("value")

if code != activation_code:
    print("Activation code", activation_code,
          "is not same as code on browser", code)
    exit(1)

driver.find_element(
    By.XPATH, "//*[@value='confirm']").click()

driver.find_element(By.ID, "username").send_keys(username)
driver.find_element(By.ID, "password").send_keys(password)
driver.find_element(
    By.CSS_SELECTOR, "button[data-action-button-primary='true']").click()

# Find the success login page

# Close window
driver.close()