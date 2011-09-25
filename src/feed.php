<?php
header("Content-type: text/xml"); 
echo "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>";
echo "<videos>";
if ($handle = opendir('.')) {
    while (false !== ($file = readdir($handle))) {
        if ($file != "." && $file != "..") {
            echo "<video file=\"$file\" ></video>";
        }
    }
    closedir($handle);
}
echo "</videos>";
?>