#!/bin/bash

cd "$(dirname $0)"

# PARAMETERS

# number of bits in the RSA cert
# use something proper or even ECC
# this is just an example
BITS=1024

INSECURE=-nodes

# PARAMETERS END

# let's ensure we have plenty entropy so we don't get stuck
#
# WARNING: this is just used to speed up the demo
#          do NOT do this in production!
rngd -r /dev/urandom &

# cleanup time
rm -rf workdir
mkdir workdir
cd workdir

# destination of all published roots
# and their attestation signatures
mkdir published

# destination of our two
# attestation organizations
mkdir attester1 attester2

# destination for our four
# organization roots
mkdir root1 root2 root3 root4

function keypath() {
	SUBJ=$1

	echo "$SUBJ/$SUBJ.key.pem"
}

function certpath() {
	SUBJ=$1

	echo "$SUBJ/$SUBJ.cert.pem"
}

function pubpath() {
	SUBJ=$1

	echo "$SUBJ/$SUBJ.pub.pem"
}

function publishedcertpath() {
	SUBJ=$1

	echo "published/$SUBJ.cert.pem"
}

function signaturepath() {
	ATTESTER=$1
	TARGET=$2

	echo "published/$TARGET.cert.pem.$ATTESTER.sha256.sign"
}

function mkcert() {
	SUBJ=$1

	echo "CREATING CERTIFICATE FOR $SUBJ"

	# create private key and self-signed cert
	openssl req -x509 $INSECURE -newkey rsa:$BITS -keyout $(keypath $SUBJ) -out $(certpath $SUBJ) -days 5 -subj "/CN=$SUBJ"
	# export public key
	openssl rsa -in $(keypath $SUBJ) -pubout -out $(pubpath $SUBJ)
}

function publish() {
	SUBJ=$1

	echo "PUBLISHING CERTIFICATE OF $SUBJ"

	cp -v $(certpath $SUBJ) $(publishedcertpath $SUBJ)
}


function attest() {
	ATTESTER=$1
	TARGET=$2

	echo "ATTESTING $TARGET BY $ATTESTER"	

	openssl dgst -sha256 -sign $(keypath $ATTESTER) -out $(signaturepath $ATTESTER $TARGET) $(publishedcertpath $TARGET)
}

function tryverify() {
	ATTESTER=$1
	TARGET=$2
	SIGNATURE=$3

	echo -n "VERIFING SIGNATURE $SIGNATURE by $ATTESTER FOR $TARGET..."
	openssl dgst -sha256 -verify $(pubpath $ATTESTER) -signature $SIGNATURE $(publishedcertpath $TARGET)
}

function list_attested() {
	ATTESTER=$1

	echo "LISTING CERTIFICATES ATTESTED BY $ATTESTER "

	for signaturefile in $(find -iname "*.$ATTESTER.sha256.sign"); do
		echo "Testing signature $signaturefile for all certs..."
		tryverify $ATTESTER root1 $signaturefile
		tryverify $ATTESTER root2 $signaturefile
		tryverify $ATTESTER root3 $signaturefile
		tryverify $ATTESTER root4 $signaturefile
	done
}

echo -e "\n\n\n"

mkcert attester1
mkcert attester2
mkcert root1
mkcert root2
mkcert root3
mkcert root4

echo -e "\n\n\n"

publish root1
publish root2
publish root3
publish root4

echo -e "\n\n\n"

attest attester1 root1
attest attester1 root2
attest attester2 root2
attest attester2 root3

echo -e "\n\n\n"

list_attested attester1

echo -e "\n\n\n"

list_attested attester2
