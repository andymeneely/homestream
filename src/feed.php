<?php
header("Content-type: text/xml"); 
echo "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>";
echo "<videos>";
if ($handle = opendir('.')) {
    while (false !== ($file = readdir($handle))) {
        if ($file != "." && $file != ".." && endsWith($file,".m4v")) {
            echo "<video file=\"$file\" ></video>";
        }
    }
    closedir($handle);
}
echo "</videos>";

function endsWith($haystack, $needle) {
    $start  = strlen($needle) * -1; //negative
    return (substr($haystack, $start) === $needle);
}

?>