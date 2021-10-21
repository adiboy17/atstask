from flask import Flask
import subprocess as sp
app = Flask(__name__)

@app.route("/")
def hello():
    output = sp.getoutput("echo $ATC_USERNAME" + "echo $ATC_PASSWORD")
    print(output)

if __name__ == "__main__":
    app.run(host='0.0.0.0')
