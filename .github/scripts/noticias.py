#!/usr/bin/env python3
"""Coleta notícias do MPGO (prioridade CyberGaeco e GAECO) e grava noticias.json no site do painel.
Uso: python noticias.py <pasta_do_site>
Se nada for encontrado, mantém o arquivo atual."""
import json, os, re, sys, html, hashlib, datetime as dt, urllib.request, urllib.parse
import xml.etree.ElementTree as ET

SITE = sys.argv[1] if len(sys.argv) > 1 else '.'
OUT = os.path.join(SITE, 'noticias.json')
IMGDIR = os.path.join(SITE, 'nt')
UA = {'User-Agent': 'Mozilla/5.0 (painel-tab-a; atualizador de noticias)'}
BASE = 'https://www.mpgo.mp.br'
HOJE = dt.datetime.now(dt.timezone.utc)

def get(url, binary=False, t=25):
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=t) as r:
            b = r.read()
            return b if binary else b.decode('utf-8', 'replace')
    except Exception as e:
        print('falhou', url, e)
        return None

def meta(h, prop):
    m = re.search(r'<meta[^>]+(?:property|name)=["\']%s["\'][^>]*content=["\']([^"\']*)' % re.escape(prop), h, re.I) \
        or re.search(r'<meta[^>]+content=["\']([^"\']*)["\'][^>]*(?:property|name)=["\']%s["\']' % re.escape(prop), h, re.I)
    return html.unescape(m.group(1)).strip() if m else ''

def score(txt):
    t = txt.lower()
    s = 0
    if 'cybergaeco' in t or 'cyber gaeco' in t or 'crime cibern' in t or 'crimes cibern' in t: s += 6
    if 'gaeco' in t: s += 4
    if 'operação' in t or 'operacao' in t: s += 2
    if any(k in t for k in ('curso', 'capacita', 'prêmio', 'premio', 'premia', 'homenage', 'treinamento')): s += 1
    return s

def tag(txt):
    t = txt.lower()
    if 'cybergaeco' in t or 'cyber gaeco' in t or 'cibern' in t: return 'CYBERGAECO'
    if 'gaeco' in t: return 'GAECO'
    return 'MPGO'

def resumo(s, n=190):
    s = re.sub(r'\s+', ' ', s or '').strip()
    if len(s) <= n: return s
    s = s[:n].rsplit(' ', 1)[0].rstrip(',;:')
    return s + '…'

def data_iso(s):
    if not s: return ''
    m = re.search(r'(\d{4})-(\d{2})-(\d{2})', s)
    if m: return m.group(0)
    m = re.search(r'(\d{2})/(\d{2})/(\d{4})', s)
    if m: return f'{m.group(3)}-{m.group(2)}-{m.group(1)}'
    try: return dt.datetime.strptime(s[:25].strip(), '%a, %d %b %Y %H:%M:%S').strftime('%Y-%m-%d')
    except Exception: return ''

itens = {}

# 1) portal do MPGO
links = []
for p in ['/portal/noticias', '/portal/noticias?pagina=2', '/portal/noticias?pagina=3', '/portal/',
          '/portal/busca?q=gaeco', '/portal/busca?q=cybergaeco']:
    h = get(BASE + p)
    if not h: continue
    for l in re.findall(r'href=["\']((?:https?://www\.mpgo\.mp\.br)?/portal/noticia/[a-z0-9\-_%]+)', h, re.I):
        u = l if l.startswith('http') else BASE + l
        if u not in links: links.append(u)
