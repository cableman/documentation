#!/usr/bin/env bash

###################################################
# Configure new os2display site
#
# 1) Setup clone search node - if it don't exists
# 2) Setup loop site
#
###################################################

## Define colors.
BOLD=$(tput bold)
UNDERLINE=$(tput sgr 0 1)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

# Versions
SERACH_NODE_VERSION="v2.1.10"
LOOP_VERSION="1.7.2"

##
# Add SSL certificates.
##
function getSSLCertificate {
	while true; do
    read -p "Use fake SSL certificate (y/n)? " yn
    case $yn in
      [Yy]* )
        if [ ! -d '/etc/ssl/nginx' ]; then
          mkdir -p /etc/ssl/nginx
        fi

        if [ -e "/etc/ssl/nginx/server.cert" ]; then
          openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" -keyout /etc/ssl/nginx/server.key  -out /etc/ssl/nginx/server.cert
        fi

        CERT=/etc/ssl/nginx/server.cert
        CERTKEY=/etc/ssl/nginx/server.key
        break
        ;;

    [Nn]* )
        read -p "Location of the SSL certificate: " CERT
        read -p "Location of the SSL certificate key: " CERTKEY
        break
        ;;

    * ) echo "${YELLOW}Please answer yes or no!${RESET}";;
    esac
  done
}

##
# Install search node and configuration.
##
function setupSearchNode {
  echo "${YELLOW}Installing Search Node:${RESET}"

	# Check if search node have been installed.
	if [ -f '/etc/apache2/sites-available/search_node.conf' ]; then
		echo "${YELLOW}Search node exists and will not be installed, so ${GREEN}skipping${YELLOW} this part.${RESET}"
		return;
	fi

	# Clone serch node
	while true; do
		read -p "Where to place search node (/home/www/search_node): " INSTALL_PATH
		if [ -z $INSTALL_PATH ]; then
			INSTALL_PATH="/home/www/search_node"
		fi
		if [ ! -d $INSTALL_PATH ]; then
			mkdir -p $INSTALL_PATH
			git clone https://github.com/search-node/search_node.git ${INSTALL_PATH}/.
			break
		fi
		echo "${RED}Please use another path, that don't exists allready!${RESET}"
	done

	# Checkout version
	cd $INSTALL_PATH
	git checkout ${SERACH_NODE_VERSION}

	# Ensure logs folder exists.
	if [ ! -d ${INSTALL_PATH}/logs ]; then
		mkdir -p ${INSTALL_PATH}/logs
	fi

	# Install npm packages
	echo "${GREEN}Installing search_node requirements...${RESET}"
	${INSTALL_PATH}/install.sh > /dev/null 2>&1

	# Configure apache
	read -p "Search node FQDN (search.example.com): " DOMAIN
	if [ -z $DOMAIN ]; then
		DOMAIN="search.example.com"
	fi

  # Proxy config.
  cat > /etc/apache2/sites-available/search_node.conf <<DELIM
<VirtualHost *:80>
  ServerName ${DOMAIN}
  Redirect permanent / https://${DOMAIN}
</VirtualHost>

<VirtualHost *:443>
  ServerName ${DOMAIN}

  ServerAdmin webmaster@localhost

  <Proxy *>
    Require all granted
  </Proxy>

  ProxyRequests off
  ProxyVia on

  RewriteEngine On
  RewriteCond %{REQUEST_URI}  ^/socket.io            [NC]
  RewriteCond %{QUERY_STRING} transport=websocket    [NC]
  RewriteRule /(.*)           ws://localhost:3010/$1 [P,L]

  ProxyPass        /socket.io http://localhost:3010/socket.io
  ProxyPassReverse /socket.io http://localhost:3010/socket.io

  <Location />
    ProxyPass http://127.0.0.1:3010/
    ProxyPassReverse http://127.0.0.1:3010/
  </Location>

  ErrorLog ${INSTALL_PATH}/logs/apache-error.log
  CustomLog ${INSTALL_PATH}/logs/apache-access.log combined

  SSLEngine on
  SSLProtocol all -SSLv2
  SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM

  SSLCertificateFile ${CERT}
  SSLCertificateKeyFile ${CERTKEY}
</VirtualHost>    
DELIM
  a2ensite search_node.conf 

  # Configure search node.
  echo "${GREEN}Configure search node...${RESET}"
  cd $INSTALL_PATH
  cp example.config.json config.json

  ADMIN_PASSWD=`pwgen 12 1`
  sed -i "/\"password\": \"admin\"/c \"password\": \"${ADMIN_PASSWD}\"" config.json

  SECRET=`pwgen 21 1`
  sed -i "/\"secret\": \"MySuperSecret\",/c \"secret\": \"${SECRET}\"," config.json  

  cat > ${INSTALL_PATH}/mappings.json <<DELIM
    {}
DELIM

  cat > ${INSTALL_PATH}/apikeys.json <<DELIM
    {}
DELIM

  # Add supervisor startup script.
  read -p "Who should the search node be runned as ($(whoami)): " USER
  if [ -z $USER ]; then
    USER=$(whoami)
  fi
  cat > /etc/supervisor/conf.d/search_node.conf <<DELIM
[program:search-node]
command=node ${INSTALL_PATH}/app.js
autostart=true
autorestart=true
environment=NODE_ENV=production
stderr_logfile=/var/log/search-node.err.log
stdout_logfile=/var/log/search-node.out.log
user=${USER}
DELIM

  # Change owner of search node to the selected user.
  chown -R ${USER} ${INSTALL_PATH}

  # Start search node and activate index.
  service supervisor restart

  echo " "
  echo " "
  echo "${GREEN}Search node installed...${RESET}"
  echo -n "Admin password: "
  echo ${ADMIN_PASSWD}
  echo " "
  echo " "
}

