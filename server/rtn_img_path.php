<?php
    if ($argc > 1) 
    {
        $file_name = $argv[1];
        // echo $file_name;
    }
    $dir = $file_name;
    $filelist = glob($dir.'*');
    $trimmedFilelist = array_map(function($file) use ($dir) 
    {
        return str_replace($dir, '', $file);
    }, $filelist);
    echo json_encode($trimmedFilelist);
?>