print('links MPGO:', len(links))
for u in links[:40]:
    h = get(u)
    if not h: continue
    t = meta(h, 'og:title') or (re.search(r'<title>([^<]+)', h) or [None, ''])[1]
    t = re.sub(r'\s*[-|–]\s*MPGO.*$', '', html.unescape(t)).strip()
    if not t: continue
    desc = meta(h, 'og:description') or meta(h, 'description')
    d = data_iso(meta(h, 'article:published_time')) or data_iso((re.search(r'(\d{2}/\d{2}/\d{4})', h) or [None, ''])[0] if re.search(r'(\d{2}/\d{2}/\d{4})', h) else '')
    itens[u] = {'t': t, 'url': u, 'sum': resumo(desc), 'd': d, 'src': 'MPGO', 'tag': tag(t + ' ' + desc + ' ' + u),
                'img_src': meta(h, 'og:image'), 'sc': score(t + ' ' + desc + ' ' + u)}

# 2) reserva: Google Notícias (só título, fonte e data)
for q in ['CyberGaeco', 'Gaeco MPGO', 'Gaeco Goiás operação', 'MPGO operação']:
    x = get('https://news.google.com/rss/search?' + urllib.parse.urlencode({'q': q + ' when:30d', 'hl': 'pt-BR', 'gl': 'BR', 'ceid': 'BR:pt-419'}))
    if not x: continue
    try: root = ET.fromstring(x)
    except Exception: continue
    for it in root.iter('item'):
        t = (it.findtext('title') or '').strip()
        src = (it.findtext('source') or '').strip()
        if src and t.endswith(' - ' + src): t = t[:-(len(src) + 3)].strip()
        txt = t.lower()
        if not ('goiás' in txt or 'goias' in txt or 'mpgo' in txt or 'mp-go' in txt or 'goiân' in txt or 'anápolis' in txt or 'cybergaeco' in txt): continue
        u = it.findtext('link') or ''
        if any(v['t'].lower()[:40] == t.lower()[:40] for v in itens.values()): continue
        itens[u] = {'t': t, 'url': u, 'sum': '', 'd': data_iso(it.findtext('pubDate')), 'src': src or 'Google Notícias',
                    'tag': tag(t), 'img_src': '', 'sc': score(t) - 1}

# filtra últimos 45 dias e ordena: semana atual com maior prioridade primeiro
def idade(v):
    try: return (HOJE.date() - dt.date.fromisoformat(v['d'])).days
    except Exception: return 99
lst = [v for v in itens.values() if idade(v) <= 45 and v['sc'] > 0]
lst.sort(key=lambda v: (0 if idade(v) <= 7 else 1, -v['sc'], idade(v)))
lst = lst[:8]
print('itens:', len(lst))
if not lst:
    print('nada novo; mantendo arquivo atual'); sys.exit(0)

# imagens (miniaturas pequenas, só do portal do MPGO)
os.makedirs(IMGDIR, exist_ok=True)
usadas = set()
try:
    from PIL import Image
    import io
except Exception:
    Image = None
for v in lst[:6]:
    v['img'] = ''
    src = v.pop('img_src', '')
    if not src or Image is None: continue
    src = urllib.parse.urljoin(BASE, src)
    nome = hashlib.sha1(src.encode()).hexdigest()[:12] + '.jpg'
    dest = os.path.join(IMGDIR, nome)
    if not os.path.exists(dest):
        b = get(src, binary=True)
        if not b: continue
        try:
            im = Image.open(io.BytesIO(b)).convert('RGB'); im.thumbnail((720, 480)); im.save(dest, 'JPEG', quality=78)
        except Exception as e:
            print('imagem falhou', e); continue
    v['img'] = 'nt/' + nome; usadas.add(nome)
for v in lst:
    v.pop('img_src', None); v.pop('sc', None); v.setdefault('img', '')
for f in os.listdir(IMGDIR):
    if f not in usadas: os.remove(os.path.join(IMGDIR, f))

novo = {'atualizado': HOJE.strftime('%Y-%m-%dT%H:%M:%SZ'), 'itens': lst}
try:
    velho = json.load(open(OUT))
    if velho.get('itens') == lst: print('sem mudanças'); sys.exit(0)
except Exception: pass
json.dump(novo, open(OUT, 'w'), ensure_ascii=False, indent=1)
print('gravado', OUT)
