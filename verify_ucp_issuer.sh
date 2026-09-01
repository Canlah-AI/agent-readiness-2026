#!/usr/bin/env bash
# 复核 UCP manifest 到底是谁派发的 —— 这份数据集最核心的那一列就是这么来的。
#
# ⚠️ v1.0.2 更正（2026-09-01）:此脚本此前探测 /.well-known/ucp.json,而采集管线探测的是
# /.well-known/ucp(无扩展名)。两者不等价:Shopify 边缘对 .json 有 catch-all 会一并应答,
# 自建前端(Netlify/Next.js)则只应答无扩展名那条。于是三家自建前端的品牌被误判成
# 「manifest 已下线」,并由此推出「~12% churn」。两条结论都已撤回,见 ERRATUM.md。
# 本脚本现在探测与采集一致的路径,并直接读 manifest 正文判定派发方。
#
# 用法: ./verify_ucp_issuer.sh [dataset.csv]
set -euo pipefail
CSV="${1:-dataset.csv}"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36"
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT

printf '%-14s %-26s %-10s %s\n' BRAND DOMAIN VERSION RESULT
shopify=0; other=0; gone=0; unreachable=0; n=0
# 按列位读到第 6 列 ucp。不要用 `case ",$_rest," in *",true,"*` 去猜:
# dataset.csv 有 22 列、十余列是布尔,那种写法会命中任意一列的 true(实测选中 48 行而非 25)。
while IFS=, read -r brand domain vertical reachable home_status ucp _rest; do
  [ "$brand" = "brand" ] && continue
  [ "$ucp" = "true" ] || continue
  n=$((n+1))
  # 网络故障必须与「站点真的不再提供该路径」分开计数,否则一次超时会被记成一次下线。
  if curl -sS -m 20 -A "$UA" -L -o "$TMP" -w '' "https://$domain/.well-known/ucp" 2>/dev/null; then
    ver=$(grep -oE '"version"[: ]*"[0-9]{4}-[0-9]{2}-[0-9]{2}"' "$TMP" | head -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)
    if [ -s "$TMP" ] && grep -q 'myshopify\.com' "$TMP"; then
      r="Shopify-issued (myshopify.com in manifest)"; shopify=$((shopify+1))
    elif [ -s "$TMP" ]; then
      r="served, not Shopify-issued"; other=$((other+1))
    else
      r="no longer served"; gone=$((gone+1))
    fi
  else
    r="UNREACHABLE (network/TLS error — not a finding)"; unreachable=$((unreachable+1)); ver=""
  fi
  printf '%-14s %-26s %-10s %s\n' "$brand" "$domain" "${ver:-?}" "$r"
done < "$CSV"
printf '\nrows tested: %s (expected 25)\n' "$n"
printf 'Shopify-issued: %s | served, not Shopify: %s | no longer served: %s | unreachable: %s\n' \
  "$shopify" "$other" "$gone" "$unreachable"
printf '\nPublished run (2026-08-11 collection): 25 of 25 Shopify-issued.\n'
printf 'Re-run 2026-09-01: 25/25 still served and still Shopify-issued; manifest versions split\n'
printf '22 on 2026-08-25 and 3 (Anker, Soundcore, eufy) still on 2026-04-08.\n'
printf 'A row landing in UNREACHABLE is YOUR network, not data.\n'
