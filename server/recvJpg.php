<?php
    if ($argc > 1) 
    {
        $file_name = $argv[1];
        // echo $file_name;
    }
    // else
    // {
    //     echo "No input received.";
    // }
    $hash = $file_name;
        $file_path = "./" .$hash. "/";
        $file = $_FILES['uploadfile'];
        move_uploaded_file($_FILES['uploadfile']['tmp_name'], $file_path.date('YmdHis').'.jpg');
        echo 'OK';
?>
