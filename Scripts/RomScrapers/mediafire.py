# ꕤ AGL
import requests
import json
import os
import re

FOLDER_URL   = ''
CONSOLE_NAME = ''
FILE_NAME    = ''
OUTPUT_DIR   = 'output_roms'
OUTPUT_PATH  = os.path.join(OUTPUT_DIR, f'{FILE_NAME}_roms.json')

API_BASE = 'https://www.mediafire.com/api/1.5/folder/get_content.php'
HEADERS  = {'User-Agent': 'Mozilla/5.0'}
SKIP_EXTENSIONS = ('.xml', '.sqlite', '.torrent', '.txt', '.jpg', '.png',
                   '.json', '.nfo', '.dat', '.html', '.htm')

def extract_folder_key(url: str) -> str:
    match = re.search(r'/folder/([a-zA-Z0-9]+)', url)
    if match:
        return match.group(1)
    match = re.search(r'[?&]([a-zA-Z0-9]{13,})', url)
    if match:
        return match.group(1)
    raise ValueError(f'Não foi possível extrair a folder key de: {url}')

def format_size(size_bytes) -> str:
    try:
        size = int(size_bytes)
    except (TypeError, ValueError):
        return '—'
    if size < 1024:
        return f'{size} B'
    elif size < 1024 ** 2:
        return f'{size / 1024:.1f} KB'
    elif size < 1024 ** 3:
        return f'{size / 1024 ** 2:.1f} MB'
    else:
        return f'{size / 1024 ** 3:.2f} GB'

def fetch_all_files(folder_key: str) -> list:
    all_files = []
    chunk = 1
    while True:
        params = {
            'folder_key':      folder_key,
            'content_type':    'files',
            'response_format': 'json',
            'chunk':           chunk,
        }
        print(f'  [~] Buscando chunk {chunk}...')
        response = requests.get(API_BASE, params=params, headers=HEADERS, timeout=30)
        response.raise_for_status()
        data = response.json()
        result = data.get('response', {}).get('result', '')
        if result != 'Success':
            message = data.get('response', {}).get('message', 'Sem detalhes.')
            print(f'[-] API retornou erro: {message}')
            break
        folder_content = data['response'].get('folder_content', {})
        files          = folder_content.get('files', [])
        more_chunks    = folder_content.get('more_chunks', 'no')
        all_files.extend(files)
        print(f'  [+] {len(files)} arquivo(s) encontrado(s) no chunk {chunk}.')
        if more_chunks.lower() != 'yes':
            break
        chunk += 1
    return all_files

def build_rom_entry(file: dict) -> dict | None:
    filename = file.get('filename', '')
    if filename.lower().endswith(SKIP_EXTENSIONS):
        return None
    link = (file.get('links', {}).get('normal_download')
            or file.get('links', {}).get('view')
            or '')
    name = os.path.splitext(filename)[0].replace('_', ' ').strip()
    size = format_size(file.get('size', 0))
    return {
        'name':    name,
        'console': CONSOLE_NAME,
        'size':    size,
        'link':    link,
    }

def extract_roms():
    print(f'[+] Iniciando scraping para: {CONSOLE_NAME}')
    print(f'[+] Fonte: {FOLDER_URL}')
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        print(f'[!] Pasta /{OUTPUT_DIR} criada.')
    try:
        folder_key = extract_folder_key(FOLDER_URL)
        print(f'[+] Folder key detectada: {folder_key}')
        raw_files = fetch_all_files(folder_key)
        print(f'[+] Total de arquivos brutos: {len(raw_files)}')
        roms = []
        for file in raw_files:
            entry = build_rom_entry(file)
            if entry:
                roms.append(entry)
        with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
            json.dump(roms, f, indent=2, ensure_ascii=False)
        print(f'[+] Sucesso! {len(roms)} ROMs salvas em: {OUTPUT_PATH}')
    except Exception as e:
        print(f'[-] Erro durante o processo: {e}')

if __name__ == '__main__':
    extract_roms()