import os
import requests

from flask import Flask
from flask import render_template
from flask import request

from flask import Flask, redirect, url_for, request
app = Flask(__name__)

@app.route('/status')
def status():
  return os.environ['APP_NAME']

@app.route('/mesh/<name>')
def get_remote(name):
  return requests.get('http://' + str(name) + '/status',timeout=3).content

if __name__ == '__main__':
   app.run(debug = True)