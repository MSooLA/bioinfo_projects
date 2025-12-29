#!/usr/bin/env bash
set -euo pipefail

IN_ROOT="/home/adminrig/projects/novaseq_wg/alignment_hg19/211222"
OUT_ROOT="/home/adminrig/sultan/UMC"
mkdir -p "$OUT_ROOT"

declare -a IDS=(
  "14UMC" "16UMC" "5UMC"
)

FILTER_EXPR='FILTER="PASS" && INFO/DP>10 && QUAL>30'

for id in "${IDS[@]}"; do
  in_vcf="${IN_ROOT}/${id}/${id}.FINAL.FINAL.annovar.hg19_multianno.vcf"
  out_vcf="${OUT_ROOT}/${id}.PASS.DP10.QUAL30.vcf.gz"

  if [[ ! -f "$in_vcf" ]]; then
    echo "[WARN] Missing file: $in_vcf" >&2
    continue
  fi

  echo "[*] ${id} → ${out_vcf}"

  # Check if INDEL_FAIL is declared in the header; if not, add it on the fly.
  if ! bcftools view -h "$in_vcf" | grep -q '^##FILTER=<ID=INDEL_FAIL'; then
    # Stream: add header line, then filter
    bcftools annotate -h <(echo '##FILTER=<ID=INDEL_FAIL,Description="Undefined filter from source VCF">') \
      "$in_vcf" -Ou \
    | bcftools view -i "$FILTER_EXPR" -Oz -o "$out_vcf"
  else
    # Header already has INDEL_FAIL; just filter
    bcftools view -i "$FILTER_EXPR" -Oz -o "$out_vcf" "$in_vcf"
  fi

  # Index (CSI)
  bcftools index -f --csi "$out_vcf"
done

echo "[DONE] Outputs in: $OUT_ROOT"
ls -1 "$OUT_ROOT"/*.PASS.DP10.QUAL30.vcf.gz*

