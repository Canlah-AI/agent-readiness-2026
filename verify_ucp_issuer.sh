#!/usr/bin/env bash
# 复核 UCP manifest 到底是谁派发的 —— 这份数据集最核心的那一列就是这么来的。
#
# 为什么需要它:原始采集只有在 host hint 泄漏出 *.myshopify.com 时才敢标 "Shopify",
# 那是 25 家里的 3 家,严重低估 —— Shopify 店挂自有域名时 host hint 什么都不漏。
# 改读 powered-by 响应头之后,22 家直接自报 Shopify;剩下 3 家该路径已下线,
# 但采集时的 host hint 正是 *.myshopify.com。合计 25/25。
#
# 用法: ./verify_ucp_issuer.sh [dataset.csv]
set -euo pipefail
CSV="${1:-dataset.csv}"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36"

printf '%-14s %-28s %s\n' BRAND DOMAIN RESULT
shopify=0; other=0; gone=0; unreachable=0; n=0
# 按列位读到第 6 列 ucp。不要用 `case ",$_rest," in *",true,"*` 去猜:
# dataset.csv 有 22 列、十余列是布尔,那种写法会命中任意一列的 true(实测选中 48 行而非 25)。
while IFS=, read -r brand domain vertical reachable home_status ucp _rest; do
  [ "$brand" = "brand" ] && continue
  [ "$ucp" = "true" ] || continue
  n=$((n+1))
  # 网络故障必须与「站点真的不再提供该路径」分开计数,否则一次超时会被记成一次下线,
  # 让复现者拿到一个看起来像结论、实际是本地网络噪声的数字。
  if hdr=$(curl -sS -m 12 -A "$UA" -L -D- -o /dev/null "https://$domain/.well-known/ucp.json" 2>/dev/null); then
    if grep -qi 'powered-by: Shopify' <<<"$hdr"; then
      r="Shopify (live header)"; shopify=$((shopify+1))
    elif grep -q '^HTTP.* 200' <<<"$hdr"; then
      r="200, no Shopify header"; other=$((other+1))
    else
      r="no longer served"; gone=$((gone+1))
    fi
  else
    r="UNREACHABLE (network/TLS error — not a finding)"; unreachable=$((unreachable+1))
  fi
  printf '%-14s %-28s %s\n' "$brand" "$domain" "$r"
done < "$CSV"
printf '\nrows tested: %s (expected 25)\n' "$n"
printf 'Shopify header: %s | 200 without it: %s | gone: %s | unreachable: %s\n' \
  "$shopify" "$other" "$gone" "$unreachable"
printf '\nPublished run (2026-08-20): Shopify 22 | 200 without it 0 | gone 3 | unreachable 0\n'
printf 'The 3 "gone" are Anker / Soundcore / eufy; their collection-time host hints were *.myshopify.com.\n'
printf 'Live re-runs drift: sites add and drop /.well-known/ucp.json over time. A row moving between\n'
printf 'Shopify and "gone" is a real-world change; any row landing in UNREACHABLE is YOUR network, not data.\n'
