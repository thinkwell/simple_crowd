Simple Crowd (SOAP Client for Atlassian Crowd)
=====

A basic Atlassian Crowd Client based on their SOAP API.
All the standard API calls have been implemented to my knowledge as of Crowd 2.0

#### Some disclaimers:


- This gem was created before Atlassian created a REST API for Crowd which is why we implemented it in SOAP.
- This gem was created for Atlassian Crowd 2.0, but it should work with 2.2.
- We renamed "principal" to "user" in all the API calls for our convenience as this gem was initially created for internal use only.
- This gem is in use in production and has been fully tested, but we provide no guarantee or support if it does not work for you.

#### Service URL Options:

- :service_url => "http://localhost:8095/crowd/",
- :app_name => "crowd",
- :app_password => ""

Ex. `SimpleCrowd::Client.new(:service_url...)`

#### Some example calls:

- `client.authenticate_user("test@test.com", "testpassword")`
  - returns token if authenticated or nil if not
- `client.find_user_with_attributes_by_name("test@test.com")`
  - returns user with all custom attributes
  - NOTE: find_user_by_name does not return custom attributes
- `client.is_valid_user_token?("SOMELARGECROWDTOKEN")`
  - returns true or false


TODO
--

- Add support for arrays in custom attribute values
- Add exception/error types instead of throwing Simple::CrowdError for all errors
- Add support for group custom attributes (as of Crowd 2.1 or 2.2)
- Add more automated tests for groups and validation factors

