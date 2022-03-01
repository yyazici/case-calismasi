#!/bin/bash

#Master node üzerine git clone olduğu varsayiliyor.

./master-install.sh

#Worker node sifresiz gecis oldugu varsayiliyor.

scp worker-install.sh server-1:/root/

ssh server-1 /root/worker-install.sh


#Postinstall adimlari
./post-install.sh