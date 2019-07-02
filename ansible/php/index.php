<html>
<head>
  <title>GCP LB</title>
  <link rel="stylesheet" href="main.css">
</head>
<body>
<?php
   $hostname = shell_exec('hostname');
   echo "<h1>hostname: <a href=>".$hostname."</a><h1>";
   $internal_ip = shell_exec("ifconfig | sed '2!D' | awk '{print $2}'");
   echo "<h1>internal ip address: ".$internal_ip."<h1>";
?>
</body>
</html>