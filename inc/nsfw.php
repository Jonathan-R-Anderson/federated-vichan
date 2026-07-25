<?php
/*
 *  NSFW image scoring (Yahoo open_nsfw via the `nsfw` service)
 *  ----------------------------------------------------------
 *  nsfw_score_file()      -> POSTs an image to the scoring service, returns its NSFW probability.
 *  nsfw_config_for_board() -> resolves the effective policy (enabled / threshold / action) for a
 *                             board: a per-board row overrides the global default row (board = ''),
 *                             which overrides the built-in config defaults.
 *
 *  Both are best-effort: a scoring outage returns status 'error', and the caller decides whether
 *  to fail open (accept) or fail closed (reject) per the board's policy.
 */

function nsfw_score_file($config, $path) {
	$host    = isset($config['nsfw']['host']) ? $config['nsfw']['host'] : 'nsfw';
	$port    = isset($config['nsfw']['port']) ? (int)$config['nsfw']['port'] : 8080;
	$timeout = isset($config['nsfw']['timeout']) ? (int)$config['nsfw']['timeout'] : 20;

	if (!is_readable($path) || @filesize($path) === 0) {
		return array('status' => 'error', 'score' => 0.0, 'error' => 'unreadable file');
	}
	$data = @file_get_contents($path);
	if ($data === false) {
		return array('status' => 'error', 'score' => 0.0, 'error' => 'read failed');
	}

	$ch = curl_init('http://' . $host . ':' . $port . '/score');
	curl_setopt_array($ch, array(
		CURLOPT_POST           => true,
		CURLOPT_POSTFIELDS     => $data,
		CURLOPT_HTTPHEADER     => array('Content-Type: application/octet-stream', 'Expect:'),
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_TIMEOUT        => $timeout,
		CURLOPT_CONNECTTIMEOUT => 5,
	));
	$body = curl_exec($ch);
	$code = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
	$cerr = curl_error($ch);
	curl_close($ch);

	if ($body === false || $code !== 200) {
		return array('status' => 'error', 'score' => 0.0, 'error' => $cerr !== '' ? $cerr : ('http ' . $code));
	}
	$json = json_decode($body, true);
	if (!is_array($json) || !isset($json['score'])) {
		return array('status' => 'error', 'score' => 0.0, 'error' => 'bad response');
	}
	return array('status' => 'ok', 'score' => (float)$json['score']);
}

// Best-effort health probe of the scoring service, for the admin status line.
function nsfw_service_ping($config) {
	$host = isset($config['nsfw']['host']) ? $config['nsfw']['host'] : 'nsfw';
	$port = isset($config['nsfw']['port']) ? (int)$config['nsfw']['port'] : 8080;
	$ch = curl_init('http://' . $host . ':' . $port . '/healthz');
	curl_setopt_array($ch, array(
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_TIMEOUT        => 5,
		CURLOPT_CONNECTTIMEOUT => 3,
	));
	$r = curl_exec($ch);
	$code = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
	curl_close($ch);
	return $r !== false && $code === 200;
}

function nsfw_config_for_board($config, $board_uri) {
	$eff = array(
		'enabled'     => !empty($config['nsfw']['default_enabled']),
		'threshold'   => isset($config['nsfw']['threshold']) ? (float)$config['nsfw']['threshold'] : 0.8,
		'action'      => (isset($config['nsfw']['action']) && $config['nsfw']['action'] === 'spoiler') ? 'spoiler' : 'reject',
		'fail_closed' => !empty($config['nsfw']['fail_closed']),
	);

	// Hard master switch (service not wired up at all).
	if (empty($config['nsfw']['available'])) {
		$eff['enabled'] = false;
		return $eff;
	}

	// Apply the global default row (board = '') first, then the per-board row, so a board-specific
	// setting always wins over the site-wide default.
	foreach (array('', (string)$board_uri) as $key) {
		$q = prepare('SELECT `enabled`, `threshold`, `action` FROM `nsfw_settings` WHERE `board` = :b');
		$q->bindValue(':b', $key);
		if ($q->execute()) {
			$row = $q->fetch(PDO::FETCH_ASSOC);
			if ($row) {
				$eff['enabled']   = (bool)$row['enabled'];
				$eff['threshold'] = (float)$row['threshold'];
				$eff['action']    = $row['action'] === 'spoiler' ? 'spoiler' : 'reject';
			}
		}
	}
	return $eff;
}
