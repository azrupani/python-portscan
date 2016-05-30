<?php
require './db/db-connect.php' 
?>
<html>
<head>
        <title>Portscan - List Resources</title>
        <link href="basic.css" rel="stylesheet" type="text/css">
</head>
<body>
	<div id="main">
		<h1>List Resources</h1>
		<div id="table-div">
			<table class="table">
				<tr>
					<th>Resource</th>
					<th>Resource Type</th>
					<th>Target Type</th>
					<th>Scan Target</th>
					<th>First Found</th>
					<th>Last Found</th>
					<th>Monitoring Status</th>
					<th>Update</th>
				</tr>
				<?php
					$db_query = "SELECT Id, Resource, ResourceType, RecordType, Target, EntryCreationTime, LastSuccessfulCheck, MonitoringEnabled FROM scan_target ORDER BY LastSuccessfulCheck DESC";
					$result = $conn->query($db_query);
					if ($result->num_rows > 0) {
						while($row = $result->fetch_assoc()) {
							$Id = $row["Id"];
							$Resource = $row["Resource"];
							$ResourceType = $row["ResourceType"];
							$RecordType = $row["RecordType"];
							$Target = $row["Target"];
							$EntryCreationTime = $row["EntryCreationTime"];
							$LastSuccessfulCheck = $row["LastSuccessfulCheck"];
							$MonitoringEnabled = $row["MonitoringEnabled"];
							
							if($MonitoringEnabled == "1") {
								$MonitoringStatus = "Enabled";
							} else {
								$MonitoringStatus = "Disabled";
							}
							echo "<tr>
								<td>$Resource</td>
								<td class=\"value-center\">$ResourceType</td>
								<td class=\"value-center\">$RecordType</td>
								<td>$Target</td>
								<td>$EntryCreationTime</td>
								<td>$LastSuccessfulCheck</td>
								<td class=\"value-center\">$MonitoringStatus</td>
								<td>	<form action=\"resource-update.php\" method=\"POST\">
										<input type=\"hidden\" name=\"resource-id\" value=\"$Id\" />
										<button class=\"value-center\" type=\"submit\" name=\"update_resource_action\">Update Resource</button>
									</form>
								</td>
							     </tr>";
						}
					} else {
						echo "0 results found!";
					}
				?>
			</table>
		</div>
	</div>
<body>
</html>

<?php
require './db/db-close.php' 
?>
