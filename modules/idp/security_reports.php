<?php
$files_dir = '/var/www/security-reports/files';
if (!is_dir($files_dir)) mkdir($files_dir, 0755, true);
$method = $_SERVER['REQUEST_METHOD'];
if ($method === 'GET') {
    $files = array_diff(scandir($files_dir), ['.', '..']);
    header('Content-Type: text/html');
    echo "<!doctype html><html><body><h1>Security Reports</h1>\n<ul>\n";
    foreach ($files as $f) {
        echo "  <li><a href='/security-reports/files/" . htmlspecialchars($f) . "'>" . htmlspecialchars($f) . "</a></li>\n";
    }
    echo "</ul>\n<p>Upload: <code>curl -X PUT -d @report.html 'https://HOST/security-reports/?filename=report.html'</code></p>\n</body></html>\n";
} elseif ($method === 'POST' || $method === 'PUT') {
    if (!empty($_FILES['file'])) {
        $filename = basename($_FILES['file']['name']);
        move_uploaded_file($_FILES['file']['tmp_name'], "$files_dir/$filename");
    } else {
        $filename = preg_replace('/[^a-zA-Z0-9._-]/', '_', $_GET['filename'] ?? 'report.html');
        file_put_contents("$files_dir/$filename", file_get_contents('php://input'));
    }
    http_response_code(201);
    echo "Saved as $filename\n";
}
