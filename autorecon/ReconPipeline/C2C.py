from flask import Flask, request, Response
from dotenv import load_dotenv, dotenv_values
import os
import subprocess

ROOT_DIR = f"./recon"
RECON_TARGETS_FILE_PATH = ROOT_DIR + "/" + "targets.txt"
DOMAINS_DIR_PATH = ROOT_DIR + "/" + "domains"

def check_token(request):
    return request.form['secret'] == os.getenv('SECRET_KEY')

def init_structure():
    if not os.path.exists(ROOT_DIR):
        os.mkdir(ROOT_DIR)
        os.mkdir(DOMAINS_DIR_PATH)

init_structure()
load_dotenv()
app = Flask(__name__)

@app.route("/add_target/<target_domain>", methods=["POST"])
def add_target(target_domain):

    if not check_token(request):
        return "Authentication Error", 401

    with open(RECON_TARGETS_FILE_PATH, "a+") as f:
        for line in f.readlines():
            if target_domain in line:
                return "Domain already in targets", 200
        
        f.write(target_domain + '\n')

    domain_dir = DOMAINS_DIR_PATH + "/" + target_domain 
    if not os.path.exists(domain_dir):
        os.mkdir(domain_dir)

    return "OK", 200
    
@app.route("/remove_target/<target_domain>", methods=["POST"])
def remove_target(target_domain):
    if not check_token(request):
        return "Authentication Error", 401

    with open(RECON_TARGETS_FILE_PATH, "r+") as f:
        lines = f.readlines()
        f.seek(0)
        for line in lines:
            if target_domain not in line:
                f.write(line)

        f.truncate()
        
    return "OK", 200


@app.route("/run_full_recon", methods=["POST"])
def run_full_recon():
    if not check_token(request):
        return "Authentication Error", 401
    
    if os.path.exists("./recon_lock"):
        return "Analysis already running", 200
    
    subprocess.Popen(["./recon_scripts/run_on_all.sh", "full", os.path.abspath(RECON_TARGETS_FILE_PATH)])
    
    return "Initiated full chain analysis on all targets!", 200

@app.route("/run_quick_recon", methods=["POST"])
def run_quick_recon():
    if not check_token(request):
        return "Authentication Error", 401
    
    if os.path.exists("./recon_lock"):
        return "Analysis already running", 200

    subprocess.Popen(["./recon_scripts/run_on_all.sh", "basic", os.path.abspath(RECON_TARGETS_FILE_PATH)])
    
    return "Initiated quick analysis on all targets!", 200
    
    

