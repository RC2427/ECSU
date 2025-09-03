#!/bin/bash
# ================================================================================
# Component : OEDA install script
# Version   : 1.1
# Date      : 05-AUG-2025
# Author    : github.com/RC2427
# Description : Installs ECSU PL/SQL & REST artifacts, uploads with FNDLOAD, irep.
# Usage     : ./install.sh or sh install.sh
# ================================================================================

echo "============================================"
echo " Starting ECSU installation "
echo "============================================"

ENV_SCRIPT=/u01/install/APPS/EBSapps.env
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ ! -f "$ENV_SCRIPT" ]; then
  echo "ERROR: EBS env script not found: $ENV_SCRIPT" >&2
  exit 1
fi
. "$ENV_SCRIPT"


echo "***********************************************"
read -sp "Enter APPS password: " APPS_PWD
echo
echo
echo "***********************************************"
echo "-----------------------------------------------------------------"

sqlplus -L -s apps/"${APPS_PWD}"@${TWO_TASK} >/dev/null <<EOF
EXIT
EOF
if [ $? -ne 0 ]; then
  echo "ERROR: Invalid APPS password" >&2
  exit 1
fi
echo "APPS authentication OK."


echo "Copying PL/SQL sources to $FND_TOP/sql…"
cp XX_FND_GETEBSCOMP_RST_PKG.pls $FND_TOP/patch/115/sql

for file in XX_FND_GETEBSCOMP_RST_PKG.pks XX_FND_GETEBSCOMP_RST_PKG.pkb; do
  cp "$file" "$FND_TOP/sql/" || {
    echo "ERROR: Copy failed for $file" >&2
    exit 2
  }
done

echo "PL/SQL sources copied."

echo "-----------------------------------------------------------------"
echo "Uploading valuesets"

shopt -s nullglob
for ldt in *.ldt; do
  echo "Uploading: $ldt"
  FNDLOAD apps/"${APPS_PWD}" 0 Y UPLOAD $FND_TOP/patch/115/import/afffload.lct "$ldt"
done
shopt -u nullglob

echo "-----------------------------------------------------------------"

echo "Deploying REST definitions with irep_parser"
$IAS_ORACLE_HOME/perl/bin/perl $FND_TOP/bin/irep_parser.pl -g -v -username=sysadmin fnd:patch/115/sql:XX_FND_GETEBSCOMP_RST_PKG.pls:12.0=XX_FND_GETEBSCOMP_RST_PKG.pls  \
|| {
  echo "ERROR: irep_parser failed" >&2
  exit 3
}
echo "REST definition deployed."


echo "Uploading ILDT via FNDLOAD…"
$FND_TOP/bin/FNDLOAD APPS/$APPS_PWD 0 Y UPLOAD $FND_TOP/patch/115/import/wfirep.lct XX_FND_GETEBSCOMP_RST_PKG_pls.ildt \
|| {
  echo "ERROR: FNDLOAD upload failed" >&2
  exit 4
}
echo "ILDT uploaded."
echo "-----------------------------------------------------------------"
echo "============================================"
echo " ECSU installation completed successfully."
echo "============================================"
exit 0
