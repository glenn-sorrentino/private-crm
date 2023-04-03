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
mkdir templates

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
    <title>Accounts</title>
    <style>
        /* Add some basic CSS for the modal */
        .modal {
            display: none;
            position: fixed;
            z-index: 1;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            overflow: auto;
            background-color: rgba(0,0,0,0.4);
        }

        .modal-content {
            background-color: #fefefe;
            margin: 15% auto;
            padding: 20px;
            border: 1px solid #888;
            width: 80%;
        }
    </style>
</head>
<body>
    <h1>Accounts</h1>
    <button id="new-account-btn">New Account</button>
    <h2>All Accounts</h2>
    <ul>
        {% for account in accounts %}
        <li>{{ account.name }} - {{ account.industry }} - {{ account.location }}</li>
        {% endfor %}
    </ul>
    <nav>
        <a href="{{ url_for('dashboard') }}">Dashboard</a>
        <a href="{{ url_for('contacts') }}">Contacts</a>
    </nav>

    <!-- Add the modal -->
    <div id="new-account-modal" class="modal">
        <div class="modal-content">
            <h2>Create New Account</h2>
            <form id="new-account-form">
                <label for="name">Account Name:</label>
                <input type="text" id="name" name="name" required>
                <label for="industry">Industry:</label>
                <input type="text" id="industry" name="industry" required>
                <label for="location">Location:</label>
                <input type="text" id="location" name="location" required>
                <input type="submit" value="Save">
                <button type="button" id="cancel-btn">Cancel</button>
            </form>
        </div>
    </div>

    <script>
        // Get the modal, form, and buttons
        var modal = document.getElementById('new-account-modal');
        var btn = document.getElementById('new-account-btn');
        var cancelBtn = document.getElementById('cancel-btn');
        var form = document.getElementById('new-account-form');

        // Open the modal when the user clicks the "New Account" button
        btn.onclick = function() {
            modal.style.display = 'block';
        }

        // Close the modal when the user clicks the "Cancel" button
        cancelBtn.onclick = function() {
            modal.style.display = 'none';
        }

        // Send a POST request when the user submits the form
        form.onsubmit = function(e) {
            e.preventDefault();
            var xhr = new XMLHttpRequest();
            xhr.open('POST', '{{ url_for("accounts") }}', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.onreadystatechange = function() {
                if (xhr.readyState == 4 && xhr.status == 200) {
                    // Refresh the page to display the new account
                    location.reload();
                }
            };
            var formData = new FormData(form);
            var encodedData = new URLSearchParams(formData).toString();
            xhr.send(encodedData);
        }
    </script>
</body>
</html>

EOL

# Run the app
echo "Starting the CRM app..."
source venv/bin/activate
python app.py
