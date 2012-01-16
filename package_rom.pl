#!/usr/bin/perl

###############################################################################
#
#Takes an otapackage zip and creates a signed update zip with the following:
#    -Removed recovery
#    -Added superuser files
#    -Added busybox and install script
#    -Custom updater-script
#    -Signed zip
#
#Author:  Jon Richards
#Email:  jon@jonrichards.net
#
###############################################################################

use strict;
use Archive::Extract;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Copy;
use File::Path;

###############################################################################
#Variables
###############################################################################
my $base_dir = "/home/jon/code/aosp/package_rom";
my $otapackage = "/home/jon/code/aosp/ics_custom/out/target/product/crespo/full_crespo-ota-eng.jon.zip";
my $update = $base_dir . "/update.zip";
my $signed = $base_dir . "/update-signed.zip";
my $busybox = $base_dir . "/files/busybox";
my $su = $base_dir . "/files/su";
my $superuser = $base_dir . "/files/Superuser.apk";
my $updater_script = $base_dir . "/scripts/updater-script";
my $install_busybox = $base_dir . "/scripts/installbusybox";
my $testsign = $base_dir . "/testsign/testsign.jar";
###############################################################################


###############################################################################
#Cleanup previous files
###############################################################################
#Delete old temp directory
if (-d $base_dir . "/temp") {
    rmtree([$base_dir . "/temp"], 0, 1) or die "Could not delete temp directory";
}
#Delete old update.zip
if(-e $update) {
    unlink($update);
}
###############################################################################


###############################################################################
#Unzip and prepare
###############################################################################
#Copy otapackage zip
copy($otapackage, $update) or die "Copy failed: $!";

#Create new temp directory
mkdir($base_dir . "/temp");

#Extract update.zip to temp directory
my $ae = Archive::Extract->new(archive => $update);
my $ok = $ae->extract(to => $base_dir . "/temp");

#Delete update.zip
unlink($update);

#Delete the recovery folder
rmtree([$base_dir . "/temp/recovery"], 0, 1) or die "Fail";
#Delete updater-script
unlink($base_dir . "/temp/META-INF/com/google/android/updater-script");
#Delete signing files
unlink($base_dir . "/temp/META-INF/CERT.RSA");
unlink($base_dir . "/temp/META-INF/CERT.SF");
unlink($base_dir . "/temp/META-INF/MANIFEST.MF");
###############################################################################


###############################################################################
#Copy files
###############################################################################
#Copy busybox
copy($busybox, $base_dir . "/temp/system/xbin") or die "Copy failed: $!";

#Copy superuser files
copy($superuser, $base_dir . "/temp/system/app") or die "Copy failed: $!";
copy($su, $base_dir . "/temp/system/bin") or die "Copy failed: $!";

#Copy updater script
copy($updater_script, $base_dir . "/temp/META-INF/com/google/android/") or die "Copy failed: $!";

#Copy installbusybox script
copy($install_busybox, $base_dir . "/temp");
###############################################################################


###############################################################################
#Create new update.zip
###############################################################################
my $zip = Archive::Zip->new();
$zip->addTree($base_dir . "/temp/", "");
unless($zip->writeToFileNamed($update) == AZ_OK ) {
    die 'Error writing update.zip';
}
###############################################################################


###############################################################################
#Sign update.zip
###############################################################################
system("/usr/java/jdk1.6.0_29/bin/java -classpath $testsign testsign $update $signed");
###############################################################################


