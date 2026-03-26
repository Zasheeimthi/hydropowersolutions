<?php
// send_mail.php — No SMTP needed. Uses Web3Forms API via cURL.
echo("sendmail enter");
header('Content-Type: application/json');

// Only accept POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Invalid request method.']);
    exit;
}

// Sanitize inputs
$name    = htmlspecialchars(trim($_POST['name']    ?? ''));
$email   = htmlspecialchars(trim($_POST['email']   ?? ''));
$message = htmlspecialchars(trim($_POST['message'] ?? ''));
$access_key = trim($_POST['access_key'] ?? '');

// Basic validation
if (empty($name) || empty($email) || empty($message) || empty($access_key)) {
    echo json_encode(['success' => false, 'message' => 'All fields are required.']);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['success' => false, 'message' => 'Invalid email address.']);
    exit;
}

// Prepare payload for Web3Forms
$payload = json_encode([
    'access_key'      => $access_key,
    'name'            => $name,
    'email'           => $email,
    'message'         => $message,
    'subject'         => "New Contact Form Message from $name", // optional: customize
    'from_name'       => $name,                                 // sender display name
    'replyto'         => $email,                                // reply goes to user's email
    'botcheck'        => '',                                    // spam prevention
]);

// Send via cURL to Web3Forms API
$ch = curl_init('https://api.web3forms.com/submit');
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST           => true,
    CURLOPT_POSTFIELDS     => $payload,
    CURLOPT_HTTPHEADER     => [
        'Content-Type: application/json',
        'Accept: application/json',
    ],
    CURLOPT_TIMEOUT        => 15,
    CURLOPT_SSL_VERIFYPEER => true,
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

// Handle cURL error
if ($curlError) {
    echo json_encode(['success' => false, 'message' => 'Connection failed: ' . $curlError]);
    exit;
}

// Parse and return response
$result = json_decode($response, true);

if ($httpCode === 200 && isset($result['success']) && $result['success'] === true) {
    echo json_encode(['success' => true, 'message' => 'Email sent successfully.']);
} else {
    $errMsg = $result['message'] ?? 'Unknown error from mail service.';
    echo json_encode(['success' => false, 'message' => $errMsg]);
}
?>
