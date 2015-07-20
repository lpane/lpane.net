upstream mhlan {
	server 127.0.0.1:8081;
}

server {
	listen 80;
	server_name mhlan.com www.mhlan.com;
	root /var/www/mhlan.com/public;

	# Dynamic content, forward to hypnotoad
	location / {
    	proxy_pass http://mhlan;
    	proxy_http_version 1.1;
    	proxy_set_header Upgrade $http_upgrade;
    	proxy_set_header Connection "upgrade";
    	proxy_set_header Host $host;
    	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    	proxy_set_header X-Forwarded-Proto $scheme;
	}

	location /img/ {
		expires max;
	}

	location /js/ {
		expires max;
	}

	location /css/ {
		expires max;
	}
}
