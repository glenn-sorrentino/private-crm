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

# Create the necessary directories and files
mkdir -p templates
touch app.py
touch templates/base.html
touch templates/accounts.html

# Create the main application file
# Create the main application file
cat > app.py <<EOL
from flask import Flask, render_template, request, redirect, url_for
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///crm.db'
db = SQLAlchemy(app)

class Contact(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), nullable=False, unique=True)
    phone = db.Column(db.String(15), nullable=True)
    account_id = db.Column(db.Integer, db.ForeignKey('account.id'), nullable=False)

@app.route('/')
def index():
    return redirect(url_for('dashboard'))

@app.route('/dashboard')
def dashboard():
    total_accounts = Account.query.count()
    total_contacts = Contact.query.count()
    return render_template('dashboard.html', total_accounts=total_accounts, total_contacts=total_contacts)

# ...
@app.route('/accounts', methods=['GET', 'POST'])
def accounts():
    if request.method == 'POST':
        account_name = request.form['name']
        account_industry = request.form['industry']
        account_location = request.form['location']
        new_account = Account(name=account_name, industry=account_industry, location=account_location)
        db.session.add(new_account)
        db.session.commit()
        return redirect(url_for('accounts'))
    accounts = Account.query.all()
    return render_template('accounts.html', accounts=accounts)

# ...
class Account(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    industry = db.Column(db.String(100), nullable=False)  # Add the industry field
    location = db.Column(db.String(100), nullable=False)  # Add the location field
    contacts = db.relationship('Contact', backref='account', lazy=True)

# ...

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
cat > templates/dashboard.html <<EOL
<!DOCTYPE html>
<html>
<head>
    <title>CRM Dashboard</title>
</head>
<body>
    <h1>CRM Dashboard</h1>
    <p>Total Accounts: {{ total_accounts }}</p>
    <p>Total Contacts: {{ total_contacts }}</p>
    <nav>
        <a href="{{ url_for('dashboard') }}">Dashboard</a>
        <a href="{{ url_for('accounts') }}">Accounts</a>
        <a href="{{ url_for('contacts') }}">Contacts</a>
    </nav>
</body>
</html>
EOL

cat > crm_app/templates/base.html << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CRM App</title>
</head>
<body>
    {% block content %}{% endblock %}
</body>
</html>
EOL

cat > templates/accounts.html <<EOL
{% extends 'base.html' %}

{% block content %}
<head>
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.16.0/umd/popper.min.js"></script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
</head>
<body>
  <div class="container">
    <h2>Accounts</h2>
    <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#myModal">Create New Account</button>
    <table class="table">
      <thead>
        <tr>
          <th>Name</th>
          <th>Industry</th>
          <th>Location</th>
        </tr>
      </thead>
      <tbody>
        {% for account in accounts %}
          <tr>
            <td>{{ account.name }}</td>
            <td>{{ account.industry }}</td>
            <td>{{ account.location }}</td>
          </tr>
        {% endfor %}
      </tbody>
    </table>
  </div>
  
  <div class="modal" tabindex="-1" role="dialog" id="myModal">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">Create New Account</h5>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <form action="/accounts" method="POST">
          <div class="modal-body">
            <div class="form-group">
              <label for="name">Name:</label>
              <input type="text" class="form-control" id="name" name="name" required>
            </div>
            <div class="form-group">
              <label for="industry">Industry:</label>
              <input type="text" class="form-control" id="industry" name="industry" required>
            </div>
            <div class="form-group">
              <label for="location">Location:</label>
              <input type="text" class="form-control" id="location" name="location" required>
            </div>
          </div>
          <div class="modal-footer">
            <button type="submit" class="btn btn-primary">Save</button>
            <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</body>
{% endblock %}

EOL

cat > templates/contacts.html <<EOL
<!DOCTYPE html>
<html>
<head>
    <title>Contacts</title>
</head>
<body>
    <h1>Contacts</h1>
    <form method="post" action="{{ url_for('contacts') }}">
        <label for="name">Contact Name:</label>
        <input type="text" id="name" name="name" required>
        <label for="email">Email:</label>
        <input type="email" id="email" name="email" required>
        <label for="phone">Phone:</label>
        <input type="text" id="phone" name="phone">
        <label for="account">Account:</label>
        <select id="account" name="account" required>
            {% for account in accounts %}
            <option value="{{ account.id }}">{{ account.name }}</option>
            {% endfor %}
        </select>
        <input type="submit" value="Add Contact">
    </form>

    <h2>All Contacts</h2>
    <ul>
        {% for contact in contacts %}
        <li>{{ contact.name }} - {{ contact.email }} - {{ contact.phone }} - {{ contact.account.name }}</li>
        {% endfor %}
    </ul>
    <nav>
        <a href="{{ url_for('dashboard') }}">Dashboard</a>
        <a href="{{ url_for('accounts') }}">Accounts</a>
        <a href="{{ url_for('contacts') }}">Contacts</a>
    </nav>
</body>
</html>
EOL

# Run the app
echo "Starting the CRM app..."
source venv/bin/activate
python app.py
