
# Default server configuration
#
{% if system.ssl == 'letsencrypt' %}
server {

    # Webmail FQDN
    listen 80;
    server_name {{ roundcube.url }};

    # Certificate renewal
    location /.well-known {
        alias /var/www/webmail/.well-known;
    }

    location / {
        # Use Letsencrypt and force https
        rewrite ^ https://$server_name$request_uri? permanent;

        # log files per virtual host
        access_log /var/log/nginx/roundcube-access.log;
        error_log /var/log/nginx/roundcube-error.log;
    }
}
{% endif %}

# Default server configuration
#
server {

    # Webmail FQDN
    server_name {{ roundcube.url }};

    # Default roundcube location on Debian
    root /var/lib/roundcube/;

    # Remove useless tokens for better security feelings ;-)
    server_tokens off;

    # Maximum upload size for attachments
    client_max_body_size {{ mail.max_attachment_size }}M;

    {% if system.ssl == 'letsencrypt' %}
    # SSL configuration
    listen 443 ssl http2;
    ssl_protocols TLSv1.1 TLSv1.2;
    ssl_certificate /etc/letsencrypt/live/{{ roundcube.url }}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/{{ roundcube.url }}/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/{{ roundcube.url }}/fullchain.pem;
    {% endif %}

    # Add index.php to the list if you are using PHP
    index index.php index.html;

    # log files per virtual host
    access_log /var/log/nginx/roundcube-access.log;
    error_log /var/log/nginx/roundcube-error.log;

    # Do not use a favicon
    location ~ ^/favicon.ico$ {
        root /var/www/default/;
        log_not_found off;
        access_log off;
        expires max;
    }

    # Nothing here
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # Deny a few files. TODO: Remove these files uppon install
    location ~ ^/(README|INSTALL|LICENSE|CHANGELOG|UPGRADING)$ {
        deny all;
    }
    location ~ ^/(bin|SQL)/ {
        deny all;
    }

    location ~ ^/installer/.* {
        deny all;
    }
    location ~ /\.ht {
        deny all;
    }
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Finally, activate the PHP routing
    location ~ \.php$ {
        try_files $uri = 404;
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_index index.php;
    }
}
