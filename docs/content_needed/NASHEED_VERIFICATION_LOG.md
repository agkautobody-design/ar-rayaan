# Nasheed verification log

Pack: `assets/academy/player_catalog_verified.json` (200 entries). Built by `tool/build_verified_catalogue.py` from `tool/nasheed_verified/verified.tsv`.

## Method

- Candidate video IDs came from web search results. Each ID was then fetched through YouTube's public oEmbed response (`youtube.com/oembed?url=...`), which returns the exact title and the uploading channel. An entry was kept only if the uploading channel is the artist's own channel, the artist's label, or a YouTube-generated `- Topic` artist channel. Re-uploads, lyric/slowed/cover channels, fan channels and compilations were rejected.
- oEmbed also refuses videos whose owner disabled embedding, so every kept entry is embeddable in the in-app player.
- Audio style is `vocals`/`duff` only when the official upload's own title says so (Vocals Only, no music, Voice Only, Duff). `music` = title says live/acoustic. Everything else is `unknown`: instrument use was NOT checked. The app has no vocals-only setting; it adds a Vocals / duff only filter chip (off by default) and a Voice only badge.
- Family-friendly is a judgement from artist and title, not a scholar's review. Language is taken from the title where it says so; entries whose language could not be told from the title were skipped.
- No audio files are in the repo. Streams come from the official channel; not downloadable.
- Channel officialness: name match plus, for Awakening Music, Wikipedia. Not independently corroborated for the other channels beyond the artist/label name. Owner should spot-check the label/broadcaster rows below.
- Limit: the fetch tool hit a usage cap and then an allowlist block mid-run, so verification stopped at 200 entries (target was 600). The 600 target was not reached.

## Channels (entries per channel)

| Channel | Entries | Class |
|---|---|---|
| @awakeningrecords | 74 | label (Awakening Music; Wikipedia: Awakening_Music, lists Maher Zain, Harris J) |
| @HiTechIslamic | 48 | label (Hi-Tech Islamic Naat) |
| @MaherZain | 12 | artist channel |
| @Studio5RecordLabel | 10 | label (Studio5) |
| @OmarEsa | 7 | artist channel |
| @samiyusuf | 5 | artist channel |
| @OSAIslamic | 5 | label/production |
| @owaisrazaqadriofficial | 5 | artist channel |
| @MesutKurtis | 4 | artist channel |
| @HeeraGoldOfficial | 3 | label/production |
| Topic channel UCygHS84HOOQTODBLeN1EmJw | 2 | YouTube-generated artist (Topic) channel |
| @hamzanamira | 2 | artist channel |
| Topic channel UC1QTP0OjM0qoPl2uLocqjbQ | 2 | YouTube-generated artist (Topic) channel |
| @nativedeen | 2 | artist channel |
| Topic channel UCmEpZxUSnx6qPpSzoLYluUA | 2 | YouTube-generated artist (Topic) channel |
| @MiladRazaQadri | 2 | artist channel |
| Topic channel UCIP2PQFYeNeaqlJXkt94UTQ | 1 | YouTube-generated artist (Topic) channel |
| @SafeAdam | 1 | artist channel |
| @ZainBhikhaKids | 1 | artist channel |
| Topic channel UCsGpBT-UElHMy7s4utUmuow | 1 | YouTube-generated artist (Topic) channel |
| @OneIslamProductions | 1 | producer of Zaky |
| @ahmedbukhatir | 1 | artist channel |
| @nativedeenofficial | 1 | artist-named; unconfirmed vs @nativedeen |
| @sieddofficial | 1 | artist channel |
| @FunMoKidsTV | 1 | producer of its own kids songs |
| @HafizTahirQadri | 1 | artist channel |
| @cokestudio | 1 | artist channel |
| @HafizAhmedRazaQadri | 1 | artist channel |
| @ARYDigitalasia | 1 | broadcaster official |
| @ARYQtvofficial | 1 | broadcaster official |
| Topic channel UCAkQeNJ-ZngaIQ-x5ioQmiw | 1 | YouTube-generated artist (Topic) channel |

## Entries by batch (source = oEmbed fetch of the video URL)