##
# Single site setup for search node (index + keys).
##
function setupLoopSearchNode {
  echo "${GREEN}Configure search node indexes...${RESET}"

  ## Login as admin.
  while true; do
    read -p "Search node admin password: " ADMIN_SN_PASSWD
    TOKEN=$(curl -X POST -s \
      http://localhost:3010/login \
        -H 'content-type: application/json' \
        -d "{\"username\": \"admin\", \"password\": \"${ADMIN_SN_PASSWD}\"}" | jq .token)
    if [[ $TOKEN != "null" ]]; then
      TOKEN=`echo ${TOKEN} | sed -e 's/^"//' -e 's/"$//'`
      break;
    fi
    echo "${RED}Wrong password...${RESET}"
  done;

  ## Create type-a-head mapping
  read -p "Name to identify the 'type-a-head' search index by (loop-type-ahead-index): " TAH_NAME
  if [ -z $TAH_NAME ]; then
    TAH_NAME="loop-type-ahead-index"
  fi
  TAH_INDEX=`echo $TAH_NAME | md5sum | cut -f1 -d" "`

  curl -X POST -s \
    "http://localhost:3010/api/admin/mapping/${TAH_INDEX}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H 'Content-Type: application/json' \
    -d '{
      "name": "loop-type-ahead-index",
      "fields": [
        {
          "type": "string",
          "country": "DK",
          "language": "da",
          "default_analyzer": "analyzer_startswith",
          "sort": false,
          "indexable": true,
          "raw": false,
          "geopoint": false,
          "field": "title",
          "default_indexer": "analyzed"
        }
      ],
      "dates": [],
      "tag": "private"
    }' > /dev/null

  ## Activate index
  curl -X GET -s \
    "http://localhost:3010/api/admin/index/${TAH_INDEX}/activate" \
    -H "Authorization: Bearer ${TOKEN}" > /dev/null

  ## Create post's mappings
  read -p "Name to identify the 'post' search index by (loop-post-index): " POST_NAME
  if [ -z $POST_NAME ]; then
    POST_NAME="loop-post-index"
  fi
  POST_INDEX=`echo $POST_NAME | md5sum | cut -f1 -d" "`

  curl -X POST -s \
    "http://localhost:3010/api/admin/mapping/${POST_INDEX}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H 'Content-Type: application/json' \
    -d '{
    "name": "loop-post-index",
    "fields": [
      {
        "type": "string",
        "country": "DK",
        "language": "da",
        "default_analyzer": "string_index",
        "default_indexer": "analyzed",
        "sort": true,
        "indexable": true,
        "raw": false,
        "geopoint": false,
        "field": "title"
      },
      {
        "type": "string",
        "country": "DK",
        "language": "da",
        "default_analyzer": "string_index",
        "default_indexer": "analysed",
        "sort": false,
        "indexable": false,
        "raw": false,
        "geopoint": false,
        "field": "status"
      },
      {
        "type": "string",
        "country": "DK",
        "language": "da",
        "default_analyzer": "string_index",
        "default_indexer": "analyzed",
        "sort": false,
        "indexable": true,
        "raw": false,
        "geopoint": false,
        "field": "comments"
      },
      {
        "type": "string",
        "country": "DK",
        "language": "da",
        "default_analyzer": "string_index",
        "default_indexer": "analyzed",
        "sort": false,
        "indexable": true,
        "raw": false,
        "geopoint": false,
        "field": "body:value"
      },
      {
        "type": "string",
        "country": "DK",
        "language": "da",
        "default_analyzer": "string_index",
        "default_indexer": "analyzed",
        "sort": false,
        "indexable": true,
        "raw": false,
        "geopoint": false,
        "field": "body:summary"
      },
      {
        "type": "string",
        "country": "DK",
        "language": "da",
        "default_analyzer": "string_index",
        "default_indexer": "analyzed",
        "sort": false,
        "indexable": true,
        "raw": false,
        "geopoint": false,
        "field": "field_description:value"
      },
      {
        "type": "string",
        "country": "DK",
        "language": "da",
        "default_analyzer": "string_index",
        "default_indexer": "analyzed",
        "sort": false,
        "indexable": true,
        "raw": false,
        "geopoint": false,
        "field": "field_keyword:name"
      },
      {
        "type": "string",
        "country": "DK",
        "language": "da",
        "default_analyzer": "string_index",
        "default_indexer": "analyzed",
        "sort": false,
        "indexable": true,
        "raw": false,
        "geopoint": false,
        "field": "field_profession:name"
      },
      {
        "type": "string",
        "country": "DK",
        "language": "da",
        "default_analyzer": "string_index",
        "default_indexer": "analyzed",
        "sort": false,
        "indexable": true,
        "raw": false,
        "geopoint": false,
        "field": "field_subject:name"
      },
      {
        "type": "string",
        "country": "DK",
        "language": "da",
        "default_analyzer": "string_index",
        "default_indexer": "analyzed",
        "sort": false,
        "indexable": true,
        "raw": false,
        "geopoint": false,
        "field": "comments:comment_body:value"
      },
      {
        "type": "string",
        "country": "DK",
        "language": "da",
        "default_analyzer": "string_index",
        "default_indexer": "analysed",
        "sort": false,
        "indexable": false,
        "raw": false,
        "geopoint": false,
        "field": "url"
      },
      {
        "type": "string",
        "country": "DK",
        "language": "da",
        "default_analyzer": "string_index",
        "default_indexer": "analysed",
        "sort": false,
        "indexable": false,
        "raw": false,
        "geopoint": false,
        "field": "field_external_link:url"
      },
      {
        "type": "string",
        "country": "DK",
        "language": "da",
        "default_analyzer": "string_index",
        "default_indexer": "analyzed",
        "sort": false,
        "indexable": true,
        "raw": true,
        "geopoint": false,
        "field": "field_subject"
      },
      {
        "type": "string",
        "country": "DK",
        "language": "da",
        "default_analyzer": "string_index",
        "default_indexer": "not_analyzed",
        "sort": false,
        "indexable": true,
        "raw": true,
        "geopoint": false,
        "field": "type"
      }
    ],
    "dates": [
      "created",
      "changed"
    ],
    "tag": "private",
    "suggesters": [
      {
        "field": "title",
        "type": "completion"
      }
    ]
  }' > /dev/null

  ## Activate index
  curl -X GET -s \
    "http://localhost:3010/api/admin/index/${POST_INDEX}/activate" \
    -H "Authorization: Bearer ${TOKEN}" > /dev/null

  # Config file for apikeys
  read -p "Name to identify the API key by (loop-test): " APINAME
  if [ -z $APINAME ]; then
    APINAME="loop-test"
  fi

  ## Add API key.
  APIKEY_WRITE=`echo $APINAME "(write)" | md5sum | cut -f1 -d" "`
  curl -X POST -s \
    http://localhost:3010/api/admin/key \
    -H "Authorization: Bearer ${TOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{
    \"api\": {
    \"key\": \"${APIKEY_WRITE}\",
      \"name\": \"${APINAME} (write)\",
      \"expire\": 300,
      \"access\": \"rw\",
      \"indexes\": [ \"${TAH_INDEX}\", \"${POST_INDEX}\" ]
    }
  }" > /dev/null

  ## Add API key.
  APIKEY_READ=`echo $APINAME "(read)" | md5sum | cut -f1 -d" "`
  curl -X POST -s \
    http://localhost:3010/api/admin/key \
    -H "Authorization: Bearer ${TOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{
    \"api\": {
    \"key\": \"${APIKEY_READ}\",
      \"name\": \"${APINAME} (read)\",
      \"expire\": 300,
      \"access\": \"r\",
      \"indexes\": [ \"${TAH_INDEX}\", \"${POST_INDEX}\" ]
    }
  }" > /dev/null
}

