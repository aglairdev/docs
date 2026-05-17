# ꕤ AGL
import requests
from bs4 import BeautifulSoup
import json
import urllib.parse
import os

BASE_URL     = ''
CONSOLE_NAME = ''
FILE_NAME    = ''
OUTPUT_DIR   = 'output_roms'
OUTPUT_PATH  = os.path.join(OUTPUT_DIR, f'{FILE_NAME}_roms.json')

def extract_roms():
    print(f'[+] Iniciando scraping para: {CONSOLE_NAME}')

    raw_url = BASE_URL.replace('/details/', '/download/')
    base_url_fixed = raw_url if raw_url.endswith('/') else raw_url + '/'

    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        print(f'[!] Pasta /{OUTPUT_DIR} criada.')

    try:
        print(f'[+] Acessando: {base_url_fixed}')
        response = requests.get(base_url_fixed)
        response.raise_for_status()

        soup = BeautifulSoup(response.text, 'html.parser')
        roms = []
        table = soup.find('table')

        if not table:
            print('[-] Tabela não encontrada. Verifique o link do Archive.')
            return

        rows = table.find_all('tr')
        for row in rows:
            link_tag = row.find('a')
            if not link_tag or not link_tag.get('href'):
                continue

            href = link_tag.get('href')
            if (href.startswith('?') or
                href.startswith('/') or
                '../' in href or
                href.lower().endswith(('.xml', '.sqlite', '.torrent', '.txt',
                                       '.jpg', '.png', '.json'))):
                continue

            link_direto = urllib.parse.urljoin(base_url_fixed, href)
            name_raw    = urllib.parse.unquote(href)
            name        = os.path.splitext(name_raw)[0].replace('_', ' ').strip()

            cols = row.find_all('td')
            size = '—'
            if len(cols) >= 3:
                size = cols[2].get_text(strip=True) or '—'

            roms.append({
                'name':    name,
                'console': CONSOLE_NAME,
                'size':    size,
                'link':    link_direto,
            })

        with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
            json.dump(roms, f, indent=2, ensure_ascii=False)

        print(f'[+] Sucesso! {len(roms)} ROMs processadas e salvas em: {OUTPUT_PATH}')

    except Exception as e:
        print(f'[-] Erro durante o processo: {e}')

if __name__ == '__main__':
    extract_roms()