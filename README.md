#evroneCrop

This is a JavaScript crop plugin, based on canvas and written with CoffeeScript. Crop is done completely on client side, the result of crop is a base64 string, that you could easily send to server.

##Usage

    <script type="text/javascript" src="jquery.js"></script>
    <script type="text/javascript" src="evroneCrop.js"></script>
    <script type="text/javascript">
      $( function() {
        crop = $(element).evroneCrop();
      });
    </script>
    

You can set various options:

- **ratio**: pass a number > 0 to fix ratio, e.g 1 for square or 16/9 for a rectangle with ratio 16/9
- **setSelect**: you can set a selection right after initializing, passing coordinates, e.g {x: 0, y: 0, w: 100, h: 100} or "center". Don't pass "h" if you have ratio enabled, it will be ignored;
- **preview**: pass an IMG element to enable preview;


Everytime user changes something, original images data attribute is updated. You can easily get id by the following code:

    $jQuery.data(crop, 'evroneCrop')
    
