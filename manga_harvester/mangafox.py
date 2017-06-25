import feedparser
import requests
import urllib
import re
import os
import sqlite3
import yaml
# import numpy as np

from datetime import datetime
from bs4 import BeautifulSoup


def get_chapters(url_rss, limit=150):
    feed = feedparser.parse(url_rss)
    for i, entry in enumerate(feed.entries):
        if i < limit:
            yield entry.title, entry.link


def get_page_count(page):
    form_top_bar = page.find_all('form', {'id': "top_bar"})
    return len(form_top_bar[0].find_all('option')) - 1  # exclude comment option


def get_page(url, user_agent=None):
    if user_agent is None:
        user_agent = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0"
    headers = {'User-Agent': user_agent}
    response = requests.get(url, headers=headers)
    page = BeautifulSoup(response.content, 'lxml')
    return page


def get_page_links(url):
    page = get_page(url)
    base_url = re.sub(r'\d+\.html', '', url)

    page_numbers = range(1, get_page_count(page) + 1)

    page_links = []
    for n in page_numbers:
        page_url = '%s%s.html' % (base_url, n)
        page_links.append(page_url)

    return page_links


def get_page_image(page_link):
    for item in page.findAll('img', attrs={'id': 'image'}):
        links.append(item['src'])
    return links


def download_page_image(page, page_number, output):
    for item in page.findAll('img', attrs={'id': 'image'}):
        src = item['src']
        urllib.urlretrieve(src, '%s/%s.jpg' % (output, page_number))
        print 'downloaded: %s' % src


def connect_to_db(path_db):
    if not os.path.exists(path_db):
        db = sqlite3.connect(path_db)
        c = db.cursor()
        c.execute('''
            CREATE TABLE harvested
            (timestamp text, name text, volume real, chapter real)''')
    else:
        db = sqlite3.connect(path_db)
    return db


def insert_record(db, record):
    c = db.cursor()
    c.execute('INSERT INTO harvested VALUES (?,?,?,?)', record)


def insert_records(db, records):
    c = db.cursor()
    c.executemany('INSERT INTO harvested VALUES (?,?,?,?)', records)


def query_chapter(db, series, volume, chapter, verbose=False):
    c = db.cursor()
    results = c.execute('''
        SELECT *
        FROM harvested
        WHERE name = ? AND volume = ? AND chapter = ?
        ORDER BY volume, chapter''', (series, volume, chapter,))

    results = results.fetchall()
    for i, row in enumerate(results):
        if verbose and i <= 100:
            print("%s: %s" % (i, row))

    return results


def aleady_downloaded(db, series, volume, chapter):
    results = query_chapter(db, series, volume, chapter)
    return True if len(results) > 0 else False


def download_manga(url_rss):
    mask = re.compile(r'(^.*?) Vol (\d+|TBD) Ch (\d+.*)')

    try:
        db = connect_to_db(path_db)

        for i, (title, link) in enumerate(get_chapters(url_rss)):
            name, volume, chapter = mask.findall(title)[0]
            output_dir_chapter = os.path.join(output_dir, title)

            # TODO: remove for code cleanliness?
            if i == 0:
                min_volume, max_volume = volume, volume
                min_chapter, max_chapter = chapter, chapter
            else:
                if volume != 'TBD':
                    if volume < min_volume:
                        min_volume = volume
                    if volume > max_volume:
                        max_volume = volume
                if chapter < min_chapter:
                    min_chapter = chapter
                if chapter > max_chapter:
                    max_chapter = chapter

            # TODO: check once with query for all chapters not individually
            if not aleady_downloaded(db, name, volume, chapter):
                print('%s: downloading...' % title)
                if not os.path.exists(output_dir_chapter):
                    os.makedirs(output_dir_chapter)

                page_links = get_page_links(link)
                for n, page_link in enumerate(page_links, start=1):
                    page = get_page(page_link)
                    download_page_image(page, n, output_dir_chapter)

                # TODO: commit less frequently maybe - depends on download time
                timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                record = (timestamp, name, volume, chapter)
                insert_record(db, record)
                db.commit()
            # else:
            #     print('%s: already downloaded.' % title)
        args = (name, min_volume, max_volume, min_chapter, max_chapter)
        print('\n%s\nvolumes   %s:%s\nchapters %s:%s\n' % args)

    except Exception as e:
        raise e

    finally:
        db.close()


def get_rss_url(name):
    return 'http://mangafox.me/rss/{}.xml'.format(name)


if __name__ == '__main__':
    path = '/home/rokkuran/workspace/miscellaneous/manga_harvester/'
    output_dir = os.path.join(path, 'output')
    path_db = os.path.join(path, 'harvested.sqlite')

    config = yaml.safe_load(open(os.path.join(path, 'config.yml'), 'rb'))
    rss_manga_names = config['rss_manga_names']
    rss_urls = [get_rss_url(name) for name in rss_manga_names]

    for url_rss in rss_urls:
        download_manga(url_rss)
