# mod_barcode

An unfinished (but usable) module for [Zotonic](https://github.com/zotonic/zotonic) to generate barcodes or QR Codes using [postscriptbarcode](https://github.com/terryburton/postscriptbarcode)

## TODO

1. Content data of generated barcode to be configurable by the user. At the moment it is hardcoded in mod_barcode.erl. For instance, QR Codes generates a link to the page http://hostname/page/id

## Requires

1. ImageMagick, **convert** program

2. Using the **monolithic build of barcode.ps** from the amazing [postscriptbarcode](https://github.com/terryburton/postscriptbarcode)

3. Set the **path to barcode.ps** in Zotonic admin, System->Config under the setting named `barcode_ps_dir`

## mod_barcode settings

A configuration named `barcode_convert_params` under System->Config sets the parameters to the convert command.


## How to use

A relation named `autocreate_barcode_type` is created by mod_barcode.

Edit a Category and add relation to a barcode type under "Barcode".

Two barcode types are automatically created by mod_barcode. Choose QR Code or Code 93, you can add more Barcode types by creating resources in the category "Barcode Type".

When a resource is created under a category that has a barcode relation, a Barcode is created and hooked into media under that resource.
