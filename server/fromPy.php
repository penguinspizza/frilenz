<?php
    if ($argc > 1) 
    {
        $file_name = $argv[1];
        if (!file_exists($file_name)) 
        {
            if (mkdir($file_name)) 
            {
                // echo "フォルダが作成されました。";
            }
            else 
            {
                // echo "フォルダの作成中にエラーが発生しました。";
            }
        }
        else 
        {
            // echo "指定された名前のフォルダは既に存在します。";
        }
        echo $file_name;
    }
    else
    {
        // echo "No /input received.";
    }
?>