| Video ID | Channel | Artist | Title | Language | Occasion | Audio |
|---|---|---|---|---|---|---|
| jnJdXj3P26M | awakeningrecords | Maher Zain | Ramadan (Arabic) | Arabic | ramadan | unknown |
| 3G-t72JjRf0 | awakeningrecords | Maher Zain | Ramadan (English) | English | ramadan | unknown |
| IhIiusMJsgU | MaherZain | Maher Zain | Ramadan (Malay/Bahasa Version) | Malay | ramadan | unknown |
| zBrNyFJXrTY | awakeningrecords | Maher Zain | Hold My Hand (Official Lyric Video) | English | general | unknown |
| zL9PG59QOnY | MaherZain | Maher Zain | Forgive Me (Official Lyric Video) | English | istighfar | unknown |
| eLFW---YSWE | awakeningrecords | Maher Zain | Ya Nabi Salam Alayka (International Version) | English | mawlid | unknown |
| xwg9Lf5ruUE | awakeningrecords | Maher Zain | Assalamu Alayka (Arabic) | Arabic | mawlid | unknown |
| vMQVC7_b0po | awakeningrecords | Maher Zain | Ya Nabi Salam Alayka (Turkish Version) | Turkish | mawlid | unknown |
| etVDc-BJD5I | MaherZain | Maher Zain | Open Your Eyes (Official Lyric Video) | English | general | unknown |
| 2gVjxIIXnx0 | awakeningrecords | Maher Zain | Always Be There (Official Audio) | English | general | unknown |
| pFMofSt2vVw | awakeningrecords | Maher Zain | Number One For Me (Vocals Only) | English | general | vocals |
| f4J7-WR1QOY | awakeningrecords | Maher Zain | Number One For Me (Official Music Video) | English | general | unknown |
| aaL5MdGL4nU | MaherZain | Maher Zain | Palestine Will Be Free | English | general | unknown |
| QlmzLvkGUFE | awakeningrecords | Maher Zain | Rahmatun Lil'Alameen | Arabic | mawlid | unknown |
| 61C6FxprHuY | awakeningrecords | Maher Zain | Barak Allah Lakuma (Vocals Only) | English | wedding | vocals |
| x70E03p93yE | awakeningrecords | Maher Zain | Baraka Allahu Lakuma (Live & Acoustic) | English | wedding | music |
| AjzE4Uj7kIM | awakeningrecords | Maher Zain | Radhitu Billahi (Arabic) | Arabic | general | unknown |
| 9RwfpLI6uuI | awakeningrecords | Maher Zain | Eidun Mubarak | Arabic | eid | unknown |
| qut78xfB-E0 | awakeningrecords | Maher Zain | Yawmul Eid | Arabic | eid | unknown |
| JBCflFzjPZk | awakeningrecords | Maher Zain | Eidun Saeed (with Mesut Kurtis and MiniMuslims) | Arabic | eid | unknown |
| nDh5UdU_cZM | awakeningrecords | Maher Zain | Insha Allah (Vocals Only) | English | general | vocals |
| PACjNsQF0Z0 | awakeningrecords | Maher Zain | Insha Allah (Arabic) | Arabic | general | unknown |
| PPZPpnqtexI | awakeningrecords | Maher Zain | Insha Allah (Turkish) | Turkish | general | unknown |
| Kvger_C4LN8 | awakeningrecords | Maher Zain | Inchallah (French Version) | French | general | unknown |
| HrXPigts1m4 | awakeningrecords | Maher Zain | Insya Allah (Malay, Vocals Only) | Malay | general | vocals |
| KfXIF2Mm2Kc | awakeningrecords | Maher Zain | Insha Allah (Official Music Video) | English | general | unknown |
| N4G0fdh_Ty0 | awakeningrecords | Maher Zain | Awaken (Official Lyric Video) | English | general | unknown |
| pZiqnQpD2nU | awakeningrecords | Maher Zain | Take My Hand (Official Music Video) | English | general | unknown |
| BScguDkZhVo | awakeningrecords | Maher Zain | Open Your Eyes (Vocals Only) | English | general | vocals |
| bU_9HL7Sl4A | awakeningrecords | Maher Zain | Palestine Will Be Free (Vocals Only) | English | general | vocals |
| Of5FYEd1Z8M | MaherZain | Maher Zain | Rahmatun Lil'Alameen (Official Lyric Video) | Arabic | mawlid | unknown |
| wEz8ZvWPSZA | MaherZain | Maher Zain | Radhitu Billahi Rabba (Arabic, Lyric Video) | Arabic | general | unknown |
| F1CB1Zoa-UE | awakeningrecords | Maher Zain | Radhitu Billahi Rabba (Vocals Only) | Arabic | general | vocals |
| 25wH52RSam8 | awakeningrecords | Maher Zain | Ya Nabi Salam Alayka (Arabic, without music) | Arabic | mawlid | vocals |
| D5vsICvAA8U | awakeningrecords | Maher Zain | Ya Nabi Salam Alayka (International, Vocals Only) | English | mawlid | vocals |
| UW5K0OzOmVI | awakeningrecords | Maher Zain | Rahmatun Lil'Alameen (Vocals Only) | Arabic | mawlid | vocals |
| cuZ3HHlgOJM | awakeningrecords | Maher Zain | Maly Siwak (Vocals Only) | Arabic | general | vocals |
| fa5iEnq60OI | awakeningrecords | Maher Zain | Awaken (Vocals Only) | English | general | vocals |
| 4VU4_NZuL24 | awakeningrecords | Maher Zain | The Power (Vocals Only Version) | English | general | vocals |
| dx9dioA2TGE | awakeningrecords | Maher Zain | For The Rest Of My Life (Vocals Only) | English | wedding | vocals |
| jqM-L4Sfwug | awakeningrecords | Maher Zain | Allahu Ya Allahu | Arabic | general | unknown |
| r6omOg9WiS0 | awakeningrecords | Maher Zain | Yama Wo Yama | Arabic | general | unknown |
| WZuRkn-LzvE | awakeningrecords | Maher Zain | Thank You Allah (Vocals Only) | English | general | vocals |
| 0VcI_axdUZo | awakeningrecords | Maher Zain | Hold My Hand (Vocals Only) | English | general | vocals |
| yc6F_73UNNQ | awakeningrecords | Maher Zain | Forgive Me (Vocals Only) | English | istighfar | vocals |
| OvZK0unyLxA | awakeningrecords | Maher Zain | Subhana Allah with Mesut Kurtis (Vocals Only) | English | general | vocals |
| wHMcqYzLJiA | awakeningrecords | Maher Zain | Thank You (Official Video) | English | general | unknown |
| 5Ayx2WVxk_c | awakeningrecords | Maher Zain | Mashallah (Vocals Only) | Arabic | general | vocals |
| yvgFuOAmhZU | awakeningrecords | Maher Zain | Mawlaya (Vocals Only) | English | general | vocals |
| FpzBgI_ge9A | awakeningrecords | Maher Zain | Mawlaya (Arabic, Vocals Only) | Arabic | general | vocals |
| UzUEG5JBhJY | MaherZain | Maher Zain | Mawlaya (Arabic) | Arabic | general | unknown |
| AKxGpetj3_g | awakeningrecords | Maher Zain | Huwa AlQuran | Arabic | general | unknown |
| mFYGTHNDrlg | MaherZain | Maher Zain | Maly Siwak (Official Music Video) | Arabic | general | unknown |
| 4Me98slNhhM | awakeningrecords | Maher Zain | Al-Hawdh (Official Lyric Video) | Arabic | general | unknown |
| UhRcou6Clh8 | awakeningrecords | Maher Zain | Da'iman Wa Abada | Arabic | general | unknown |
| tBbdSzwxqyY | MaherZain | Maher Zain | Rahmatun Lil'Alameen (Official Music Video) | Arabic | mawlid | unknown |
| qxM008lh-dI | awakeningrecords | Maher Zain | Sallou | Arabic | mawlid | unknown |
| df-YD24K0NA | awakeningrecords | Maher Zain | Qamarun | Arabic | mawlid | unknown |
| bis9eeVKVL0 | awakeningrecords | Maher Zain | Kur'an (Turkish Version) | Turkish | general | unknown |
| u_-McEvEGvI | awakeningrecords | Harris J | Salam Alaikum (Official Music Video) | English | general | unknown |
| qnxYiaHRPFY | awakeningrecords | Harris J | Eid Mubarak ft. Shujat Ali Khan (Official Audio) | English | eid | unknown |
| 0Sdp7c4jiJg | awakeningrecords | Harris J | Let Me Breathe (Official Audio) | English | general | unknown |
| lxFglQCatEc | awakeningrecords | Harris J | Love Who You Are (Official Audio) | English | general | unknown |
| RWJ1uU2Spcs | awakeningrecords | Humood AlKhudher | Kun Anta (Official Lyric Video) | Arabic | general | unknown |
| rPo__G6_8r4 | topic:UCygHS84HOOQTODBLeN1EmJw | Humood AlKhudher | Kun Anta | Arabic | general | unknown |
| g1kPrIpwd1A | topic:UCygHS84HOOQTODBLeN1EmJw | Humood AlKhudher | Kun Anta (Vocals-Only, No Music) | Arabic | general | vocals |
| 9dwveMlPjKU | awakeningrecords | Mesut Kurtis | Ya Ramadan (Official Music Video) | Arabic | ramadan | unknown |
| 7Z8wmvX9occ | topic:UCIP2PQFYeNeaqlJXkt94UTQ | Mesut Kurtis | Ya Allah | Arabic | general | unknown |
| Sf4dhUGy67M | awakeningrecords | Hamza Namira | Ya Rabb (O Lord) (Official Audio) | Arabic | general | unknown |
| mGr-gsLWToE | hamzanamira | Hamza Namira | Kollo Ala Allah | Arabic | general | unknown |
| AdwnRuGVnSc | hamzanamira | Hamza Namira | La3allo Khair | Arabic | general | unknown |
| nY-19pWQJZ8 | awakeningrecords | Raef | Alhamdu Lillah (Official) | English | general | unknown |
| Hzs9DhbNHCs | awakeningrecords | Raef | Home (Official Music Video) | English | general | unknown |
| dudp60j-0go | SafeAdam | Safe Adam | Hasbi Rabbi (Vocals and Duff Drum) | English | general | duff |
| syV0YLR1tBI | samiyusuf | Sami Yusuf | Mawlana | Arabic | general | unknown |
| s67mDKwkRzU | topic:UC1QTP0OjM0qoPl2uLocqjbQ | Sami Yusuf | Al-Mu'allim | Arabic | mawlid | unknown |
| b0kLCJGx6AM | topic:UC1QTP0OjM0qoPl2uLocqjbQ | Sami Yusuf | Asma Allah (Live in Concert) | Arabic | general | unknown |
| Dr1mJ_O2rGI | ZainBhikhaKids | Zain Bhikha | Welcome O Ramadaan | English | ramadan | unknown |
| TcRrmB1M7R4 | topic:UCsGpBT-UElHMy7s4utUmuow | Zain Bhikha | Allah Made Everything | English | kids | unknown |
| s3_rwqa6-CA | OneIslamProductions | Zaky (One Islam Productions) | Months in Islam | English | kids | unknown |
| LcAgsSBJDSc | awakeningrecords | Irfan Makki | Waiting For The Call (Live at the London Apollo) | English | general | music |
| rpRxU8_vb08 | awakeningrecords | Irfan Makki | Waiting For The Call (Official Lyric Video) | English | general | unknown |
| HRbP9aMDzIc | awakeningrecords | Irfan Makki | Mabrook (Live at the Apollo Theatre) | English | wedding | music |
| Vqfy4ScRXFQ | awakeningrecords | Maher Zain | Ya Nabi Salam Alayka (Arabic, Official Music Video) | Arabic | mawlid | unknown |
| hbMjIlSmyUE | awakeningrecords | Maher Zain | Ramadan (Arabic, Vocals Only) | Arabic | ramadan | vocals |
| VPSc2wskZ6M | MesutKurtis | Mesut Kurtis | Rahmat Al-Rahman | Arabic | general | unknown |
| nRkOuZOLtyM | awakeningrecords | Mesut Kurtis | Hasbi Rabbi (Urdu, Arabic and Turkish) | Arabic | general | unknown |
| uSn79rELJmI | MesutKurtis | Mesut Kurtis | Al-Medina | Arabic | hajj | unknown |
| fiT-WWaH5bc | awakeningrecords | Mesut Kurtis | Astaghfiruallah | Arabic | istighfar | unknown |
| UXwszbfAoiM | MesutKurtis | Mesut Kurtis | Tashawwaqat Rouhi (with Mostafa Atef) | Arabic | general | unknown |
| -QCANdv7p_Y | MesutKurtis | Mesut Kurtis | Hasret Ramadan 2026 (Turkish) | Turkish | ramadan | unknown |
| QfdwuzqOdTc | awakeningrecords | Raef | Ya Allah with Sintesa (Acapella, Vocals Only) | English | general | vocals |
| QMHmLvqE4t8 | awakeningrecords | Raef | Mercy (Official Music Video) | English | general | unknown |
| o2W8_mvLuxU | ahmedbukhatir | Ahmed Bukhatir | Taweel Alshawq | Arabic | general | unknown |
| moZNGtKcOFg | awakeningrecords | Maher Zain | Sepanjang Hidup (Bahasa Version) | Indonesian | wedding | unknown |
| fjZTP3-M_KE | awakeningrecords | Maher Zain | Sepanjang Hidup (Vocals Only) | Indonesian | wedding | vocals |
| 6mRS4SDdyn8 | MaherZain | Maher Zain | Assubhu Bada | Arabic | general | unknown |
| crZinYtSH_w | awakeningrecords | Maher Zain | Love Will Prevail (World Refugee Day) | English | general | unknown |
| eoMJJCVBCgo | awakeningrecords | Maher Zain | Love Will Prevail (Official Music Video) | English | general | unknown |
| h-qK9jYAOrM | MaherZain | Maher Zain | Love Will Prevail | English | general | unknown |
| UxDWvovzCIU | awakeningrecords | Maher Zain | One Day (Vocals Only) | English | general | vocals |
| DHvLp61A-7M | MaherZain | Maher Zain | Muhammad (Pbuh) Waheshna | Arabic | mawlid | unknown |
| XFIzRDfgxq0 | awakeningrecords | Maher Zain | Salla Alayka Rahman | Arabic | mawlid | unknown |
| z2_2cFityc4 | samiyusuf | Sami Yusuf | You Came To Me | English | general | unknown |
| Tug63dI4MEY | samiyusuf | Sami Yusuf | Healing | English | general | unknown |
| -bx8RE1GAgg | samiyusuf | Sami Yusuf | Wherever You Are (Acoustic, Arabic) | Arabic | general | music |
| unG9eb_yCnQ | samiyusuf | Sami Yusuf | You Came To Me (Turkish) | Turkish | general | unknown |
| 4AhhNR6dCpg | nativedeen | Native Deen | Not Afraid to Stand Alone (4K Remastered) | English | general | unknown |
| 1ZpN1ebXgCE | nativedeen | Native Deen with Junaid Jamshed | SubhanAllah | English | general | unknown |
| W7VezcjXNec | nativedeenofficial | Native Deen | Ramadan Is Here | English | ramadan | unknown |
| gkfzYQ3vkaQ | topic:UCmEpZxUSnx6qPpSzoLYluUA | Native Deen | Stand Alone | English | general | unknown |
| tcu8OxbP0NE | topic:UCmEpZxUSnx6qPpSzoLYluUA | Native Deen | Stand Alone (Voice Only) | English | general | vocals |
| NFxovkIuuaA | sieddofficial | Siedd | BarakAllah (Official Nasheed Video, Vocals Only) | English | wedding | vocals |
| BGUNoNPp8zY | OmarEsa | Omar Esa | Dhikr (Lyric Nasheed Video) | English | general | unknown |
| WL5Uf6vsO48 | OmarEsa | Omar Esa | Children of Gaza | English | general | unknown |
| nNKyNetlVoA | OmarEsa | Omar Esa | Death (Vocals Only) | English | general | vocals |
| rZuE0BczNj4 | OmarEsa | Omar Esa | Dhikr 1 (Official Lyric Video) | English | general | unknown |
| hVacrcv7kG4 | OmarEsa | Omar Esa | Allah Hi Allah Kiya Karo (Vocals Only) | Urdu | general | vocals |
| -jHufw0USok | OmarEsa | Omar Esa | Rabb (Vocals Only) | English | general | vocals |
| isYEornaAsg | OmarEsa | Omar Esa | Allah Help Me (Vocals Only) | English | general | vocals |
| okG9YKD3CrE | FunMoKidsTV | FunMo Kids | Eid Song for Kids | English | eid | unknown |
| NAoyiD0uE5E | OSAIslamic | Owais Raza Qadri | Mera Dil Aur Meri Jaan Madine | Urdu | hajj | unknown |
| cae8cw3GNhY | HeeraGoldOfficial | Owais Raza Qadri | Madine Ka Safar Hai (Ramzan Naat) | Urdu | ramadan | unknown |
| OlMz2T3Esy8 | owaisrazaqadriofficial | Owais Raza Qadri | Main Madine Chala | Urdu | hajj | unknown |
| vcsZUL13zu0 | owaisrazaqadriofficial | Owais Raza Qadri | Shehr e Madina | Urdu | general | unknown |
| v6J6OLadVZU | OSAIslamic | Owais Raza Qadri | Madine Ke Wali Do Alam | Urdu | general | unknown |
| Xe2edHVckt0 | OSAIslamic | Owais Raza Qadri | An Nabi Salloo Alae | Urdu | mawlid | unknown |
| OxHt1HmFmUg | Studio5RecordLabel | Hafiz Tahir Qadri | Shehr e Nabi | Urdu | general | unknown |
| 3YC51gfzPiw | HiTechIslamic | Hafiz Tahir Qadri | Ramzan Mubarak Sabko | Urdu | ramadan | unknown |
| -ThDnDCAxz8 | Studio5RecordLabel | Hafiz Tahir Qadri | Bolo Marhaba (Milad Title Naat) | Urdu | mawlid | unknown |
| jJ6Cb3DGd6Y | Studio5RecordLabel | Hafiz Tahir Qadri | Nabi Ka Zikr (Medley Naat) | Urdu | mawlid | unknown |
| mPXMAjWZCgA | Studio5RecordLabel | Hafiz Tahir Qadri | Ramzan Ka Mahina | Urdu | ramadan | unknown |
| eEehJWtaauI | Studio5RecordLabel | Hafiz Tahir Qadri | Dhoom Macha Do Amad Ki | Urdu | mawlid | unknown |
| jjfMwomjpRc | HiTechIslamic | Hafiz Tahir Qadri | Al Nabi Sallu Aleh | Urdu | mawlid | unknown |
| sW1gRGoRXNQ | HafizTahirQadri | Hafiz Tahir Qadri | Sarkar Tawajju Farmain | Urdu | general | unknown |
| QSCMur2gMhE | HiTechIslamic | Hafiz Tahir Qadri | Aaqa Ka Milad Aaya | Urdu | mawlid | unknown |
| a3pnLhiu-V8 | HiTechIslamic | Junaid Jamshed | Muhammad Ka Roza | Urdu | general | unknown |
| a18py61_F_w | cokestudio | Atif Aslam (Coke Studio) | Tajdar-e-Haram | Urdu | general | music |
| H-rkmeHF6UY | Studio5RecordLabel | Khalid Hasnain Khalid | Apni Rehmat Ke Samundar Mein | Urdu | general | unknown |
| 0v8G9KRcFYE | Studio5RecordLabel | Khalid Hasnain Khalid | Madina Madina | Urdu | hajj | unknown |
| WpjgHeL6_zE | Studio5RecordLabel | Khalid Hasnain Khalid | Main Banda e Aasi Hoon (Hajj Kalam) | Urdu | hajj | unknown |
| 3pR8bOeE3TY | MiladRazaQadri | Milad Raza Qadri | Sahar Ka Waqt (Qaseeda Burdah Sharif) | Urdu | mawlid | unknown |
| 0dRS9rhZYwg | MiladRazaQadri | Milad Raza Qadri | Aagaye Mustafa Ki Sawari | Urdu | mawlid | unknown |
| Fr6WEGqzc_s | HafizAhmedRazaQadri | Hafiz Ahmed Raza Qadri | Milad e Mustafa Ka Jashn | Urdu | mawlid | unknown |
| e29VttbbKfg | ARYDigitalasia | Qari Waheed Zafar Qasmi and Syed Fasihuddin Soharwardy | Shan-e-Sehr (Naat Segment) | Urdu | general | unknown |
| QVlsaNW6r6U | ARYQtvofficial | Qari Waheed Zafar Qasmi | Assubhu Badamin Tala'atihi | Arabic | general | unknown |
| _85AFxFKMTQ | HiTechIslamic | Syed Fasihuddin Soharwardi | Mehfil-e-Naat (Official HD Video) | Urdu | general | unknown |
| QGqjWm1EuXw | HiTechIslamic | Rafia Sabri | Bekhud Kiye Dete Hain | Urdu | general | unknown |
| RhMnUDGF7vA | HiTechIslamic | Noor Sisters | Aagaye Rasool Allah | Urdu | mawlid | unknown |
| l3hHUwc1cAk | HiTechIslamic | Junaid Jamshed | Mera Dil Badal De | Urdu | general | unknown |
| xtrkL-jTQPc | HiTechIslamic | Junaid Jamshed | Musaddas e Haali | Urdu | general | unknown |
| 1UdbXqZjrfo | HiTechIslamic | Junaid Jamshed | Yeh Subh-e-Madina | Urdu | general | unknown |
| _g1GfGSxJs0 | HiTechIslamic | Junaid Jamshed | Badee-uz-Zaman (Arabic) | Arabic | general | unknown |
| v0qDogOZhso | HiTechIslamic | Junaid Jamshed | Aei Rasool-e-Amin | Urdu | general | unknown |
| 54amM9aBNGk | HiTechIslamic | Junaid Jamshed | Yaar Rahe Ya Rab Tu Mera | Urdu | general | unknown |
| d1L2ZnbeGos | HiTechIslamic | Junaid Jamshed | Jalwa-e-Janan | Urdu | general | unknown |
| -_E42HQ-Sps | HiTechIslamic | Owais Raza Qadri | Allahumma Salle Alaa | Urdu | general | unknown |
| yjPfcIGv30I | HiTechIslamic | Owais Raza Qadri | Taiba Ke Jane Wale | Urdu | hajj | unknown |
| nlthYAZm3HY | HiTechIslamic | Owais Raza Qadri | Sarkar Ka Madina | Urdu | general | unknown |
| E6YWmJB1cyI | HiTechIslamic | Waris Baig | Ae Khuda | Urdu | general | unknown |
| thTTaLM-CGo | HiTechIslamic | Muhammad Haris Qadri | Yaad Allah Wali | Urdu | general | unknown |
| P24tbogZetU | HiTechIslamic | Alhaj Siddique Ismail | Durood Shareef (Original Recording) | Urdu | general | unknown |
| lqqiTXX5OYI | HiTechIslamic | Gulaab | Hammd Allah Allah | Urdu | general | unknown |
| cfAT9nThJn4 | HiTechIslamic | Ghulam Mustafa Qadri | Mein Banda e Aasi Hoon | Urdu | hajj | unknown |
| m5lp6sNGaUw | HiTechIslamic | Ghulam Mustafa Qadri | Hasbi Rabbi | Urdu | general | unknown |
| bQwZKtxugR4 | HiTechIslamic | Muhammad Jahanzaib Qadri | Zulfan Madni Diyan | Punjabi | general | unknown |
| 1WEnrG0M9UM | HiTechIslamic | Hi-Tech Islamic | Hasbi Rabbi Jallallah (Tere Sadqe Mein Aaqa) | Urdu | general | unknown |
| uUdsY1eFytI | HiTechIslamic | Syed Fasihuddin Soharwardi | Sari Duniya Mein Mein Har Ek | Urdu | general | unknown |
| T1bnRJFNjic | HeeraGoldOfficial | Usaid Zahid Siddique | Assubhu Bada | Arabic | general | unknown |
| RQOOSOhmuKc | HeeraGoldOfficial | Owais Raza Qadri | Unki Mehak Ne Dil Ke | Urdu | general | unknown |
| AWxhvjbzG-c | owaisrazaqadriofficial | Owais Raza Qadri | Lutf Unka | Urdu | general | unknown |
| Jol1PfH3fpU | owaisrazaqadriofficial | Owais Raza Qadri | Haqeeqat Mein Woh Lutfe Zindagi | Urdu | general | unknown |
| ktWsWUoPltc | owaisrazaqadriofficial | Owais Raza Qadri | Huzoor Aisa Koi Intezam Ho Jaye | Urdu | general | unknown |
| ixNInP2dIhA | Studio5RecordLabel | Imran Shaikh Attari | Kalam e Bahoo | Punjabi | general | unknown |
| 5PQ1C41VJuI | Studio5RecordLabel | Imran Shaikh Attari | Tere Qurban Pyare Muhammad | Urdu | general | unknown |
| rZa2LIm92Co | OSAIslamic | Qari Waheed Zafar Qasmi | Jahan Rozae Paake Kherul Wara Hai | Urdu | general | unknown |
| 6FPFWiEffyc | OSAIslamic | Qari Waheed Zafar Qasmi | Zahe Muqaddar Huzoor e Haq Se | Urdu | general | unknown |
| -t_Kl8jyJ5k | topic:UCAkQeNJ-ZngaIQ-x5ioQmiw | Alhaj Khursheed Ahmed | Taiba Ki Hai Yaad Ayi | Urdu | general | unknown |
| AlBsjftfj2A | HiTechIslamic | Shakeel Ashraf | Shah e Madina | Urdu | hajj | unknown |
| ZY4Cb6J8JiM | HiTechIslamic | Shakeel Ashraf | Sadh Le Madine Menu | Punjabi | hajj | unknown |
| yuiFhxPINgw | HiTechIslamic | Hafiz Ahmed Raza Qadri | Salle Alaa | Urdu | general | unknown |
| BiCBEpVlops | HiTechIslamic | Hafiz Ahmed Raza Qadri | Azaan | Urdu | general | unknown |
| vg0GG-4Dh1Y | HiTechIslamic | Hafiz Ahmed Raza Qadri | Aaqa Ka Jashan Manao | Urdu | mawlid | unknown |
| zTczMw6evpg | HiTechIslamic | Hafiz Ahmed Raza Qadri | Jaga Jee Lagane Ki | Urdu | general | unknown |
| mgvDXz1kr1g | HiTechIslamic | Hafiz Ahmed Raza Qadri | Ham Madine Say Allah | Urdu | hajj | unknown |
| RaJi2sy2dxk | HiTechIslamic | Hafiz Ahmed Raza Qadri | Sadey Wal Sohniya | Punjabi | general | unknown |
| W_pkteqpAeg | HiTechIslamic | Qari Shahid Mehmood Qadri | Darood-e-Taaj | Arabic | general | unknown |
| t2x9M7t9iI4 | HiTechIslamic | Qari Shahid Mehmood Qadri | English Naat | English | general | unknown |
| Eavf_y8y7Zw | HiTechIslamic | Syed Fasihuddin Soharwardi | Live in Mehfil | Urdu | general | unknown |
| PP030FkHI7Q | HiTechIslamic | Syed Fasihuddin Soharwardi | Darbar Alag Tera | Punjabi | general | unknown |
| VC4cgSrlTVE | HiTechIslamic | Ishrat Ali | Mangtay Khali Haath | Punjabi | general | unknown |
| z6mK97N_wLE | HiTechIslamic | Qari Shahid Mehmood Qadri | Live in Mehfil | Urdu | general | unknown |
| nhzqHm-rStM | HiTechIslamic | Qari Shahid Mehmood Qadri | Jore Hasnain De | Punjabi | general | unknown |
| 79L4nPAbWnA | HiTechIslamic | Qari Shahid Mehmood Qadri | Maa Diyan Duawawan | Punjabi | general | unknown |
| k8HnEimUfSM | HiTechIslamic | Qari Shahid Mehmood Qadri | Allah Hu Allah | Urdu | general | unknown |
| CUPY_aeR9C8 | HiTechIslamic | Javeria Saleem | Qaseeda Burda Sharif | Arabic | mawlid | unknown |
| VmHTIx7F2Uc | HiTechIslamic | Aqsa Abdul Haq | Qaseeda Burda Sharif | Arabic | mawlid | unknown |
| S5DYqgziETY | HiTechIslamic | Owais Raza Qadri | Salam | Urdu | mawlid | unknown |
| 05Qepv2okf8 | HiTechIslamic | Hassan Sheikh | Shakkar Wanda | Punjabi | general | unknown |
| v6ilQzvv6O0 | HiTechIslamic | Shakeel Ashraf | Dar E Sarkar | Urdu | general | unknown |

