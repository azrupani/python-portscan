<?php
require './db/db-connect.php' 
?>
<html>
<head>
        <title>Update Resource</title>
        <link href="basic.css" rel="stylesheet" type="text/css">
</head>
<body>
	<div id="main">
		<h1>Update Resource</h1>
		<?php
			if (isset($_POST['resource-id'])) {
			// If we have an ID means we intend to show the update form
				$ResourceId = $_POST['resource-id'];
				echo "<form method=\"POST\" action=\"resource-update.php\">
					<label for=\"ResourceId\">Resource ID:</label>
					<input type=\"label\" name=\"resource-id-update-required\" value=$ResourceId readonly></input>
					<br/>
					<label for=\"MonitoringStatus\">Monitoring Status:</label>
					<select name=\"monitoring-status\">
					  <option value=\"1\" selected>Enabled</option>
					  <option value=\"0\">Disabled</option>
					</select>
					<br/><br/>
					<button type=\"submit\" name=\"update_resource_final\">Update Resource</button>
					<button type=\"reset\" value=\"Reset\">Reset</button>
                                     </form>";
			} elseif (isset($_POST['resource-id-update-required'])) {
			// Do the update and redirect to the list all resources page
				$ResourceId = $_POST['resource-id-update-required'];
				$MonitoringStatus = $_POST['monitoring-status'];
				
				$db_query = "UPDATE scan_target SET MonitoringEnabled = $MonitoringStatus WHERE Id = $ResourceId";
				if ($conn->query($db_query) === TRUE) {
					header('Location: /list-resources.php');
				} else {
					echo "<h1>Update Failed!</h1>" . $conn->error;
				}

			}
		?>
	</div>
<body>
</html>

<?php
require './db/db-close.php' 
?>
