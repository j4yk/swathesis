#!/bin/sh

PROGRAM=`echo $0 | sed 's%.*/%%'`
PROGDIR="$(cd `dirname $0`; echo $PWD)"

if [ ! -z "$ZSH_VERSION" ]; then
  setopt shwordsplit
fi
ECHON="/usr/bin/printf %b"
ECHO="/usr/bin/printf %b\\n"

THE_TDS=swathesis.tds.zip

KPSEWHICH="${KPSEWHICH:-kpsewhich}"
KPATHSEAVERSION=$($KPSEWHICH --version | head -1 | cut -d" " -f3 | cut -d. -f1)


__usage() {
  printf "Usage: $PROGRAM [OPTIONS]

Install swathesis.

OPTIONS
  --home        install to TEXMFHOME  ($($KPSEWHICH -var-value TEXMFHOME )) (* recommended)
  --local       install to TEXMFLOCAL ($($KPSEWHICH -var-value TEXMFLOCAL))
  --tex         install to TEXMFDIST  ($($KPSEWHICH -var-value TEXMFDIST )) (not recommended)

  --bin-home    install the \`swth' script to $BIN_DEFAULT (*)
  --bin-local   install the \`swth' script to /usr/local/bin
  --bin-tex     install the \`swth' script to $(dirname $KPSEWHICH)
  --bin-sys     install the \`swth' script to /usr/bin (not recommended)

  --no-req      do not atempt to install required packages
  --no-bin      do not link the \`swth' script
  --no-logos    do not try to find Logos.zip (Uni Potsdam/HPI logos)

  --logos=FILE  use Logos.zip from FILE

  --update      force update; rebuild TDS package prior to installation
  --verbose     turn verbose output on
  --help        output this help and exit

* = default

"
}

__find_bin() {
  if [ -d "${HOME}/.bin" ] && $ECHO $PATH | tr : \n | grep -q "${HOME}/.bin"; then
    $ECHO "${HOME}/.bin"
  else
    $ECHO "${HOME}/bin"
  fi
}


__check_dir() {
  DIR="$1"
  if [ ! -d "$DIR" ]; then
    printf "\n$DIR does not exist, create it? [YES|no] "
    read ANS
    case "$ANS" in
      [Nn][Oo]?) : ;;
      *) mkdir -p $DIR ;;
    esac
  fi

  if [ ! -w "$DIR" ]; then
    printf "\n$DIR is not writable, continue as root (sudo)? [NO|yes] "
    read ANS
    case "$ANS" in
      [Yy][Ee][Ss]) E=sudo ;;
      *) exit 2 ;;
    esac
  fi
}

__verbose_info() {
  printf "
Information
-----------
DEST=         $DEST
DEST_DIR=     $DEST_DIR
DEST_DEFAULT= $DEST_DEFAULT
BIN=          $BIN
BIN_DEFAULT=  $BIN_DEFAULT
"
if [ "$NOLOGO" -eq 1 ]; then
  $ECHON "not "
fi
$ECHO "deploying logos (from $LOGO)"

if [ ! -z "$E" ]; then
  $ECHO "using $E as sudo";
fi

if [ "$REQUIREMENTS" -eq 0 ]; then
  $ECHON "not "
fi
$ECHO "installing requirements"

if [ "$NOBIN" -eq 1 ]; then
  printf "not "
fi
$ECHO "installing binary"

if [ "$NEEDMKTEXLSR" -eq 0 ]; then
   $ECHON "not "
fi
$ECHO "rebuilding tex file db"
$ECHO "-----------"

}

VERBOSE=0
DEST=
DEST_DEFAULT="$($KPSEWHICH -var-value TEXMFHOME)"
REQUIREMENTS=1
BIN=
BIN_DEFAULT="$(__find_bin)"
NOBIN=0
NEEDMKTEXLSR=0
UPDATE=0
E=
NOLOGO=0
LOGO=Logos.zip

while test $# -gt 0; do
  case "x$1" in
    x--help|x-h)
      __usage
      exit 0
      ;;
    x--verbose|x-v) VERBOSE=1                                  ;;
    x--home)        DEST=TEXMFHOME                             ;;
    x--local)       DEST=TEXMFLOCAL                            ;;
    x--tex)         DEST=TEXMFDIST                             ;;
    x--bin-home)    BIN="$BIN_DEFAULT"                         ;;
    x--bin-local)   BIN=/usr/local/bin                         ;;
    x--bin-tex)     BIN="$(dirname $KPSEWHICH)"                ;;
    x--bin-tex)     BIN=/usr/bin                               ;;
    x--no-req)      REQUIREMENTS=0                             ;;
    x--no-bin)      NOBIN=1                                    ;;
    x--update)      UPDATE=1                                   ;;
    x--no-logos)    NOLOGO=1                                   ;;
    x--logo=*)      LOGO="$($ECHON $1 | sed -e 's%--logo=%%')" ;;
    *)
      $ECHO "$PROGRAM: unknown option \`$1', try --help if you need it." >&2
      exit 1
      ;;
  esac
  shift
done


$ECHO "Installing swathesis"
$ECHO "===================="
$ECHO ""
$ECHO ""
if [ "$VERBOSE" -eq 1 ]; then
  __verbose_info
fi


if [ -z "$DEST" ]; then
  printf "
Where shall I install swathesis to,
  install to TEXMFHOME  ($($KPSEWHICH -var-value TEXMFHOME )) (recommended)
  install to TEXMFLOCAL ($($KPSEWHICH -var-value TEXMFLOCAL))
  install to TEXMFDIST  ($($KPSEWHICH -var-value TEXMFDIST )) (not recommended)
  or somewhere else?
[TEXMFHOME] "
  read DEST
  if [ -z "$DEST" ]; then DEST=TEXMFHOME; fi
fi
case "$DEST" in
  TEXMF*) DEST_DIR=$($KPSEWHICH -var-value "$DEST") ;;
  *)      DEST_DIR="$DIR"                             ;;
esac

__check_dir "$DEST_DIR"
OLDKPATHSEA=$(if [ "$KPATHSEAVERSION" -lt 6 ]; then $ECHO 1; else $ECHO 0; fi)
if [ "$DEST" = TEXMFHOME ]; then
  if [ -f "$DEST_DIR"/ls-R -o "$OLDKPATHSEA" -eq 1 ]; then
    NEEDMKTEXLSR=1
  else
    NEEDMKTEXLSR=0
  fi
else
  NEEDMKTEXLSR=1
fi


if [ "$NOBIN" -eq 0 ]; then
  if [ -z "$BIN" ]; then
    printf "
Where shall I install the \`swth' script to?
  home  install to $BIN_DEFAULT
  local install to /usr/local/bin
  tex   install to $(dirname $KPSEWHICH)
  sys   install to /usr/bin (not recommended)
  or somewhere else?
[home] "
    read ANS
    if [ -z "$ANS" ]; then ANS="$BIN_DEFAULT"; fi
    case "$ANS" in
      home)  BIN="$BIN_DEFAULT"          ;;
      local) BIN=/usr/local/bin          ;;
      tex)   BIN="$(dirname $KPSEWHICH)" ;;
      sys)   BIN=/usr/bin                ;;
      *)     BIN="$ANS"                  ;;
    esac
  fi
  __check_dir "$BIN"
  if [ -f "$BIN"/swth -o -L "$BIN"/swth ]; then
    printf "\`swth' is already present in $BIN.
Shall I ignore that (no linking) or overwrite that file?
[IGNORE|overwrite|abort] "
    read ANS
    case "$ANS" in
      o|over*)  rm "$BIN"/swth ;;
      a|abort*) exit 128       ;;
      *)        NOBIN=1     ;;
    esac
  fi
fi

if [ "$NOLOGO" -eq 0 ]; then
  if [ \! -f "$LOGO" ]; then
    printf "Do you have a Logos.zip with Uni Potsdam/HPI logos?
If you have, place it in this directory
    $PWD
and say \`yes' (or the filename), if not, or you do not 
know what this means, say \`no'.

[yes|filename|NO] "
    read ANS
    if [ -z "$ANS" ]; then ANS="no"; fi
    case "$ANS" in
      no|NO)  NOLOGO=1                    ;;
      yes)    if [ \! -f "$LOGO" ]; then
                $ECHO "Cannot find $LOGO, although requested to use it, don't know what to do, aborting."
                exit 1
              fi                          ;;
      *)      LOGO="$ANS"                 ;;
    esac
  fi
fi


if [ "$VERBOSE" -eq 1 ]; then
  __verbose_info
fi


if [ "$REQUIREMENTS" -eq 1 ]; then
  $ECHO "> Installing Requirements"
  _PREQ="$PWD"; cd "$PROGDIR"/requirements
  TDS_DEST="$DEST_DIR" ./get_requirements.sh
  cd "$_PREQ"
fi

if [ \( ! -f "$PROGDIR/$THE_TDS" \) -o \( "$UPDATE" -eq 1 \) ]; then
  $ECHO "> (re)Building TDS package"
  _PTDS="$PWD"; cd "$PROGDIR"
  rm -f $THE_TDS
  if ./tdsify.sh; then
      cd "$_PTDS"
  else 
      cd "$_PTDS"
      exit 1
  fi
fi



if type unzip >/dev/null 2>/dev/null; then
    :
else
    $ECHO ">> \`unzip' not found, please install."
    exit 1
fi


$ECHO "> Deploying swathesis into $DEST_DIR"
_P=$PWD
cd "$DEST_DIR"

$E unzip -u -o -q "$PROGDIR/$THE_TDS"
if [ $NOLOGO -ne 1 ]; then
  cd tex/latex/swathesis
  $ECHO "> Deploying logos into $DEST_DIR/tex/latex/swathesis"
  $E unzip -u -o -q "$PROGDIR/$LOGO"
fi

cd "$_P"


if [ "$NEEDMKTEXLSR" -eq 1 ]; then
  $ECHO "> Rebuilding TeX file database"
  $E mktexlsr "$DEST_DIR"
fi

if [ "$NOBIN" -eq 0 ]; then
  $ECHO "> Linking \`swth' into $BIN"
  $E ln -s "$DEST_DIR"/scripts/swathesis/swth.sh "$BIN"/swth
  if $ECHO $PATH | tr ':' '\n' | grep -q "$BIN"; then
    :
  else
    $ECHO "

CAUTION: '$BIN' is not on your \$PATH. You
         might want to add it or re-start your shell,
         it might then get added automatically
         (PATH is $PATH)

"
  fi
fi

$ECHO "Done"
