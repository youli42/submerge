#!/usr/bin/env python3
"""由上游 docker-compose.yml 生成 podman 版（只改 healthcheck.test 的写法）。
podman-compose 1.3.0 用 '  '.join(shlex.quote(i)) 序列化 CMD 列表，
会把上游 node -e 脚本暴露给 /bin/sh -c 造成 dash 语法错误 -> 永远 unhealthy
-> 依赖 service_healthy 的 submerge/mihomo 起不来。test 用字符串形式则会被
正确 cmd_quote。上游更新后重跑本脚本即可。"""
import re, sys
src = open('docker-compose.yml', encoding='utf-8').read()
new_test = '      test: nft list table inet submerge_gateway > /dev/null\n'
pat = re.compile(r'^      test:\n(?:        .*.\n|        - .*\n)+', re.M)
# test: 后面紧跟的是 "        - CMD" 之类的列表项，直到下一个键（interval:）
pat = re.compile(r'^      test:\n(?:        .*\n)+?(?=      interval:)', re.M)
out, n = pat.subn(new_test, src)
if n != 1:
    sys.exit(f'healthcheck test block replacement count = {n} (expected 1)')
open('docker-compose.podman.yml', 'w', encoding='utf-8').write(out)
print('generated docker-compose.podman.yml, replacements =', n)
