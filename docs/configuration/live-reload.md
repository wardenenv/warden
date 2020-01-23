## Configuring LiveReload on Magento 2

TODO Add documentation on adding the following into the `env.php` file including usage information:

```
'design' => [
    'footer' => [
        'absolute_footer' => '
            <script id="__lr_script__">//<![CDATA[
                document.write("<script src=\'/livereload.js?port=443\'/>");
            //]]></script>
        '
    ]
]
```
