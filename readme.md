
Deployed on Heroku
===
You can find this app deployed on Heroku at http://echo-api.herokuapp.com/ 

Running Natively (Locally)
===
Start locally using rackup:
``` bash
rackup config.ru --host 0.0.0.0
````

You should see output similar to this:
``` bash
Puma starting in single mode...
Version 3.6.0 (ruby 2.3.1-p112), codename: Sleepy Sunday Serenity
* Min threads: 0, max threads: 16
* Environment: development
* Listening on tcp://0.0.0.0:9292
Use Ctrl-C to stop
```

Running in Docker
===
Build the docker image
> docker build .

Run the image to get a running instance:
> docker run -P <image id returned in build above>

-P publishes all ports exposed by the Dockerfile (which exposes 9292)

You should see output from the app, describing where it is listening for requests:
``` bash
/opt/echo-api/echo_api.rb:11: warning: class variable access from toplevel
Puma starting in single mode...
* Version 3.6.0 (ruby 2.1.3-p242), codename: Sleepy Sunday Serenity
* Min threads: 0, max threads: 16
* Environment: development
* Listening on tcp://0.0.0.0:9292
Use Ctrl-C to stop
```

You can see the running instance and the ports exposed using:
> docker ps
``` bash
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                     NAMES
26e740038940        1cf0e6830b96        "bundle exec rackup c"   5 minutes ago       Up 5 minutes        0.0.0.0:32768->9292/tcp   nostalgic_jennings
```

So the echo-api is exposed on 0.0.0.0:32768 and can be tested there:

``` bash
> curl http://0.0.0.0:32768/test?name=me
```


