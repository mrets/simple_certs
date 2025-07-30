# README

This application is a very simple app that implements a renewable energy certificate registry API.

## App overview

There are 7 models in this app:

* Organization - every user is a member of one organization
* User - the user object holds the api_key used to access the API
* Generator - an organization can have zero or more renewable energy generators associated with it
* Generation - a generation is a record of generated energy from a generator over a period of time
* Certificate - when a valid generation is created, it creates an immutable certificate that has 
  details of a quantity of renewable energy. It is like a currency where a quantity of 1 stands for
  for 1 MWh or renewable energy, or 1 REC in industry speak.
* CertficateQuantity - a certificate quantity is a portion of a certificate that can be transferred to other
  users or stored in different accounts.
* Account - an account stores certificate quantities and has a balance of n RECs based on the total of 
  all certificate quantities that it holds.

When a user posts generation that is valid, it creates a certificate of the same quantity and a certificate
quantity of the same quantity as well into the organizations default account.

## Component versions

This uses ruby 3.3.9 and rails 8.0.2. 

### Installation

Depending on your OS, you instructions will be different. Here is how to get it installed on MacOS
using RVM.

```
rvm install "ruby-3.3.9"  --with-openssl-dir=$(brew --prefix openssl@1.1)
gem update --system 
bundle install
```

### Getting started

Once ruby and the application is installed, run:

```
rails db:setup
```

This sets up two organizations each with one generation / certificate / certificate quantity. The first organization's
user has an api key of 'abcd', and the second of 'xyz'. The HTTP header of X-Api-Key's value selects
which user you are operating as.

Next import the postman collection into postman, and start poking around.