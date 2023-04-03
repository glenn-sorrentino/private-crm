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
from flask import Flask, render_template, request, redirect, url_for
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///crm.db'
db = SQLAlchemy(app)

class Account(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    contacts = db.relationship('Contact', backref='account', lazy=True)

class Contact(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), nullable=False, unique=True)
    phone = db.Column(db.String(15), nullable=True)
    account_id = db.Column(db.Integer, db.ForeignKey('account.id'), nullable=False)

@app.route('/')
def dashboard():
    total_accounts = Account.query.count()
    total_contacts = Contact.query.count()
    return render_template('dashboard.html', total_accounts=total_accounts, total_contacts=total_contacts)

@app.route('/accounts', methods=['GET', 'POST'])
def accounts():
    if request.method == 'POST':
        account_name = request.form['name']
        new_account = Account(name=account_name)
        db.session.add(new_account)
        db.session.commit()
        return redirect(url_for('accounts'))
    accounts = Account.query.all()
    return render_template('accounts.html', accounts=accounts)

@app.route('/contacts', methods=['GET', 'POST'])
def contacts():
    if request.method == 'POST':
        contact_name = request.form['name']
        contact_email = request.form['email']
        contact_phone = request.form['phone']
        account_id = request.form['account']
        new_contact = Contact(name=contact_name, email=contact_email, phone=contact_phone, account_id=account_id)
        db.session.add(new_contact)
        db.session.commit()
        return redirect(url_for('contacts'))
    contacts = Contact.query.all()
    accounts = Account.query.all()
    return render_template('contacts.html', contacts=contacts, accounts=accounts)

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', debug=True)
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
echo "Starting the CRM app..."
source venv/bin/activate
python app.py
