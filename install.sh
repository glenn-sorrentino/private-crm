#!/bin/bash

# Update packages and install required software
sudo apt update
sudo apt install -y python3 python3-pip python3-venv sqlite3

# Create a project directory
mkdir crm_app
cd crm_app

# Set up a virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required Python packages
pip install Flask Flask-SQLAlchemy

# Create the main application file
cat > app.py <<EOL
from flask import Flask, render_template
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///crm.db'
db = SQLAlchemy(app)

class Customer(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(50), nullable=False)
    email = db.Column(db.String(100), nullable=False, unique=True)

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    db.create_all()
    app.run(debug=True)
EOL

# Create templates folder and a basic index.html file
mkdir templates
cat > templates/index.html <<EOL
<!DOCTYPE html>
<html>
<head>
    <title>CRM App</title>
</head>
<body>
    <h1>Welcome to the CRM App!</h1>
    <p>Under construction...</p>
</body>
</html>
EOL

# Run the app
echo "To run the app, execute the following commands:"
echo "cd crm_app"
echo "source venv/bin/activate"
echo "python app.py"
