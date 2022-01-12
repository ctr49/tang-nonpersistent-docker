#!/bin/bash
# vim: set tabstop=8 shiftwidth=4 softtabstop=4 expandtab smarttab colorcolumn=80:

set -e

### NGINX ###

# finalizing nginx config based on ENV variables

# ... adding ACLs for systems that may access
NGINX_ALLOW=""
IFS=':' read -ra CIDR_LIST <<< ${WHITELIST}
for CIDR in "${CIDR_LIST[@]}"; do
   NGINX_ALLOW="${NGINX_ALLOW}\t\tallow ${CIDR};\n"
done

if [ ! -z "$NGINX_ALLOW" ]; then
  sed -i "s,#__CIDR__,$NGINX_ALLOW," /home/myuser/nginx-reverse-tang
fi

# ... adding trusted proxies to look at XFF headers as source

PROXY_TRUSTED=""
IFS=':' read -ra PROXY_LIST <<< ${TRUSTED_PROXY}
for PROXY in "${PROXY_LIST[@]}"; do
   PROXY_TRUSTED="${PROXY_TRUSTED}\tset_real_ip_from ${PROXY};\n"
done

if [ ! -z "$PROXY_TRUSTED" ]; then
  sed -i "s,#__PROXY__,${PROXY_TRUSTED}\n\treal_ip_header\tX-Forwarded-For;," /home/myuser/nginx-reverse-tang
fi

# ... add listening port, check config and start nginx

sed -i "s/__PORT__/$PORT/" /home/myuser/nginx-reverse-tang && \
  nginx -c /home/myuser/nginx-reverse-tang -t && \
  nginx -c /home/myuser/nginx-reverse-tang &

### TANG ###

# Populating tang db from ENV variables

# ... using the current keys

for CURRENT_KEY in TANG_LATEST_SV TANG_LATEST_DK; do
	if [[ ! -z "${CURRENT_KEY}" && ! -z "${!CURRENT_KEY}" ]]; then
		cat <<- EOF > /var/db/tang/${CURRENT_KEY:5}.jwk
			${!CURRENT_KEY}
		EOF
	fi
done

# ... adding any old keys if present

for OLD_KEY in $(compgen -v TANG_OLD_); do
	cat <<- EOF > /var/db/tang/.${OLD_KEY:9}.jwk
		${!OLD_KEY}
	EOF
done

# ... check if we have any keys in the db, display results

chk_files=($(ls -1A /var/db/tang))
echo -e "Keys in /var/db/tang/:"
( IFS=$'\n'; echo "${chk_files[*]}" )

# ... update cache if we have 2 or more keys (otherwise tang wouldn't work)
if [ ${#chk_files[@]} -gt 1 ]; then
  echo "Populating tang cache from DB ..."
  /usr/lib/x86_64-linux-gnu/tangd-update /var/db/tang /var/cache/tang
else
  echo "Not enough keys in DB, check ENV for TANG_CURRENT_SV and TANG_CURRENT_DK values"
  exit 1
fi

# start tang, wrapped by socat

if [ $? -eq 0 ]; then
  echo "Starting tang ..."
  socat tcp-l:8080,reuseaddr,fork exec:"/usr/libexec/tangd /var/cache/tang"
fi
