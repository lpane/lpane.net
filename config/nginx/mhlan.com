server {
    server_name mhlan.com www.mhlan.com;
	root /var/www/mhlan.com/web;

    access_log off;

    # Dynamic content, forward to Apache
    location / {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_pass http://127.0.0.1:8080;
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
