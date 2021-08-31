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

### Mac

Install the required binaries using [brew](https://brew.sh):

```
brew install imagemagick
brew install qrencode
brew install zbar
```
### Linux

Install the required binaries using your favorite package manager, e.g.:

```
pacman -S imagemagick
pacman -S qrencode
pacman -S zbar
```
If you get an error on Linux about the *"convert: attempt to perform an operation not allowed by the security policy <gs|pdf>"* add the following to */etc/ImageMagick-7/policy.xml*:

```
<policy domain="coder" rights="read | write" pattern="PDF" />
<policy domain="coder" rights="read | write" pattern="gs" />
```

## Installation

Clone the repo or simply and make it executable:

```
 git clone https://github.com/dtonon/papiro.git
 cd papiro
 chmod +x papiro.sh
 ./papiro.sh -h
 ```
 You can even [download/copy](https://raw.githubusercontent.com/dtonon/papiro/master/papiro.sh) the single `papiro.sh` file, that's all!

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
These are all the options:

```
-a	Anonymous mode, don't annotate the original filename for increased privacy
-o	Specify the output filename
-z	Debug mode, create a debug/ dir with the temp images
```

## Example

In the examples/ dir you can find a [nice 60KB cat's photo](examples/cat.jpg) and the [4 pages qrcodes-pdf-papiro](examples/qrcodes-cat.jpg.pdf) generated with the following command:

```
./papiro.sh -c cat.jpg
```
This is a preview of the generated pdf (top cropped A4 page):

![Output pdf example](docs/output-example.png)

## Security & encryption

Remember that a qrcode slightly obfuscates your data but it does not protect them in any way; you may need to encrypt them before using Papiro, also to avoid the printer's attack surface. For that you can use gpg, a password protected zip or the built-in "new vim encrypted file":

```
./papiro.sh -x
```