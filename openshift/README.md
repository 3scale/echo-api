# Echo-API env.


You can use two different backend templates:

* I just need an echo-api deployed: echo-api-template.yml (uses prebuilt docker images)
* I want to modify/devel echo-api:
	1. Go to ../
	2. Make your changes on the aplication files (app.json, config.ru, echo_api.rb).
	3. make update

## Downloading the CLI

Get `openshift-cli`:

[Getting started with CLI](https://docs.openshift.org/latest/cli_reference/get_started_cli.html#installing-the-cli)

On OSX:

```shell
brew update && brew install openshift-cli
```

NOTE: After installing ensure that you can execute the "oc" command and that "oc version" returns at least version v.1.2.1:
```
oc v1.2.1
kubernetes v1.2.0-36-g4a3f9c5
```


# Project setup (once per environment)

- Login:

```shell
$ oc login https://openshift.server.com:8443 --insecure-skip-tls-verify
```

- Create or switch to your project:

```
oc new-project echo-api
```

- Create the template:

```
oc new-app -f echo-api-template.yml --param ECHOAPI_HOST=<a-hostname-for-echo-api-route>
```

- Check status:

```
oc status
```
