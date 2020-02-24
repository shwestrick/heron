CC=mpl

all:
	cd src && mllex parse.lex
	cd src && mlyacc parse.grm
	sed 's/_COMPILER_CMD_/${CC}/g' src/Toplevel.sml > src/_Toplevel.sml
	${CC} -verbose 1 -output heron src/heron.mlb

binary-release: all
	tar czvf heron-$(shell /bin/echo | ./heron | grep Heron | cut -d ' ' -f 2)-$(shell uname -m)-$(shell uname | tr A-Z a-z).tar.gz \
		heron \
		lib \
		examples/HandWatch* \
		examples/Radiotherapy.tesl \
		examples/PowerWindow.tesl \
		examples/basic \
		examples/reference-gallery \
		examples/aviation

# Tests are done with TESL files and expected outputs available in ./regression
test:
	rm -f regression/*.out regression/_results.log
	chmod +x regression/check.sh
	for var in $(shell ls regression/*.tesl) ; do regression/check.sh $${var} ; done | tee regression/_results.log
	rm -f regression/*.sorted
	if (! (grep "FAIL" regression/_results.log >/dev/null)) ; then echo "\e[1m\e[32mCongrats! ALL REGRESSION TESTS PASSED.\e[0m" ; else echo "\e[1m\e[31mSorry! SOME REGRESSION TESTS HAVE FAILED.\e[0m" ; exit 1 ; fi

clean:
	rm -f regression/*.out regression/_results.log
	rm -f src/parse.grm.desc src/parse.grm.sig src/parse.grm.sml src/parse.lex.sml src/_Toplevel.sml

# with_polyml:
#  	cd src && mllex parse.lex
#  	cd src && mlyacc parse.grm
#  	./contrib/sml-buildscripts/polybuild src/heron.mlb
#  	mv src/heron .
