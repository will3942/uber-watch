uber-watch
==========

The watchapp for the Uber Private API &amp; iOS app.  

Compiling the iOS App
==========

1. Clone the repository locally, and add the frameworks PebbleKit.framework and PebbleVendor.framework located in the Pebble SDK (https://account.getpebble.com/sdk_releases).
2. Build and run on the device.

Compiling the Pebble App
==========

1. Clone the repository locally
2. Link the Pebble SDK compiling files using the create_pebble_project.py tool with the --symlink-only  in the Pebble SDK tools folder 
3. `./waf configure`
4. `./waf build`
5. Transfer the .pbw from the build folder to your phone using `python -m SimpleHTTPServer`
6. Install the Pebble app and run on the Pebble.
