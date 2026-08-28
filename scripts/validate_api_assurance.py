#!/usr/bin/env python3
import json
from pathlib import Path

P = Path('contracts/api-assurance.v1.json')

def fail(msg):
    raise SystemExit(f'FAIL: {msg}')

m = json.loads(P.read_text(encoding='utf-8'))
if m.get('schema') != 'rafaelia.termux-api-assurance.v1': fail('schema')
if m.get('claim_allowed') is not False: fail('claim_allowed')
if m['authority'].get('vectras_attractor_authority_local') is not False: fail('authority drift')
if m['identity'].get('main_app_package') != 'com.termux.rafacodephi': fail('main package')
if m['identity'].get('api_package') != 'com.termux.rafacodephi.api': fail('api package')
if 'armeabi-v7a' not in m['identity'].get('abis', []): fail('ARM32 lost')
if m['license'].get('flatten_to_single_invented_license') is not False: fail('license flattening')
if m['pairing'].get('debug_build_is_pairing_proof') is not False: fail('debug build promoted')
if m['ipc'].get('broadcast_dispatch_is_terminal_success') is not False: fail('dispatch promoted')
if m['security_privacy'].get('state') != 'FAIL_CLOSED': fail('privacy/security not fail-closed')
if 'TOKEN_VAZIO' not in m['physical_runtime'].get('state',''): fail('physical runtime prematurely promoted')
if not any(g['urgency']=='P0' and g['state']=='TOKEN_VAZIO' for g in m['gaps']): fail('P0 open gap missing')
if not m['rollback'].get('available'): fail('rollback')
text = Path('AGENTS.md').read_text(encoding='utf-8')
if 'Termux API plugin / Android API producer' not in text: fail('AGENTS local authority not corrected')
if 'Historical Vectras/RafaelOS/attractor instructions' not in text: fail('authority-history boundary missing')
print('PASS: Termux API authority, pairing, IPC and runtime gates are fail-closed')
