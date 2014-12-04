#!/bin/sh

while getopts k:c: option
do
  case "$option" in
    k)
      _KEY=$OPTARG ;;
    c)
      _CRT=$OPTARG ;;
    \?)
      echo "Usage: $0 [-k keyfile] [-c crtfile]"
      exit 1 ;;
  esac
done

if [ x$_KEY = "x" ] || [ x$_CRT = "x" ]
then
      echo "Usage: $0 [-k keyfile] [-c crtfile]"
exit 1
fi

_OPENSSL="/usr/bin/openssl"

keypub=`$_OPENSSL rsa -pubout -in $_KEY 2> /dev/null`
crtpub=`$_OPENSSL x509 -pubkey -in $_CRT -noout`


if [ "$keypub" = "$crtpub" ]
then
  echo "*** keypair match !! ***"
else
  echo "*** keypair mismatch !! ***"
fi

echo ""
echo $keypub
echo $crtpub
