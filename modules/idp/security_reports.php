<?php
$files_dir = '/var/www/security-reports/files';
if (!is_dir($files_dir)) mkdir($files_dir, 0755, true);
$method = $_SERVER['REQUEST_METHOD'];

// Handle DELETE requests
if ($method === 'DELETE') {
    parse_str(file_get_contents('php://input'), $_DELETE);
    $filename = basename($_GET['filename'] ?? $_DELETE['filename'] ?? '');
    
    if (empty($filename)) {
        http_response_code(400);
        echo "Error: No filename specified\n";
        exit;
    }
    
    $filepath = "$files_dir/$filename";
    
    if (!file_exists($filepath)) {
        http_response_code(404);
        echo "Error: File not found\n";
        exit;
    }
    
    if (unlink($filepath)) {
        http_response_code(200);
        echo "Deleted: $filename\n";
    } else {
        http_response_code(500);
        echo "Error: Could not delete $filename\n";
    }
    exit;
}

if ($method === 'GET') {
    $files = array_diff(scandir($files_dir), ['.', '..']);
    
    // Natural order sorting
    natsort($files);
    
    header('Content-Type: text/html');
    echo "<!doctype html><html><head>
    <style>
        table { border-collapse: collapse; width: 100%; }
        th, td { padding: 10px; text-align: left; border: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        tr:hover { background-color: #f5f5f5; }
        .delete-btn { 
            background-color: #ff4444; 
            color: white; 
            border: none; 
            padding: 5px 10px; 
            cursor: pointer;
            border-radius: 3px;
        }
        .delete-btn:hover { background-color: #cc0000; }
    </style>
    <script>
        function deleteFile(filename) {
            if (confirm('Are you sure you want to delete ' + filename + '?')) {
                fetch(window.location.href + '?filename=' + encodeURIComponent(filename), {
                    method: 'DELETE'
                })
                .then(response => {
                    if (response.ok) {
                        alert('Successfully deleted: ' + filename);
                        location.reload();
                    } else {
                        return response.text().then(text => { throw new Error(text); });
                    }
                })
                .catch(error => {
                    alert('Error: ' + error.message);
                });
            }
        }
    </script>
    </head><body>
    <h1>Security Reports</h1>\n";
    echo "<table border='1' cellpadding='10'>\n";
    echo "<tr><th>Filename</th><th>Last Modified Date</th><th>Size</th><th>Action</th><tr>\n";
    
    foreach ($files as $f) {
        $filepath = "$files_dir/$f";
        $modified_date = date('Y-m-d H:i:s', filemtime($filepath));
        $file_size = round(filesize($filepath) / 1024, 2) . ' KB';
        echo "  <tr>";
        echo "    <td><a href='/security-reports/files/" . htmlspecialchars($f) . "'>" . htmlspecialchars($f) . "</a></td>";
        echo "    <td>" . htmlspecialchars($modified_date) . "</td>";
        echo "    <td>" . htmlspecialchars($file_size) . "</td>";
        echo "    <td>";
        echo "<button class='delete-btn' onclick='deleteFile(\"" . htmlspecialchars($f) . "\")'>Delete</button>";
        echo "  </td>";
        echo "  </tr>\n";
    }
    
    echo "</table>\n";
    echo "<p><strong>Upload file:</strong> <code>curl -X PUT -d @report.html 'https://HOST/security-reports/?filename=report.html'</code></p>\n";
    echo "<p><strong>Delete file via command line:</strong> <code>curl -X DELETE 'https://HOST/security-reports/?filename=report.html'</code></p>\n";
    echo "</body></html>\n";
    
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
