# Native build ON THE BOARD against the running kernel's headers
# (sudo apt install linux-headers-$(uname -r)).
# Host cross-builds go through ../../../scripts/build-app.sh <app> kernel.
KDIR ?= /lib/modules/$(shell uname -r)/build

all:
	$(MAKE) -C $(KDIR) M=$(CURDIR) modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR) clean
