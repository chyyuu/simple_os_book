#README

## setup
in ubuntu 16.04 x86-64 or later
```
## install texlive
sudo apt install texlive-full
## install chinese fonts
wget https://github.com/chyyuu/fonts/archive/master.zip
unzip -x fonts-master.zip
wget https://github.com/chyyuu/msfonts/archive/master.zip
unzip -x msfonts-master.zip
sudo mv fonts-master /usr/share/fonts/
sudo mv msfonts-master /usr/share/fonts/
sudo apt install fonts-wqy-microhei fonts-wqy-zenhei ttf-wqy-microhei ttf-wqy-zenhei xfonts-wqy
```

## build doc
```
make
```

then you will get sosbook.pdf

