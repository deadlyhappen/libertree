The reference implementation of the Libertree components are available
as RPM and DEB packages.  We provide package repositories for Debian
Wheezy for 64-bit systems.  For other systems please see the
instructions in MANUAL-INSTALLATION.md.

# Pre-installation notes

Due to some deficiencies of our experimental packages, a user account
named `libertree` has to be created manually.

~~~
$ su -
$ adduser libertree
$ passwd libertree
~~~

The following steps are written under the assumption that you have
some system administration experience.  We intend to simplify this
process eventually, but some administration skills will always be
required.


# Debian Wheezy (64 bit)

Next, the experimental Debian repository is added to the list of apt
sources.  Finally, the two components (frontend and backend) are
installed.

~~~
$ su -
$ echo "deb http://repo.elephly.net/debian/ wheezy main" >> /etc/apt/sources.list
$ apt-get update
$ apt-get install libertree-{frontend,backend}
~~~


# Post-install configuration

The database will have to be configured next.  After initialising the
postgresql cluster and starting the postgresql server daemon, perform
the following steps:

## Database configuration

To simplify database administration, it is recommended to configure
PostgreSQL to trust local connections.  Please confirm that the
configuration file \`pg_hba.conf' contains the following lines:

    local  all  all       trust
    local  all  postgres  trust

If you see 'peer', 'ident', or 'md5' instead of 'trust', please change
the lines and reload the PostgreSQL server configuration (or restart
the postgresql daemon).  While this change is not required, it is
highly recommended because authentication often gets in the way.

Common locations of the pg_hba.conf file are:

* Debian & Ubuntu Server: /etc/postgresql/9.1/main/pg_hba.conf

* Fedora: /var/lib/pgsql/data/pg_hba.conf

Three simple steps need to be performed initially:

- create a database user "libertree"
- create the "libertree_production" database
- run the migration script

~~~
$ cd /opt/libertree/db
$ ./createuser.sh
$ ./createdb.sh
$ cp database.yaml.example database.yaml
$ LIBERTREE_ENV=production ./migrate.sh
~~~

Only the last step is required after updates to the `libertree-db`
package.


## Frontend configuration

To expose the frontend to the Internet, a proxying web server, such as
nginx or Apache, is recommended.  Under
`/opt/libertree/frontend-ramaze/config/` you can find an example
configuration files for an nginx setup (`libertree.nginx.example`) and
an Apache vhost definition (`libertree.apache.example`).  For nginx,
copy the configuration file to
`/etc/nginx/sites-available/libertree.conf`, adjust it if necessary,
and link it to `/etc/nginx/sites-enabled/libertree.conf` when you are
ready to deploy it.

The frontend also requires configuration.  Edit the files in
`/opt/libertree/frontend-ramaze/config/`.


## Connecting the backend to an XMPP server

The Libertree backend contains an XMPP server component which is
responsible for communication with other Libertree installations.  The
Libertree backend should work with any standard XMPP server.  We
recommend Prosody, because it is easy to set up.  If you are using
Prosody, you may want to add the following snippet to the prosody
configuration:

~~~
Component "libertree.myserver.net"
    component_secret = "the-component-secret"
~~~

This will tell the XMPP server that a service listens at the domain
name "libertree.myserver.net" and that it will register with the given
shared secret.  Make sure that this secret is the same as the one
specified in the backend's configuration file.  Also, you need to make
sure that the backend is in fact configured to listen on the specified
domain name.  Do take a look at
`/opt/libertree/backend-rb/config.yaml.example`; it contains the
settings that *must* be customised before you can expect the backend
to work.  Copy this file to `config.yaml` and edit the settings.  More
settings are available in `/opt/libertree/backend-rb/defaults.yaml`.
Unless a conflicting definition is configured in `config.yaml` the
defaults from `defaults.yaml` are used.

Setting up an XMPP server is not covered by these instructions.  The
recommended (and easiest) configuration is to make the XMPP server
listen on the root domain name (e.g. `myserver.net`) and assign the
Libertree component a subdomain (e.g. `libertree.myserver.net`), both
of which are configured to point to the very same IP address.

According to the
[XMPP protocol specifications](http://xmpp.org/rfcs/rfc6120.html#tcp-resolution)
a remote XMPP server will look up DNS information for another XMPP
server before establishing a connection.  The preferred method is to
use SRV (service) records.  In our setting, a remote server queries a
DNS server for the XMPP SRV record associated with the domain of the
Libertree component (e.g. `libertree.myserver.net`).  If a SRV record
exists, it will proceed to look up the IP address of the server named
in the SRV record.  If no SRV record exists for the component domain,
the IP of the component domain is looked up.  If the IP of the
component domain is in fact the same as the IP mapped to the host
running the XMPP server programme, all is well and communication with
the XMPP server is established.

For advanced configurations with SRV records, please do read up on
[SRV records](http://prosody.im/doc/dns).  If you do not already have
a properly configured XMPP server do yourself a favour and read the
[excellent Prosody documentation](http://prosody.im/doc).


# Starting it all

The frontend and backend processes can be started with the provided
service scripts:

~~~
$ su -
$ cd /opt/libertree
$ ./frontend-ramaze/service.sh start
$ ./backend-rb/service.sh start
~~~


# Updating

To update an existing installation just fetch the latest version from
the repository:

~~~
$ su -
$ apt-get update
$ apt-get upgrade
~~~

After upgrading any Libertree component, perform the following steps:

- compare the configuration files against the example files to see if
  they need updating
- run the migration script (`LIBERTREE_ENV=production
  /opt/libertree/db/migrate.sh`) to update the database schema.
- restart all Libertree processes:

~~~
$ su -
$ cd /opt/libertree
$ ./frontend-ramaze/service.sh restart
$ ./backend-rb/service.sh restart
~~~
