<?php

// Connect to the DB

$servername = "<ADDME>";
$username = "<ADDME>";
$password = "<ADDME>";
$dbname = "syseng_scan"; 

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
} 

#echo "Connected to DB successfully";

?>
