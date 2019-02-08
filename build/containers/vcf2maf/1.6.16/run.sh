#!/bin/sh

case $1 in
    vcf2vcf.pl) shift; exec perl /usr/bin/vcf2maf/vcf2vcf.pl "$@" ;;
    vcf2maf.pl) shift; exec perl /usr/bin/vcf2maf/vcf2maf.pl "$@" ;;
    maf2maf.pl) shift; exec perl /usr/bin/vcf2maf/maf2maf.pl "$@" ;;
    maf2vcf.pl) shift; exec perl /usr/bin/vcf2maf/maf2vcf.pl "$@" ;;
    *) echo "vcf2vcf.pl, vcf2maf.pl, maf2maf.pl, or maf2vcf.pl?"; exit 1 ;;
esac
