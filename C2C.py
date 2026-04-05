from flask import Flask, request, Response
from dotenv import load_dotenv, dotenv_values
import os

ROOT_DIR = f"./recon"
RECON_TARGETS_FILE_PATH = ROOT_DIR + "/" + "targets.txt"
DOMAINS_DIR_PATH = ROOT_DIR + "/" + "domains"

def init_structure():
    if not os.path.exists(ROOT_DIR):
        os.mkdir(ROOT_DIR)
        os.mkdir(DOMAINS_DIR_PATH)

init_structure()
load_dotenv()
app = Flask(__name__)

@app.route("/add_target/<target_domain>", methods=["POST"])
def add_target(target_domain):

    if request.form['secret'] != os.getenv('SECRET_KEY'):
        return "Authentication Error", 401

    with open(RECON_TARGETS_FILE_PATH, "a+") as f:
        for line in f.readlines():
            if target_domain in line:
                return "Domain already in targets", 200
        
        f.write(target_domain)
        os.mkdir(DOMAINS_DIR_PATH + "/" + target_domain)

        return "OK", 200
    
@app.route("/remove_target/<target_domain>", methods=["POST"])
def remove_target(target_domain):

    if request.form['secret'] != os.getenv('SECRET_KEY'):
        return "Authentication Error", 401

    with open(RECON_TARGETS_FILE_PATH, "r+") as f:
        lines = f.readlines()
        f.seek(0)
        for line in lines:
            if target_domain not in line:
                f.write(line)

        f.truncate()
        
    return "OK", 200




