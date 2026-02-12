#!/usr/bin/env bash
set -euo pipefail


# Always use RAW-DATA as main directory
main_dir="$(dirname "$0")/../RAW-DATA"
out_dir="$(dirname "$0")/../COMBINED-DATA"

translation_file="${main_dir}/sample-translation.txt"
if [[ ! -f "${translation_file}" ]]; then
  echo "Missing sample-translation.txt in RAW-DATA" >&2
  exit 1
fi

mkdir -p "${out_dir}"

get_culture() {
  awk -F $'\t' -v s="$1" 'NR>1 && $1==s {print $2; exit}' "${translation_file}"
}

reformat_fasta() {
  awk -v pfx="$3" 'BEGIN{n=0} /^>/{n++; print ">"pfx"_"sprintf("%03d",n); next} {print}' "$1" > "$2"
}

for sample_dir in "${main_dir}"/*; do
  [[ -d "${sample_dir}" ]] || continue
  sample_name="$(basename "${sample_dir}")"
  [[ "${sample_name}" == "COMBINED-DATA" ]] && continue

  culture="$(get_culture "${sample_name}")"
  [[ -z "${culture}" ]] && culture="${sample_name}"

  [[ -f "${sample_dir}/checkm.txt" ]] && cp -f "${sample_dir}/checkm.txt" "${out_dir}/${culture}-CHECKM.txt"
  [[ -f "${sample_dir}/gtdb.gtdbtk.tax" ]] && cp -f "${sample_dir}/gtdb.gtdbtk.tax" "${out_dir}/${culture}-GTDB-TAX.txt"

  bins_dir="${sample_dir}/bins"
  [[ -d "${bins_dir}" ]] || continue

  mag_idx=0
  bin_idx=0

  for fa in "${bins_dir}"/*.fasta; do
    [[ -f "${fa}" ]] || continue
    base="$(basename "${fa}")"

    if [[ "${base}" == "bin-unbinned.fasta" ]]; then
      out_fa="${out_dir}/${culture}_UNBINNED.fa"
      reformat_fasta "${fa}" "${out_fa}" "${culture}_UNBINNED"
      continue
    fi

    num="${base#bin-}"
    num="${num%.fasta}"
    [[ "${num}" =~ ^[0-9]+$ ]] || continue
    num=$((10#${num}))

    type="BIN"
    if [[ -f "${sample_dir}/checkm.txt" ]]; then
      read -r completeness contamination < <(
        awk -v n="${num}" '$1 ~ ("bin-" n "$") {print $(NF-2), $(NF-1); exit}' "${sample_dir}/checkm.txt"
      ) || true
      if [[ -n "${completeness:-}" && -n "${contamination:-}" ]]; then
        comp_ok=$(awk -v c="${completeness}" 'BEGIN{print (c>=50)?1:0}')
        cont_ok=$(awk -v c="${contamination}" 'BEGIN{print (c<=5)?1:0}')
        [[ "${comp_ok}" -eq 1 && "${cont_ok}" -eq 1 ]] && type="MAG"
      fi
    fi

    if [[ "${type}" == "MAG" ]]; then
      mag_idx=$((mag_idx+1))
      idx=$(printf "%03d" "${mag_idx}")
    else
      bin_idx=$((bin_idx+1))
      idx=$(printf "%03d" "${bin_idx}")
    fi

    out_fa="${out_dir}/${culture}_${type}_${idx}.fa"
    reformat_fasta "${fa}" "${out_fa}" "${culture}_${type}_${idx}"
  done
done