## Rejected or skipped candidates (86 lines)

| Video ID(s) | Channel | Reason |
|---|---|---|
| QLPvZ6LordQ | husaintayyeb5783 | re-upload (Sami Yusuf Hasbi Rabbi) |
| 2p0ovdIQ914 | muslimnaat | re-upload (Native Deen M.U.S.L.I.M) |
| NN9HXpk5nB8 | - | oembed not fetched |
| CWDmEYyLPno | AwakenMusic-e8l | "Soul Music" channel, not Awakening |
| gfKpHnTnZ-E | Canary-Aub | re-upload |
| 0m0t4-_FJ-A | syazmanrecords8134 | re-upload (Syazman Records) |
| Vbizz3yl1Do | awakeningrecords | full album upload, not a single track |
| HZpjfuwPECA | ArabicRecordsOfficial | re-upload channel |
| L_5ILZBM2A4 | MaherZain.Family | fan/family channel, not the official one |
| fZsp1p59HSw | SintesaOfficial | third-party channel |
| ULvWOu8lUA8 | Halalmodewallah | edit/re-upload channel |
| THKGB_cUgN4 | username.f | fan re-upload |
| 3F73NB0kx14 | SYAFLAN-ID | third-party cover/re-upload |
| qmGclMvYTuo | MaherZain.Family | not the official channel |
| KK5GOFKb7FI | - | oembed not fetched |
| 812dQFKwa9s | awakeningrecords | official but song language not verifiable from title; skipped |
| fzmH0qS6iNo | nasyidcloud | re-upload |
| IWvAcw6tYVU | NoMusicMedia | third-party edit |
| WVsLv8ys_DA | ZainMusic | uncertain channel |
| 1JKWorYZZHY | ZainMusic? | uncertain channel |
| 2t3_ylqbQ5E | nasheedstar | re-upload channel |
| cqtsaj6_w-I | nasheedstar | re-upload channel |
| 1PNhiHxtuKQ | lanknob | re-upload |
| lPOOQKwavrA | lyricsmusique8868 | lyrics re-upload |
| fJld1iuxbuQ | SiyamSajnanChowdhury | cover |
| pXasHiAniEs | WildNature | re-upload |
| huUYFo41doM | MesutKurtis | official but duplicate of Ya Ramadan already added |
| HQzA2_9eCo0,DFsmKRjXasQ | awakeningrecords | full-album / promo, not a track |
| ed2Mc5VXZKU,aexS1iZmHwk,3rkeqFw9OBA | various | full concert/album uploads, not single tracks |
| 3ZPSUUvV6WM | phantasiaimagination5570 | re-upload |
| coPGtu0EXWA | Lyroverseofficial | re-upload |
| -9KzXxeEEIE | MaherZain | compilation video, not a single track |
| _PlHjuh8Ed8,o2ydWXXSXCM | NasheedWithoutMusic. | re-upload channel |
| ivrumxRUz_Y | nasheedvocals | re-upload |
| 68EnpNATRi0 | nasheedstar | re-upload |
| a_EZQXItiqA | nabil___004 | re-upload |
| _cNSEbiABQw,r4VMATchzjs | AbAlMamun | re-upload |
| vh-nPuIJnrQ | mausiqi_plus | re-upload |
| oUsZo2AdzQw | Abbas.786 | re-upload |
| 0wrgOXdjbzA | elbarakadounia | re-upload |
| sQ5r73LhP2I | samhaqq | re-upload |
| zuhnMyr0_Vg | MaherZain.Family | not official channel |
| gABuMtDGyIs | imschanel-video | re-upload |
| WOZqs1Pqbg8 | TaufikIlyasahNadaHati | cover |
| JV_hkjHLiRI | SYAFLAN-ID | re-upload |
| J1N_95KnSww | ahmedboga94 | re-upload |
| 6hZzH-96QHc,KK5GOFKb7FI,G1G5MS7cFTE | - | oembed not fetched (embedding disabled or removed) |
| BiGVVAP3KsQ | awakeningrecords | official but duplicate of Waheshna already added |
| bJjfKT-cTMg | awakeningrecords | AFC Asian Cup football song, not a nasheed |
| McNOK-4Cy7o,J9IXs9qOUL4 | dazestudios | channel could not be confirmed as Native Deen's own |
| nHXah1XCr64 | HiTechIslamic | label channel, duplicate song; skipped |
| BcjV89_dShc | DEENTV | third party |
| o0UFGQV22rw | inspiritingreminders | re-upload |
| CzSSUplQTHs | asifsomy | re-upload |
| qHkV9T9qJqA | BritIslam | not artist channel |
| OlFHe8NLGQo | Halalmusicstudio | channel could not be confirmed |
| TzvnQK_pkl4 | salahuddinsakibartist | not in scope |
| s6kE_uP3xH4 | HeeraGoldOfficial | official-label upload but duplicate song already added |
| hSJ-QC2NUGs | Samaatv | broadcaster clip, not the artist/label |
| GnijGCqEbgk | Qalb-e-Abdeen | re-upload |
| JW0KIBsBeoI | IslamZindaabad | re-upload |
| hCnf8PD_GJE,ySbuZIi0d2Q | - | oembed not fetched |
| ylbvtvRt5Zw | topic | duplicate of Tajdar-e-Haram already added |
| 1tSav9c-YtE | MeemProduction | manqabat, channel unconfirmed |
| qVHcb_lL9yg | URQProductionOfficial | channel could not be confirmed |
| 7rT9XfqHTZw | oldisgoldnaatein | re-upload |
| cuvi8SLCUBg | QaviKhanBuzdar | re-upload |
| BWKIcxfJfyU | HiTechIslamic | artist not stated in title |
| NrUOgLcRP50 | Hi-TechIslamicGold | channel could not be confirmed |
| Q7uiGV2Zbr8 | HiTechIslamic | compilation |
| 2gXOg0M-Xfk | HiTechIslamic | official but language/theme of 'Bold and Brave' not verifiable from title; skipped |
| HlgdHgw7Tls,ZhVnDFChpRs,dU1MaomGLT4 | HiTechIslamic | manqabat (Ali/Hussain) - out of scope for the nasheed catalogue; skipped |
| 3DsSlSEeIBg | AlFaisalProduction | channel could not be confirmed |
| GmH12-uMBVY | naathub779 | re-upload channel |
| sUJciFuyDqo,mwr_q9zvfno,_JkzhCk2YhE | - | oembed not fetched |
| dG3x4j9eMcs | ARYQtvofficial | duplicate of Zahe Muqaddar already added |
| ygGq8jBJtR0 | GTVNewsHD | TV re-broadcast |
| vMz1ut5uyzg | aplusentertainmenttv | TV re-broadcast |
| MY6fD8fKsSw | SyedFarhanAliWaris | noha, out of scope |
| -QHUczPwzdQ,QjOkXgKT6Ok | FarhanAliWaris-y4g | unofficial channel |
| PMaKA7gLbxE,Hcd3wupEN64 | HassanBinKhurshid | family channel, not confirmed official |
| bPGbGPrkKao,q3_oA3dQrT8 | GreenEntertainmentTV | TV re-broadcast |
| WeNvk3QG4bQ | BOLNetworkOfficial | TV re-broadcast |
| aWiU2IQgw2Q | HiTechIslamic | title names only the artist, no track title |
| juYMlMMSeLs | - | not fetched (weekly limit reached on fetch tool) |
| vhjuPl94VU0 | Hi-TechIslamicGold | channel could not be confirmed |

## Not yet verified (no fetch possible)

Candidate IDs found by search but never fetched: `g5i9EGt5XLM`, `2GhLa03R9jQ`, `q_Mb5O1tqqQ`, `3EGtAKyaozQ`, `arf8jOJJSFo`, `2N-XQnLqTls`, `Dz72ATi_baA`, `NmBhuXezeeA`, `r7qJufrRVMc`, `JByVTp8t17A`, `l3WmFrQG_TA`, `P9nzEHBVlvQ`, `oodchZT4d6w`, `m81jvJ1Ezkw`, `shZMxcIFGqA`, `rMbXgvGcYGw`, `7iBcXuLwr1g`. They are NOT in the pack. Not attempted at all: Sabyan, Haddad Alwi, Opick, Raihan, Bangla reciters, Dawud Wharnsby, Zain Bhikha main channel, Muhammad al Muqit (no official channel found), Deen Squad, Baraka Blue. To add more: put fetched rows in verified.tsv, run the build script, paste the digest into `kVerifiedCatalogSha256`.
