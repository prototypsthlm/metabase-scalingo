![Metabase](metabase.png)

# Deploying Metabase to Scalingo

## Deploying Using Scalingo's One-click Button

Click on the button below to deploy Metabase to Scalingo within minutes.

[![Deploy](https://cdn.scalingo.com/deploy/button.svg)](https://my.scalingo.com/deploy?source=https://github.com/Scalingo/metabase-scalingo#master)

## Deploying Using Scalingo's Command Line Tool

1. Create an application on Scalingo:

```bash
$ scalingo create my-metabase
```

2. Add a PostgreSQL for the internal usage of Metabase:

```bash
$ scalingo --app my-metabase addons-add postgresql postgresql-starter-512
```

3. Configure your application to use the appropriate buildpack for deployments:

```bash
$ scalingo --app my-metabase env-set 'BUILDPACK_URL=https://github.com/Scalingo/multi-buildpack'
```

4. Clone this repository:

```bash
$ git clone https://github.com/Scalingo/metabase-scalingo
```

5. Configure `git`:

```bash
$ cd metabase-scalingo
$ scalingo --app my-metabase git-setup
```

6. Set required environment variables:

```bash
$ scalingo --app my-metabase env-set METABASE_PORT=3000
```

7. Deploy the application:

```bash
$ git push scalingo master
```

# Architecture

This deployment uses multiple buildpacks to run Metabase behind an nginx reverse proxy.

## Buildpacks

The `.buildpacks` file configures the following buildpacks (in order):

1. **Nginx Buildpack**: Runs nginx on `$PORT` (Scalingo's assigned port)
2. **JVM Common Buildpack**: Provides Java runtime
3. **Metabase Buildpack**: Builds and runs Metabase

The order is important - nginx buildpack must be first to generate the `bin/run` script.

## How It Works

The application starts using `bin/start-with-nginx.sh`, which:

1. Starts Metabase on port 3000 in the background
2. Waits for Metabase to be ready (health check)
3. Starts nginx on `$PORT` in the foreground

Nginx acts as a reverse proxy, forwarding all requests to Metabase while:
- Overriding Content Security Policy (CSP) headers
- Adding custom security headers
- Handling timeouts for long-running queries

## Content Security Policy (CSP) Configuration

This deployment customizes Metabase's default CSP to support:
- Custom script hashes for specific features

The nginx configuration (`nginx.conf.erb`) overrides Metabase's CSP headers. You can add additional script hashes dynamically using the `CSP_SCRIPT_HASHES` environment variable without redeploying.

# Configuring the Application Deployment Environment

The following environment variables are available for you to adjust, depending
on your needs:

| Name                 | Description                                                                              | Default value                                   |
| -------------------- | ---------------------------------------------------------------------------------------- | ----------------------------------------------- |
| `BUILDPACK_URL`      | URL of the buildpack to use.                                                             | https://github.com/Scalingo/multi-buildpack.git |
| `DATABASE_URL`       | URL of your database addon. **Only available if you have a database addon provisioned**. | Provided by Scalingo                            |
| `MAX_METASPACE_SIZE` | Maximum amount of memory allocated to Java Metaspace[^1].                                | `512m` (512MB)                                  |
| `METABASE_PORT`      | Port for Metabase to run on (nginx proxies to this).                                    | `3000`                                          |
| `CSP_SCRIPT_HASHES`  | Additional SHA-256 hashes for script-src CSP directive. Space-separated hash values.    | (empty)                                         |

### Setting CSP Script Hashes

If you encounter CSP violations in browser console, you can add the suggested hashes:

```bash
scalingo --app my-metabase env-set CSP_SCRIPT_HASHES="'sha256-YourHash1=' 'sha256-YourHash2='"
scalingo --app my-metabase restart
```

Example:
```bash
scalingo --app my-metabase env-set CSP_SCRIPT_HASHES="'sha256-YX4iJw93x5SU0ple+RI+95HNdNBZSA60gR8a5v7HfOA=' 'sha256-ZSYgJqvgOEEcwpkGpHB7fKYVqiBkvMiEVITezQz0eIo='"
```

Metabase also [supports many environment variables](https://www.metabase.com/docs/latest/operations-guide/environment-variables.html).

[^1]: See https://wiki.openjdk.org/display/HotSpot/Metaspace for further details about Java Metaspace.

# Updating Metabase on Scalingo

To upgrade to the latest version of Metabase, you only need to redeploy it,
this will retrieve the latest version avaible on [the Metabase buildpack](https://github.com/metabase/metabase-buildpack).

## Updating After Deploying Using Scalingo's One-click Button

If you deployed your Metabase instance via our One-click button, you can update
it with the following command:

```bash
$ scalingo --app my-metabase deploy https://github.com/Scalingo/metabase-scalingo/archive/refs/heads/master.tar.gz
```

If you are facing the `create archive deployment: * git_ref → can't be blank` error, you may need to specify the version explicitly:

```bash
$ scalingo --app my-metabase deploy https://github.com/Scalingo/metabase-scalingo/archive/refs/heads/master.tar.gz v1.0.0
```

## Updating After Deploying Using Scalingo's Command Line Tool

```bash
$ cd metabase-scalingo
$ git pull origin master
$ git push scalingo master
```

# Troubleshooting

## 502 Bad Gateway

If you see a 502 error, Metabase may not be running or hasn't started yet. Check the logs:

```bash
$ scalingo --app my-metabase logs --lines 100
```

Look for:
- "Metabase is ready!" message in logs
- Any Java errors or exceptions
- Database connection issues

## Application Won't Start (Timeout)

If the application times out during boot:

1. Verify `METABASE_PORT` is set to `3000`:
   ```bash
   $ scalingo --app my-metabase env | grep METABASE_PORT
   ```

2. Check that nginx buildpack is first in `.buildpacks` file
3. Review logs for startup errors

## CSP Violations in Browser Console

If you see Content Security Policy errors in your browser console:

1. Copy the suggested hash from the error message
2. Add it to `CSP_SCRIPT_HASHES`:
   ```bash
   $ scalingo --app my-metabase env-set CSP_SCRIPT_HASHES="'sha256-NewHash='"
   $ scalingo --app my-metabase restart
   ```

## Viewing Application Logs

To monitor the application in real-time:

```bash
$ scalingo --app my-metabase logs --follow
```
