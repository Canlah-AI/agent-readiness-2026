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
shopify=0; other=0; gone=0
while IFS=, read -r brand domain _rest; do
  [ "$brand" = "brand" ] && continue
  case ",$_rest," in *",true,"*) : ;; *) continue ;; esac   # 只测 ucp=true 的行
  hdr=$(curl -s -m 12 -A "$UA" -L -D- -o /dev/null "https://$domain/.well-known/ucp.json" || true)
  if grep -qi 'powered-by: Shopify' <<<"$hdr"; then r="Shopify (live header)"; shopify=$((shopify+1))
  elif grep -qc '^HTTP.* 200' <<<"$hdr" >/dev/null && grep -q '^HTTP.* 200' <<<"$hdr"; then r="200, no Shopify header"; other=$((other+1))
  else r="no longer served"; gone=$((gone+1)); fi
  printf '%-14s %-28s %s\n' "$brand" "$domain" "$r"
done < "$CSV"
printf '\nShopify header: %s | 200 without it: %s | gone: %s\n' "$shopify" "$other" "$gone"
