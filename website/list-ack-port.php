<?php
require './db/db-connect.php' 
?>
<html>
<head>
        <title>Portscan - Acknowledged Host/Port mapping</title>
        <link href="basic.css" rel="stylesheet" type="text/css">
</head>
<body>
	<div id="main">
		<h1>Acknowledged Host/Port mapping</h1>
		<div id="table-div">
			<table class="table">
				<tr>
					<th>Resource</th>
					<th>Target</th>
					<th>Scan Results</th>
				</tr>
				<?php
					// If we are calling to ourselves then check to see if there's anything to unacknowledge:
					if (isset($_POST['scan_result_id'])) {
						$scan_result_id = $_POST['scan_result_id'];
						$db_ack_query="UPDATE scan_results SET DateAccepted = NULL WHERE Id = $scan_result_id";
						$ack_result = $conn->query($db_ack_query);
						if (!$ack_result) {
							echo "<h1>Update Failed</h1>";
						} else {
							echo "<h3>Update Successful!</h3>";
						}
					}
			
					$db_query = "SELECT Id, Resource, Target FROM scan_target WHERE Id IN (SELECT DISTINCT ResourceId FROM scan_results)";
					$result = $conn->query($db_query);
					if ($result->num_rows > 0) {
						while($row = $result->fetch_assoc()) {
							$RId = $row["Id"];
							$Resource = $row["Resource"];
							$Target = $row["Target"];

							echo "<tr>
								<td>$Resource</td>
								<td>$Target</td>";
							
							// Now for each Resource, find the scan details:
							
							$db_subquery = "SELECT Id, Protocol, OpenPort, DateAccepted, MonitoringEnabled FROM scan_results WHERE ((ResourceId = $RId) AND (DateAccepted IS NOT NULL))";
							$result_subquery = $conn->query($db_subquery);
									echo "<td>
										<table class=\"sub-table\">";
							if ($result_subquery->num_rows > 0) {
								while($row_subquery = $result_subquery->fetch_assoc()) {
									$Id = $row_subquery["Id"];
									$Protocol = $row_subquery["Protocol"];
									$OpenPort = $row_subquery["OpenPort"];
									$DateAccepted = $row_subquery["DateAccepted"];

									echo "<tr class=\"sub-table-tr\">
										<td class=\"sub-table-td\">$Protocol $OpenPort is open (Last Auditted: $DateAccepted)</td>
										<td class=\"sub-table-td\"><form action=\"list-ack-port.php\" method=\"POST\"> <input type=\"hidden\" name=\"scan_result_id\" value=\"$Id\" /><button type=\"submit\" name=\"ack_scan_result\" class=\"sub-table-td-ack\">Un-Acknowledge</button></form></td>
									     </tr>";
								}
							}

							$db_subquery_2 = "SELECT COUNT(*) FROM scan_results WHERE (((ResourceId = $RId) AND ((DateAccepted IS NULL) OR (DateAccepted < date_sub(now(), interval 6 month)))))";
							$result_2 = $conn->query($db_subquery_2);
							if ($result_2->num_rows > 0) {
								while($row_2 = $result_2->fetch_assoc()) {
									$count = $row_2["COUNT(*)"];
									if ($count >= 1) {
										echo "<td class=\"sub-table-td\">Note: $count additional open ports needs to be acknowledged!</td>";
									}
								} 
							}
								echo "</table></td>";
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
