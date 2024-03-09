const b2BucketPath = `/file/${B2_BUCKET_NAME}`;

addEventListener('fetch', event => {
	return event.respondWith(handler(event));
});

function cacheHeaders({ headers: originHeaders } = {}) {
  const headers = new Headers();

  if(originHeaders.get('Content-Type') === 'text/html') {
    headers.set('Cache-Control', 'public, max-age=0, s-maxage=300, '); // No browser cache, 5 min CDN cache
  } else {
    headers.set('Cache-Control', 'public, max-age=31536000'); // Cache assets for 1 year
  }

  const etag = originHeaders.get('x-bz-content-sha1');
  if(etag) {
    headers.set('ETag', etag);
  }

  return headers;
}

async function handler(event) {
  const url = new URL(event.request.url);

	// Full b2 object path (remove trailing slash)
  url.pathname = b2BucketPath + url.pathname.replace(/\/+$/, '');
  if (!(/(\.[^\/]+)$/).test(url.pathname)) { // Path w/ no file extension defaults to index page
		url.pathname += '/index.html';
	}

  // Return cached response if available
  const cache = caches.default;
  let response = await cache.match(event.request);
  if(response) {
    const headers = cacheHeaders(response);

  	return new Response(response.body, {
  		status: response.status,
      statusText: response.statusText,
  		headers,
  	});
  }

  // Fetch asset from B2 origin
  response = await fetch(url);

  if(response.status === 404) { // Fetch and stream 404 page
    const { status, statusText } = response;

    response = await fetch(url.origin + b2BucketPath + '/404.html');
    const headers = new Headers();
    headers.set('Cache-Control', 'public, max-age=300'); // Five minute cache

    const { readable, writable } = new TransformStream();
    response.body.pipeTo(writable);

    return new Response(readable, {
      status,
      statusText,
      headers,
    });
  }

  const headers = cacheHeaders(response);
  return new Response(response.body, {
  	status: response.status,
  	statusText: response.statusText,
  	headers,
  });
};
