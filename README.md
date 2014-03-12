# mod_barcode

An unfinished (but usable) module for [Zotonic](https://github.com/zotonic/zotonic) to generate barcodes or QR Codes using [postscriptbarcode](https://github.com/terryburton/postscriptbarcode)

## TODO

1. see what I can do with dispatch rules for barcode templates.

## Requires

1. ImageMagick, **convert** program

2. Using the **monolithic build of barcode.ps** from the amazing [postscriptbarcode](https://github.com/terryburton/postscriptbarcode)

3. Set the **path to barcode.ps** in Zotonic admin, System->Config under the setting named `barcode_ps_dir`

## mod_barcode settings

A configuration named `barcode_convert_params` under System->Config sets the parameters to the convert command.


## How to use

A relation named `autocreate_barcode_type` is created by mod_barcode.

Edit a Category and add relation to a barcode type under "Barcode".

Some barcode types are automatically created by mod_barcode. You can add more Barcode types by creating resources in the category "Barcode Type", the unique name of that resource is the same as the function in postscriptbarcode.

When a resource is created under a category that has a barcode relation, a Barcode is automatically created and hooked into media under that resource.

The content of the barcode is by standard the Id of the resource that the barcode is created with, except for QR Code and DataMatrix, where the content is the link to the page for that resource. The barcode content can be edited by creating a template, for instance 'barcode.qrcode.tpl' looks like this by standard

    http://{{m.site.hostname}}/page/{{id}}

This can be changed to anything you want by creating the file 'barcode.qrcode.tpl' under your templates/ directory.