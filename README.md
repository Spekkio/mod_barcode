# mod_barcode

An incomplete module for Zotonic to generate barcodes or QR Codes using https://github.com/terryburton/postscriptbarcode

## TODO

1. Content data of generated barcode to be configurable by the user. At the moment it is hardcoded in mod_barcode.erl.

## Requires

ImageMagick, convert program

Using the monolithic build of barcode.ps from the amazing postscriptbarcode
https://github.com/terryburton/postscriptbarcode

Or here
https://code.google.com/p/postscriptbarcode/

Download and set the required path to barcode.ps in Zotonic admin, System->Config under the setting named barcode_ps_dir

## mod_barcode settings

A configuration named barcode_convert_params under System->Config sets the parameters to the convert command.


## Using

A relation named autocreate_barcode_type is created, edit a Category and add relation under "Barcode". Choose QR Code or Code 93, you can add more Barcode types. When a resource is created with that Category, a Barcode is created and hooked into media under that resource.