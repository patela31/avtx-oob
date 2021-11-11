# 1.  Note, the 'variables' in variable.tf removed as caused issues, the SP details added via T8 cloud 'env variables'
# 2.  T8 cloud variables equates to *tfvars

Warning: Value for undeclared variable
The root module does not declare a variable named "client_secret" but a value was found in file "/terraform/terraform.tfvars". If you meant to use this value, add a "variable" block to the configuration. To silence these warnings, use TF_VAR_... environment variables to provide certain "global" settings to all configurations in your organization. To reduce the verbosity of these warnings, use the -compact-warnings option.

# 3.  this deploys controller and copilot (though no initialization etc).



