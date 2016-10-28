Matlab encoding utilities
=========================

Matlab utilities to encode/decode a byte sequence. The package supports the
following features.

 * Base64 encode
 * GZIP compression
 * Image compression (image processing toolbox required)

The package internally uses JAVA functions. JAVA must be enabled in Matlab.

Usage
-----

### Base64 encode

Use `base64encode` and `base64decode` for encoding/decoding.

    >> x = 'foo bar';
    >> z = base64encode(x)

    z =

    Zm9vIGJhcg==

    >> x2 = char(base64decode(z))

    x2 =

    foo bar

### GZIP compression

Use `gzipcompress` and `gzipdecompress`.

    >> x = zeros(1,1000,'uint8');
    >> z = gzipcompress(x);
    >> whos
      Name      Size              Bytes  Class    Attributes

      x         1x1000             1000  uint8
      z         1x29                 29  uint8

    >> all(x == gzipdecompress(z))

    ans =

         1

### Image compression

Use `imencode` and `imdecode`. Both functions take image format as the second
argument. See `imformats` for the list of available formats on the platform.

    >> im = imread('cat.jpg');
    >> z = imencode(im, 'jpg');
    >> whos
      Name        Size                Bytes  Class    Attributes

      im        500x375x3            562500  uint8
      z           1x24653             24653  uint8
    >> im2 = imdecode(z, 'jpg');

License
-------

The code may be redistributed under the BSD clause 3 license.
