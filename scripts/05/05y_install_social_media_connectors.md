# install social media connectors for Flume/Kafka streaming

## install python virtual environment
```bash
su - root
apt install -y python3-virtualenv
apt install -y instaloader
```

execute as `hduser` in separate python-VM
```bash
su - hduser
pipx install facebook-scraper
pipx install instaloader
git clone https://github.com/abhirajranjan/Instagram-cli.git
git clone https://github.com/orakaro/rainbowstream.git
```

## Instagram CLI
prepare python script for Instagram-cli
```bash
UserName=<username>
PassWord=<passwd>
cat >~/Instagram-cli/insta_access.py <<!
#!/usr/bin/python3
import instagram  # importing file

insta = instagram.Instagram() # create an instance
res = insta.login(username='${UserName}', password='${PassWord}') #perform login. it will give out login info of user logged in like userID and auth.

## if above operation yields auth != True then you can read res in order to understand errors

if not insta.isAuth: ## checks if above login was successful or not same as res.text['Authentication']
	print('Failed to login in')
else:
	print('login successful')
!
```

## X/Twitter with rainbowstream
For accessing X with rainbowstream, it is necessary to first activate the API to get keys
```bash
cd ~/rainbowstream
cat >~/rainbowstream/rainbowstream/consumer.py <<!
# Consumer information
CONSUMER_KEY = 'Ho0rlPMpJKoKGzpZkU8I5qKqD' # Your Twitter application's API key
CONSUMER_SECRET = 'G36p1Z9PI5COLlQr4hcmPjSalYEqXtq46CpB6iTiW3YWHCVmP8' # Your Twitter application's API secret
#PCKT_CONSUMER_KEY = 'PocketAPIKey' # Your Pocket application's API key
!
```

```bash
virtualenv venv # Python3 users: use -p to specify python3
source venv/bin/activate
pip install -e .
which rainbowstream # /this-directory/venv/bin/rainbowstream
# Remove ~/.rainbow_oauth if exists
# you will get asked for a pin, where you open in browser https://api.twitter.com/oauth/authorize?oauth_token=...
# and insert the pin, so that login works
rainbowstream
```

### occuring errors
unfortunately following errors occur:

> We have connection problem with twitter REST API right now :(<br>
> You currently have access to a subset of Twitter API v2 endpoints and limited v1.1 endpoints<br>
> (e.g. media post, oauth) only. If you need access to this endpoint, you may need a different access level.<br>
> You can learn more here: [https://developer.twitter.com/en/portal/product](https://developer.twitter.com/en/portal/product)