# mod_barcode

An unfinished (but usable) module for [Zotonic](https://github.com/zotonic/zotonic) to generate barcodes or QR Codes using [postscriptbarcode](https://github.com/terryburton/postscriptbarcode)

## TODO

1. A tool to manually create barcodes.
2. See what I can do with dispatch rules for barcode templates.

## Requires

1. ImageMagick, **convert** program

2. Using the **monolithic build of barcode.ps** from the amazing [postscriptbarcode](https://github.com/terryburton/postscriptbarcode)

3. Set the **path to barcode.ps** in Zotonic admin, System->Config under the setting named `barcode_ps_dir`

## mod_barcode settings

A configuration named `barcode_convert_params` under System->Config sets the parameters to the convert command.


## How to use

### Autocreate Barcodes

When a resource is created under a category (for example Text category), a Barcode is automatically created and hooked into media under that resource.

But for this to work, you must first edit a Category and add a relation to a barcode type under "Barcode".

A predicate named `autocreate_barcode_type` is created by mod_barcode.

You can add more Barcode types manually by creating resources in the category "Barcode Type", the unique name of that resource is the same as the function in postscriptbarcode.

The content of the barcode is by standard the Id of the resource that the barcode is created with, except for QR Code and DataMatrix, where the content is the link to the page for that resource. The barcode content can be edited by creating a template, for instance 'barcode.qrcode.tpl' looks like this by standard

    http://{{m.site.hostname}}/page/{{id}}

This can be changed to anything you want by creating the file 'barcode.qrcode.tpl' under your templates/ directory.