##
# Install loop.
##
function setupDrupalLoop {
  while true; do
    read -p "Where to place loop (/home/www/loop): " INSTALL_PATH
    if [ -z $INSTALL_PATH ]; then
      INSTALL_PATH="/home/www/loop"
    fi
    if [ ! -d $INSTALL_PATH ]; then
      drush make https://raw.githubusercontent.com/os2loop/profile/${LOOP_VERSION}/drupal.make ${INSTALL_PATH} > /dev/null
      break
    fi
    echo "${RED}Please use another path, that don't exists allready!${RESET}"
  done

  echo "${GREEN}Configuring loop...${RESET}"
  read -p "Loop FQDN (loop.example.com): " DOMAIN
  if [ -z $DOMAIN ]; then
    DOMAIN="loop.example.com"
  fi

  echo "${GREEN}Configuring MySQL...${RESET}"
  echo -n "MySQL root password: "
  read -s PASSWORD
  echo " "

  CLEAN=${DOMAIN//./}
  CLEAN=${CLEAN//[^a-zA-Z0-9_]/}
  RANCHARS=`pwgen 8 1`
  MYSQL_PASS=`pwgen 21 1`
  MYSQL_USER=$CLEAN$RANCHARS
  MYSQL_DB=$CLEAN$RANCHARS

  mysql -uroot --password="${PASSWORD}" <<MYSQL_SCRIPT
DROP DATABASE IF EXISTS ${MYSQL_DB};
CREATE DATABASE ${MYSQL_DB};
CREATE USER \`${MYSQL_USER}\`@\`localhost\` IDENTIFIED BY '${MYSQL_PASS}';
GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO \`${MYSQL_USER}\`@\`localhost\` IDENTIFIED BY '${MYSQL_PASS}';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

  ADMIN_PASSWD=`pwgen 12 1`
  drush --yes --root="${INSTALL_PATH}" site-install loopdk --db-url="mysql://${MYSQL_USER}:${MYSQL_PASS}@localhost/${MYSQL_DB}" --site-name=${DOMAIN} --account-name=admin --account-pass=${ADMIN_PASSWD}

  # Apache configuration.
  CONF_FILE=${DOMAIN//./_}
  cat > /etc/apache2/sites-available/${CONF_FILE}.conf <<DELIM
<VirtualHost *:80>
  ServerName ${DOMAIN}
  Redirect permanent / https://${DOMAIN}
</VirtualHost>

<IfModule mod_ssl.c>
  <VirtualHost _default_:443>
    ServerAdmin webmaster@localhost
    ServerName ${DOMAIN}

    DocumentRoot ${INSTALL_PATH}
    <Directory ${INSTALL_PATH}>
      Options FollowSymLinks
      AllowOverride All
      Require all granted
    </Directory>

    <IfModule mod_deflate.c>
      SetOutputFilter DEFLATE
      SetEnvIfNoCase Request_URI \.(?:gif|jpg|png|ico|zip|gz|mp4|flv)$ no-gzip
    </IfModule>

    ErrorLog ${APACHE_LOG_DIR}/${CONF_FILE}_error.log
    CustomLog ${APACHE_LOG_DIR}/${CONF_FILE}_access.log combined

    SSLEngine on
    SSLCertificateFile ${CERT}
    SSLCertificateKeyFile ${CERTKEY}

    <FilesMatch "\.(cgi|shtml|phtml|php)$">
        SSLOptions +StdEnvVars
    </FilesMatch>

    BrowserMatch "MSIE [2-6]" \
        nokeepalive ssl-unclean-shutdown \
        downgrade-1.0 force-response-1.0
    # MSIE 7 and newer should be able to use keepalive
    BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown

  </VirtualHost>
</IfModule>
DELIM

  a2ensite ${CONF_FILE}.conf

  # Search node site configuration
  setupLoopSearchNode;

  # Added search configuration to settings.php.
  echo "${GREEN}Configure drupal search node...${RESET}"
  echo " "
  read -p "Search node FQDN (https://search.example.com): " DOMAIN
  if [ -z $DOMAIN ]; then
    DOMAIN="https://search.example.com"
  fi

  cat >> ${INSTALL_PATH}/sites/default/settings.php <<DELIM
\$conf['search_api_loop_search_node_apikey'] = '${APIKEY_WRITE}';
\$conf['search_api_loop_search_node_apikey_readonly'] = '${APIKEY_READ}';
\$conf['search_api_loop_search_node_host'] = '${DOMAIN}';

\$conf['search_api_loop_search_node_index_posts'] = '${TAH_INDEX}';
\$conf['search_api_loop_search_node_index_auto_complete'] = '${POST_INDEX}';
DELIM

  ## Change to loop to search node.
  echo "${GREEN}Change loop to use search node...${RESET}"
  drush --yes --root="${INSTALL_PATH}" dis loop_search search_api_spellcheck search_api_views search_api_page search_api_solr
  drush --yes --root="${INSTALL_PATH}" pm-uninstall loop_search search_api_spellcheck search_api_views search_api_page search_api_solr
  drush --yes --root="${INSTALL_PATH}" en search_api_search_node 
  drush --yes --root="${INSTALL_PATH}" en loop_search_node loop_search_node_settings search_node_page 

  echo " "
  echo " "
  echo "${GREEN}Site installed...${RESET}"
  echo -n "Admin password: "
  echo ${ADMIN_PASSWD}
  echo " "
  echo " "
}

##
# Restart services.
##
function restartServices {
  service supervisor restart
  service apache2 restart
  service elasticsearch restart
}

##
# Make sure only root can run our script.
##
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

getSSLCertificate;

while (true); do
  echo "##########################################"
  echo "##            ${YELLOW}Installation${RESET}              ##"
  echo "##########################################"
  echo "##                                      ##"
  echo "##  1 - Search node (if not installed)  ##"
  echo "##  2 - New site                        ##"
  echo "##  x - Exit                            ##"
  echo "##                                      ##"
  echo "##########################################"
  read -p "What should we install (1-4)? " SELECTED
  case $SELECTED in
    1)
      setupSearchNode;
      restartServices;
      ;;

    2)
      setupDrupalLoop;
      restartServices;
      ;;

    x)
      break;;

  esac
done
