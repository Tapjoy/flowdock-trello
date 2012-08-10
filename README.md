flowdock-trello
===============

Add .env:

```
TRELLO_ORGANIZATION=(org id or name here),(board id here)
TRELLO_KEY=(trello key here)
TRELLO_TOKEN=(trello token here)
FLOWDOCK_TOKEN=(flowdock token here)
FLOWDOCK_EMAIL=(email here)
```

`foreman start`

heroku
------

```
heroku git:remote -a server-name-here
heroku config:set TRELLO_ORGANIZATION=(org id or name here),(board id here) TRELLO_KEY=(trello key here) TRELLO_TOKEN=(trello token here) FLOWDOCK_TOKEN=(flowdock token here) FLOWDOCK_EMAIL=(email here)
git push heroku master
heroku ps:scale worker=1
heroku restart
```