echi-binary

# Windows installation

1. Install Ruby 2.2.1

  Download and run [Ruby Installer for Windows](http://rubyinstaller.org/downloads/)

  On third step, check:
  * "Add Ruby executable to your PATH"
  * "Assosicate .rb and .rbw files with this Ryby installation"

2. Run Windows console and check ruby version.
  ```
  > ruby -v
  ruby 2.1.1p85...
  ```

3. Install 'bindata' gem. Run in windows console:
  ```
  > gem install bindata
  ```

4. Now you can use converter script
  ```
  > ruby converter.rb
  Usage: ruby converter.rb <direction[to_text|to_bin]> "<delimiter>" <input_file> <output_file>
  ```

  Examples:

  Convert from binary to text
  ```
  > ruby converter.rb to_text "," chr1412.771.090712 chr1412.771.090712.csv
  Binary file chr1412.771.090712 successfully converted to text chr1412.771.090712.csv
  ```
  Convert from text to binary
  ```
  > ruby converter.rb to_bin "," chr1412.771.090712.csv new_chr1412.771.090712
  Text file chr1412.771.090712 successfully converted to binary chr1412.771.090712.csv
  ```



