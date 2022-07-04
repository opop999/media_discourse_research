new_type_tuple =(("tabloids", "VgYGq6aCc2mG"),
                ("opinion", "yo6IqeicqMkE"),
                ("political_tabloids","3a8skuqGKwug"),
                ("analytical_investigative","wKoC0MKMKwmI"),
                ("anti_systemic", "t8eaEGOq8oSM"),
                ("mainstream", "uU8qgYUyyCCK"),
                ("market_driven", "8w2kioEEckmE"),
                ("other", "qSuwuucUGUg6"),
                ("party_webs", "7mqQWkAokSKO"),
                ("institutions", "9WWGQ0i0ACuK"),
                ("unknown", "MiYAkG04eSqG"))

import requests
import re
import json
   
    base_url_start = "https://www.korpus.cz/kontext/freqs?maincorp=online_archive&viewmode=kwic&pagesize=40&attrs=word&attr_vmode=visible-kwic&base_viewattr=word&refs=doc&q=~"
    base_url_end = "&fcrit=doc.resource%200&flimit=1&fpage=1&ftt_include_empty=1"
    
links = [base_url_start + new_type_tuple[i][1] + base_url_end for i,_ in enumerate(new_type_tuple)]

full_pages = [requests.get(link, headers={'User-Agent': "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36", 'accept-encoding': 'gzip, deflate, br'}) for link in links]
   
# match = [json.loads(re.search("(?<=FreqResultData = ).*(?=;)", page.text).group(0))[0]["Items"] for page in full_pages]   
   
    
# match = json.loads(re.search(r"(?<=FreqResultData = ).*(?=;)", full_pages[0].text)).group(0))[0]["Items"]

media = [ medium["Word"][0]["n"] for medium in match ]

