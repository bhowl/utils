# utils #
A collection of utility functions and scripts.

## Shell Scripts ##
* `func.sh`: shell utility functions
* `snake_case.sh`: convert filenames and dirnames to snake_case convention

## Python Scripts ##
* `emailer.py`: A wrapper script to send emails from the CLI or another script. 
To configure this for gmail, create an [apps password](https://myaccount.google.com/apppasswords?rapt=AEjHL4M3v2qJNnq0zWR0-BacIwoubZU4IbevmStyj4zayhY0orEQ4mu0Vy80QSkZL9_UocrMvnSsdX8BM7jDQeYzMoejhXONYMqzSG2JL1TThZNyOfvHmXc).
Then, set the following enviroment variables (optionally add to your startup-environment)...
```
export SENDER_EMAIL="<your_email>"
export APPS_PASSWORD="<the generated password (16 char)"
```
