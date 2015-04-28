AS = as31
PORT = /dev/ttyUSB0

SOURCE = knitter.asm
HEX = $(SOURCE:%.asm=%.hex)

.PHONY: main send clean

all: main
	@echo "Done!"

send: main
	echo D > $(PORT)
	cat $(HEX) > $(PORT)
	@echo "Done sending $(HEX) to $(PORT)"

main: $(HEX)
	@echo "Done Assembling $(HEX)"

$(HEX): $(SOURCE)
	$(AS) $<

clean:
	rm $(HEX)
	@echo "Done cleaning."
