CC=mlton

all: heron

heron:
	cd src && mllex parse.lex
	cd src && mlyacc parse.grm
	${CC} -verbose 1 -output heron src/heron.mlb

archive-release: heron
	tar czvf heron-$(shell /bin/echo | ./heron | grep Heron | cut -d ' ' -f 2)-$(shell uname -m)-$(shell uname | tr A-Z a-z).tar.gz \
		heron \
		examples/basic \
		examples/gallery

clean:
	rm -f heron src/parse.grm.desc src/parse.grm.sig src/parse.grm.sml src/parse.lex.sml

# with_polyml:
#  	cd src && mllex parse.lex
#  	cd src && mlyacc parse.grm
#  	./contrib/sml-buildscripts/polybuild src/heron.mlb
#  	mv src/heron .
