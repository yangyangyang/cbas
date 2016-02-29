#!/usr/bin/env cram
# vim: set syntax=cram :

# test the help

  $ cbas --help
  Usage: cbas [OPTIONS] COMMAND [ARGS]...
  
  Options:
    -v, --verbose                   Activate verbose mode.
    -c, --config <config_path>      Path to config file.
    -u, --username <username>       Username.
    -a, --auth-url <auth_url>       Auth-server URL.
    -s, --client-secret <secret>    Special client secret, ask mum.
    -p, --password-provider <provider>
                                    Password provider.
    -h, --jump-host <host>          Jump host to connect with.
    -k, --ssh-key-file <key-file>   SSH Identity to use.
    --version                       Print version and exit.
    --help                          Show this message and exit.
  
  Commands:
    delete  Delete user.
    upload  Upload ssh-key and create user

# Start the mocked auth & cbastion server

  $ cp "$TESTDIR/mocked_cbastion.py" .
  $ ./mocked_cbastion.py >/dev/null 2>&1 &
  $ MOCK_PID=$!
  $ echo $MOCK_PID
  \d+ (re)

# Maybe wait for the bottle server to start

  $ sleep 1
  $ echo "supar-successful-pubkey" >pubkey.pub

# Test that a HTTP 400 from the auth server raises an error

  $ cbas -u auth_fail -p testing -k pubkey.pub -h localhost -s client_secret -a http://localhost:8080/oauth/token upload
  Will now attempt to obtain an JWT...
  Authentication failed: errored with HTTP 400 on request
  [1]

# Test a successful creation

  $ echo "supar-successful-pubkey" >pubkey.pub

  $ cbas -u user_ok -p testing -k pubkey.pub -h localhost:8080 -s client_secret -a http://localhost:8080/oauth/token upload
  Will now attempt to obtain an JWT...
  Authentication OK!
  Access token was received.
  Will now attempt to upload your ssh-key...
  Upload OK!

# Test a negative case when a user creation fails

  $ echo "" >pubkey.pub
  $ cbas -u create_fail -p testing -k pubkey.pub -h localhost:8080 -s client_secret -a http://localhost:8080/oauth/token upload
  Will now attempt to obtain an JWT...
  Authentication OK!
  Access token was received.
  Will now attempt to upload your ssh-key...
  Upload failed: Permission denied
  Error: HTTP response code from c-bastion was 403
  [1]

# Test a positive case for user deletion

  $ cbas -u user_ok -p testing -h localhost:8080 -s client_secret -a http://localhost:8080/oauth/token delete
  Will now attempt to obtain an JWT...
  Authentication OK!
  Access token was received.
  Will now attempt to delete your user...
  Delete OK!

# Test a negative case for user deletion

  $ cbas -u delete_fail -p testing -h localhost:8080 -s client_secret -a http://localhost:8080/oauth/token delete
  Will now attempt to obtain an JWT...
  Authentication OK!
  Access token was received.
  Will now attempt to delete your user...
  Delete failed!
  Error: HTTP response code from c-bastion was 403
  [1]

# Shut down the mocked cbastion/auth server

  $ rm pubkey.pub
  $ kill $MOCK_PID
