<?php

$redis = new Redis();
$con   = $redis->connect(WP_REDIS_HOST, WP_REDIS_PORT);

if ( !$con ) {
	http_response_code(500);
	die("Redis not connected");
}
$redis->close();
echo "ok";
http_response_code(200);

