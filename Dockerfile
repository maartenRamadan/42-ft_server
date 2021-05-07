# **************************************************************************** #
#                                                                              #
#                                                         ::::::::             #
#    Dockerfile                                         :+:    :+:             #
#                                                      +:+                     #
#    By: mramadan <mramadan@student.codam.nl>         +#+                      #
#                                                    +#+                       #
#    Created: 2020/01/10 12:20:48 by mramadan       #+#    #+#                 #
#    Updated: 2020/01/17 17:22:37 by mramadan      ########   odam.nl          #
#                                                                              #
# **************************************************************************** #

FROM debian:buster

RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install wget sendmail

# NGNINX
RUN apt-get -y install nginx
COPY ./srcs/nginx.conf /etc/nginx/sites-available/mp

# SYMLINK
RUN ln -s /etc/nginx/sites-available/mp /etc/nginx/sites-enabled/
RUN rm -f /etc/nginx/sites-available/default
RUN rm -f /etc/nginx/sites-enabled/default

# SSL
RUN mkdir /etc/nginx/ssl && chmod 700 /etc/nginx/ssl
COPY ./srcs/localssl.key /etc/nginx/ssl/
COPY ./srcs/localssl.crt /etc/nginx/ssl/

# MYSQL
RUN apt-get -y install mariadb-server
RUN service mysql start; \
	echo "CREATE DATABASE mp;" | mysql -u root; \
	echo "GRANT ALL PRIVILEGES ON *.* TO 'mramadan'@'localhost' IDENTIFIED BY 'codam';" | mysql -u root; \
	echo "FLUSH PRIVILEGES" | mysql -u root

# PHPMYADMIN
WORKDIR /var/www/mp/wordpress
RUN apt-get -y install php7.3 php-mysql php-fpm php-cli php-mbstring php-curl php-gd php-intl php-soap php-xml php-xmlrpc php-zip
RUN wget https://files.phpmyadmin.net/phpMyAdmin/4.9.4/phpMyAdmin-4.9.4-english.tar.gz
RUN tar xvzf phpMyAdmin-4.9.4-english.tar.gz && rm -rf phpMyAdmin-4.9.4-english.tar.gz
RUN mv phpMyAdmin-4.9.4-english phpmyadmin
RUN chmod -R 755 phpmyadmin
COPY ./srcs/config.inc.php phpmyadmin

# WORDPRESS
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp
WORKDIR /var/www/mp/wordpress/
RUN service mysql start && \
	wp core download --allow-root && \
	wp config create --dbhost=localhost --dbname=mp --dbuser=mramadan --dbpass=codam --allow-root && \
	wp core install --url=localhost --title="Haaaaai" --admin_name=mramadan --admin_password=codam --admin_email=maartenramadan@gmail.com --allow-root && \
	chmod 644 wp-config.php && \
	chown -R www-data:www-data /var/www/mp && \
	wp theme install https://downloads.wordpress.org/theme/shapely.1.2.8.zip --allow-root && \
	wp theme activate shapely --allow-root && \
	wp plugin install https://downloads.wordpress.org/plugin/classic-editor.1.5.zip --allow-root && \
	wp plugin activate classic-editor --allow-root

RUN chown -R www-data /var/www/mp/wordpress/wp-content/uploads && \
    chmod 777 /var/www/mp/wordpress/wp-content/upgrade && \
    chmod 777 /var/www/mp/wordpress/wp-content/plugins && \
    chmod 777 /var/www/mp/wordpress/wp-content/themes && \
    chmod 777 /var/www/mp/wordpress

# INCREASE LIMITS
RUN cd /etc/php/7.3/fpm && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 10M/g' php.ini && \
	sed -i 's/post_max_size = 8M/post_max_size = 20M/g' php.ini

# RUN
COPY ./srcs/start.sh /root/
ENTRYPOINT bash /root/start.sh

EXPOSE 80 443 110