#!/bin/sh
# $LynxId: install-cfg.sh,v 1.5 2021/01/07 00:31:20 tom Exp $
# install lynx.cfg, ensuring the old config-file is saved to a unique file,
# and prepending customizations to the newly-installed file.
#
# $1 = install program
# $2 = file to install
# $3 = where to install it
PRG="$1"
SRC=$2
DST=$3

LANG=C;		export LANG
LC_ALL=C;	export LC_ALL
LC_CTYPE=C;	export LC_CTYPE
LANGUAGE=C;	export LANGUAGE

if test -f "$DST" ; then
	echo "** checking if you have customized $DST"
	OLD=lynx-cfg.old
	NEW=lynx-cfg.new
	TST=lynx-cfg.tst
	TMP=lynx-cfg.tmp
	trap 'rm -f $OLD $NEW $TST $TMP; exit 9' INT QUIT TERM HUP
	rm -f $OLD $NEW $TST $TMP

	# avoid propagating obsolete URLs into new installs
	{
		echo lynx.isc.org;
		echo lynx.browser.org;
		echo www.trill-home.com;
		echo www.cc.ukans.edu;
		echo www.ukans.edu;
		echo www.slcc.edu;
		echo sol.slcc.edu;
	}>$TMP

	# Make a list of the settings which are in the original lynx.cfg
	# Do not keep the user's HELPFILE setting since we modify that in
	# a different makefile rule.
	${EGREP-egrep} '^[ 	]*[A-Za-z]' "$SRC" |sed -e 's/^[ 	]*HELPFILE:.*/HELPFILE:/' >>$TMP
	${EGREP-egrep} '^[ 	]*[A-Za-z]' "$SRC" |${FGREP-fgrep} -v -f $TMP >$OLD
	${EGREP-egrep} '^[ 	]*[A-Za-z]' "$DST" |${FGREP-fgrep} -v -f $TMP >$TST

	if test -s $TST ; then
		cat >$TMP <<EOF
## The following lines were saved from your previous configuration.

EOF
		cat "$TST" >>$TMP
		cat "$SRC" >$NEW
		cat "$TMP" >>$NEW

		# See if we have saved this information before (ignoring the
		# HELPFILE line).
		if cmp -s $NEW $OLD
		then
			echo "... installed $DST would not be changed"
		else
			NUM=1
			while test -f "${DST}-${NUM}"
			do
				if cmp -s "$NEW" "${DST}-${NUM}"
				then
					break
				fi
				NUM=`expr "$NUM" + 1`
			done
			if test ! -f "${DST}-${NUM}"
			then
				echo "... saving old config as ${DST}-${NUM}"
				mv "$DST" "${DST}-${NUM}" || exit 1
			fi
			echo "** installing $NEW as $DST"
			eval "$PRG" "$NEW" "$DST" || exit 1
		fi
	else
		echo "... no customizations found"
		echo "** installing $SRC as $DST"
		eval "$PRG" "$SRC" "$DST" || exit 1
	fi
	rm -f "$SKIP" "$OLD" "$NEW" "$TST" "$TMP"
elif cmp -s "$SRC" "$DST"
then
	echo "... installed $DST would not be changed"
else
	echo "** installing $SRC as $DST"
	eval "$PRG" "$SRC" "$DST" || exit 1
fi
