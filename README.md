# Papiro

**Papiro is a simple script that encodes and decodes a file to/from qrcode(s).**
The qrcodes are saved in a single pdf, ready to print; the rebuild process is done on a group of qrcodes' photos.

Papiro is useful to save files in a non digital fashion for backup and portability pourposes using a printer.
You can export secrets, cretentials, 2FA backup codes, crypto seeds and more (binary files are supported too).

_Papiro_ is the italian word for "papyrus" :page_with_curl:

## Requirements

Papiro needs these binaries:

- `convert`
- `qrencode`
- `zbarimg`
- `montage`

## Installation

```
 git clone https://github.com/dtonon/papiro.git
 cd papiro
 chmod +x papiro.sh
 ./papiro.sh -h
 ```

 ## Usage
```
# Encode a file to qrcodes in single pdf
./papiro.sh -c memo.txt

# Interactively create a new vim encrypted file and then process it
./papiro.sh -x

# Encode a file to qrcodes keeping the filename secret
./papiro.sh -c cat.jpg -a

# Decode a group of images to rebuild a file
./papiro.sh -r photos/ -o data.json
```

## Example

In the examples/ dir you can find a [nice cat's photo source](examples/cat.jpg) and the [6 pages qrcodes-pdf-papiro](examples/qrcodes-cat.jpg.pdf) generated with the following command:

```
./papiro.sh -c cat.jpg
```
This is a preview of the generated pdf (top cropped A4 page):

![Output pdf example](docs/output-example.png)

## Security

Remember that a qrcode slightly obfuscates your data but it does not protect them in any way; you may need to encrypt them before using Papiro, also to avoid the printer's attack surface. For that you can use gpg, a password protected zip or the built-in "new vim encrypted file":

```
./papiro.sh -x
```