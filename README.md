# Papiro

**Papiro it is a simple script that encodes and decodes a file to/from qrcode(s).**
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
 papiro.sh -h
 ```

 ## Usage
```
# Encode a file to qrcodes in single pdf
./papiro.sh -c memo.txt

# Encode a file to qrcodes keeping the filename secret
./papiro.sh -c thisphoto.jpg -a

# Decode a group of images to rebuild a file
./papiro.sh -r photos/ -o data.json
```

## Security

Remember that a qrcode slightly obfuscates your data but it does not protect them in any way; you may need to encrypt them before using Papiro, also to avoid the printer's attack surface.