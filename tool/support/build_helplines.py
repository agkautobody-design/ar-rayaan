#!/usr/bin/env python3
"""Builds assets/support/helplines.json from the table below.

Every row in VERIFIED was read on an operator or official page on 2026-10-27
(the `source` URL). Anything not confirmed on a page we could read goes in
TO_VERIFY and is NOT in the display list. Numbers are never typed into
snippet text; the app joins them by country and scope.

Run:  python3 tool/support/build_helplines.py [--check]
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'assets', 'support', 'helplines.json')
ON = '2026-10-27'
E = ['en']
SC = ['suicide', 'addiction', 'domestic-abuse', 'child', 'sexual-violence', 'general', 'emergency',
      'smoking', 'gambling', 'elder', 'eating', 'poison', 'muslim']

V = []   # verified rows
T = []   # to verify rows


def v(cid, country, service, number, scope, hours, src, lang=None, text=None, url=None, aud='adult', note=None):
    V.append(dict(id=cid, country=country, service=service, number=number, text=text, url=url, hours=hours,
                  scope=scope, language=lang or E, audience=aud, verifiedOn=ON, source=src, status='verified', notes=note))


def t(cid, country, service, number, scope, why, src=None, lang=None, aud='adult'):
    T.append(dict(id=cid, country=country, service=service, number=number, text=None, url=None, hours=None,
                  scope=scope, language=lang or E, audience=aud, verifiedOn=None, source=src, status='unverified', notes=why))


# ---------------------------------------------------------------- US
v('us-988', 'US', '988 Suicide & Crisis Lifeline', '988', ['suicide', 'general'], None, 'https://988lifeline.org/get-help/',
  ['en', 'es'], text='Text 988', note='Hours not stated on the get-help page. Chat at chat.988lifeline.org.')
v('us-ctl', 'US', 'Crisis Text Line', None, ['suicide', 'general'], '24/7', 'https://www.crisistextline.org/text-us/', ['en', 'es'], text='Text HOME to 741741')
v('us-ndvh', 'US', 'National Domestic Violence Hotline', '1-800-799-7233', ['domestic-abuse'], None, 'https://www.thehotline.org/search/sms:88788',
  text='Text START to 88788', note='Hours not stated on the fetched page.')
v('us-rainn', 'US', 'RAINN National Sexual Assault Hotline', '1-800-656-4673', ['sexual-violence'], '24/7', 'https://rainn.org/learn-about-rainn/contact-us/', ['en', 'es'], text='Text HOPE to 64673')
v('us-childhelp', 'US', 'Childhelp National Child Abuse Hotline', '1-800-422-4453', ['child'], None, 'https://www.childhelphotline.org/', ['en', 'es'], text='Text GO to 800-422-4453',
  aud='child-or-adult-concerned', note='Not a reporting line and not connected to 911. Hours not stated.')
v('us-samhsa', 'US', 'SAMHSA National Helpline', '1-800-662-4357', ['addiction', 'general'], '24/7', 'https://www.samhsa.gov/find-help/helplines/national-helpline', ['en', 'es'], note='Treatment referral and information, not a crisis line.')
v('us-poison', 'US', 'Poison Help', '1-800-222-1222', ['poison', 'emergency'], '24/7', 'https://www.poison.org/need-immediate-assistance')
v('us-gambling', 'US', 'National Problem Gambling Helpline', '1-800-697-3738', ['gambling'], '24/7', 'https://www.ncpgambling.org/help-treatment/about-the-national-problem-gambling-helpline/',
  text='Text 1-800-MY-RESET', note='The older 1-800-GAMBLER is not on the operator page; use 1-800-MY-RESET.')
v('us-quit', 'US', '1-800-QUIT-NOW', '1-800-784-8669', ['smoking'], None, 'https://www.cdc.gov/tobacco/hcp/patient-care/quitlines-and-other-resources.html',
  text='Text QUITNOW to 333888 (texting portal)', note='Hours not stated; may offer a call-back at busy times.')
v('us-eldercare', 'US', 'Eldercare Locator', '1-800-677-1116', ['elder'], None, 'https://eldercare.acl.gov/home',
  note='Finds local services for older adults. The page does not call it an abuse line.')
v('us-911', 'US', 'Emergency services', '911', ['emergency'], '24/7', 'https://www.911.gov/calling-911/')
# ---------------------------------------------------------------- Canada
v('ca-988', 'CA', '9-8-8 Suicide Crisis Helpline', '9-8-8', ['suicide', 'general'], '24/7', 'https://988.ca/get-help/what-to-expect', ['en', 'fr'], text='Text 9-8-8')
v('ca-khp', 'CA', 'Kids Help Phone', '1-800-668-6868', ['child', 'suicide', 'general'], '24/7 phone and text', 'https://kidshelpphone.ca/urgent-help',
  ['en', 'multiple'], text='Text CONNECT to 686868', aud='child', note='Page contradicts itself on live-chat hours; chat not relied on.')
v('ca-naseeha', 'CA', 'Naseeha Muslim Youth Helpline', '1-866-627-3342', ['muslim', 'suicide', 'general'], '24/7', 'https://www.naseeha.org/helpline-textline',
  ['en', 'fr', 'ar', 'ur', 'hi', 'pa', 'bn', 'gu'], note='Page names no countries served; based in Ontario.')
# ---------------------------------------------------------------- UK
v('gb-samaritans', 'GB', 'Samaritans', '116 123', ['suicide', 'general'], '24/7', 'https://www.samaritans.org/how-we-can-help/contact-samaritan/talk-us-phone/')
v('gb-shout', 'GB', 'Shout', None, ['suicide', 'general'], '24/7', 'https://giveusashout.org/get-help/', text='Text SHOUT to 85258')
v('gb-myh', 'GB', 'Muslim Youth Helpline', '0808 808 2008', ['muslim', 'general', 'suicide'], '16:00-22:00 daily', 'https://myh.org.uk/how-we-can-help/call-us/')
v('gb-ndah', 'GB', 'National Domestic Abuse Helpline (Refuge)', '0808 2000 247', ['domestic-abuse'], '24/7', 'https://refuge.org.uk/i-need-help-now/how-we-can-help-you/national-domestic-abuse-helpline/', note='Page names no country scope; London-based, serves the UK.')
v('gb-mwn', 'GB', 'Muslim Women\'s Network UK helpline', '0800 999 5786', ['domestic-abuse', 'muslim', 'general'], None, 'https://www.mwnuk.co.uk/contact-mwnuk', note='Hours and eligibility not stated on the page.')
v('gb-karma', 'GB', 'Karma Nirvana (honour-based abuse)', '0800 5999 247', ['domestic-abuse'], 'Mon-Fri 09:00-17:00', 'https://karmanirvana.org.uk/get-help/helpline/', note='For emergencies call 999.')
v('gb-rapecrisis', 'GB', 'Rape Crisis England & Wales support line', '0808 500 2222', ['sexual-violence'], '24/7', 'https://rapecrisis.org.uk/get-help/want-to-talk/', note='Ages 16+, England and Wales. Page metadata shows one digit fewer; body text used.')
v('gb-childline', 'GB', 'Childline', '0800 1111', ['child'], '24/7', 'https://www.childline.org.uk/get-support/contacting-childline/', aud='child', note='UK, Channel Islands only.')
v('gb-nspcc', 'GB', 'NSPCC Helpline (adults worried about a child)', '0808 800 5000', ['child'], 'Mon-Fri 10:00-16:00', 'https://www.nspcc.org.uk/about-us/our-services/nspcc-helpline/', aud='adult-concerned')
v('gb-frank', 'GB', 'FRANK (drugs)', '0300 123 6600', ['addiction'], '24/7', 'https://talktofrank.com/contact-frank', text='Text 82111')
v('gb-drinkline', 'GB', 'Drinkline', '0300 123 1110', ['addiction'], 'Weekdays 09:00-20:00, weekends 11:00-16:00', 'https://www.nhs.uk/live-well/alcohol-advice/alcohol-support/')
v('gb-nacoa', 'GB', 'Nacoa (children of alcohol-dependent parents)', '0800 358 3456', ['addiction', 'child'], None, 'https://www.nhs.uk/live-well/alcohol-advice/alcohol-support/', aud='child-or-adult-concerned')
v('gb-gamcare', 'GB', 'GamCare / National Gambling Treatment Service', '0808 80 20 133', ['gambling'], '24/7', 'https://www.gamcare.org.uk/get-support/')
v('gb-smoke-eng', 'GB', 'Smokefree National Helpline (England)', '0300 123 1044', ['smoking'], None, 'https://www.nhs.uk/live-well/quit-smoking/nhs-stop-smoking-services-help-you-quit/')
v('gb-smoke-sco', 'GB', 'Quit Your Way Scotland', '0800 84 84 84', ['smoking'], None, 'https://www.nhs.uk/live-well/quit-smoking/nhs-stop-smoking-services-help-you-quit/')
v('gb-smoke-wal', 'GB', 'Help Me Quit (Wales)', '0800 085 2219', ['smoking'], None, 'https://www.nhs.uk/live-well/quit-smoking/nhs-stop-smoking-services-help-you-quit/')
v('gb-999', 'GB', 'Emergency services', '999', ['emergency'], '24/7', 'https://www.londonambulance.nhs.uk/our-services/emergency-care/calling-999/', note='Page says when to call; does not state hours or cost.')
# ---------------------------------------------------------------- Ireland
v('ie-samaritans', 'IE', 'Samaritans', '116 123', ['suicide', 'general'], '24/7', 'https://www.samaritans.org/ireland/how-we-can-help/contact-samaritan/', note='Page does not say the call is free from Ireland specifically.')
v('ie-pieta', 'IE', 'Pieta', '1800 247 247', ['suicide', 'general'], '24/7', 'https://www.pieta.ie/how-we-can-help/helpline/', text='Text HELP to 51444')
v('ie-hse-drugs', 'IE', 'HSE Drugs and Alcohol Helpline', '1800 459 459', ['addiction'], 'Mon-Fri 09:30-17:30', 'https://www2.hse.ie/services/habit-addiction/drugs-and-alcohol-helpline/')
v('ie-childline', 'IE', 'Childline (ISPCC)', '1800 66 66 66', ['child'], '24/7', 'https://www.childline.ie/about-us', aud='child')
v('ie-womensaid', 'IE', 'Women\'s Aid National Freephone Helpline', '1800 341 900', ['domestic-abuse'], '24/7', 'https://www.womensaid.ie/about-us/contact-us/')
v('ie-drcc', 'IE', 'Dublin Rape Crisis Centre National Helpline', '1800 77 8888', ['sexual-violence'], '24/7', 'https://www.drcc.ie/services/helpline/')
v('ie-quit', 'IE', 'HSE Quit Team', '1800 201 203', ['smoking'], 'Mon-Wed 10-20 (Wed to 19), Thu 10-19, Fri 10-17, Sat 10-14', 'https://www2.hse.ie/living-well/quit-smoking/contact/')
v('ie-alone', 'IE', 'ALONE support line (older people)', '0818 222 024', ['elder'], 'Daily 08:00-20:00', 'https://alone.ie/referral-information/')
v('ie-112', 'IE', 'Emergency services', '112 or 999', ['emergency'], None, 'https://www.gov.ie/en/department-of-the-taoiseach/services/how-to-contact-emergency-services-in-ireland/', note='Both free; hours not stated on the page.')
# ---------------------------------------------------------------- Australia
v('au-lifeline', 'AU', 'Lifeline', '13 11 14', ['suicide', 'general'], '24/7', 'https://www.lifeline.org.au/get-help/national-services/lifeline-crisis-support', text='Text 0477 13 11 14', note='English; interpreters via 13 14 50.')
v('au-1800respect', 'AU', '1800RESPECT', '1800 737 732', ['domestic-abuse', 'sexual-violence'], '24/7', 'https://1800respect.org.au/calling-1800respect', text='Text 0458 737 732')
v('au-kids', 'AU', 'Kids Helpline', '1800 55 1800', ['child'], '24/7', 'https://www.kidshelpline.com.au/get-help/phone-counselling/', aud='child', note='Ages 5-25 per health.gov.au.')
v('au-nadh', 'AU', 'National Alcohol and Other Drug Hotline', '1800 250 015', ['addiction'], None, 'https://www.health.gov.au/our-work/drug-help/how-to-find-help', note='Hours not stated on the fetched page.')
v('au-fds', 'AU', 'Family Drug Support', '1300 368 186', ['addiction'], '24/7', 'https://www.health.gov.au/our-work/drug-help/how-to-find-help', note='For families.')
v('au-quit', 'AU', 'Quitline', '13 7848', ['smoking'], 'Varies by state; mostly Mon-Fri 08:00-20:00', 'https://www.quit.org.au/en/support-and-resources/ways-to-get-in-touch')
v('au-elder', 'AU', '1800 ELDERHelp', '1800 353 374', ['elder'], 'Varies by state', 'https://www.health.gov.au/contacts/elder-abuse-phone-line', note='Routes to the state service; not a crisis line.')
v('au-000', 'AU', 'Triple Zero', '000', ['emergency'], '24/7', 'https://www.triplezero.gov.au/triple-zero/How-to-Call-000', note='Text-based service 106 for speech or hearing difficulty.')
# ---------------------------------------------------------------- NZ
v('nz-1737', 'NZ', '1737 Need to talk?', '1737', ['suicide', 'general'], '24/7', 'https://www.1737.org.nz/how-1737-works', text='Text 1737', note='Not a crisis team; call 111 in danger.')
v('nz-lifeline', 'NZ', 'Lifeline Aotearoa', '0800 543 354', ['general', 'suicide'], '07:00-24:00', 'https://mentalhealth.org.nz/get-help-support/helplines-support/', text='Text 4357')
v('nz-samaritans', 'NZ', 'Samaritans NZ', '0800 726 666', ['general', 'suicide'], '24/7', 'https://mentalhealth.org.nz/get-help-support/helplines-support/')
v('nz-depression', 'NZ', 'Depression Helpline', '0800 111 757', ['general'], '24/7', 'https://mentalhealth.org.nz/get-help-support/helplines-support/', text='Text 4202')
v('nz-youthline', 'NZ', 'Youthline', '0800 37 66 33', ['child', 'general', 'suicide'], '24/7', 'https://youthline.co.nz/get-help/helpline/', text='Text 234', aud='child')
v('nz-adh', 'NZ', 'Alcohol Drug Helpline', '0800 787 797', ['addiction'], '24/7', 'https://alcoholdrughelp.org.nz/')
v('nz-gambling', 'NZ', 'Gambling Helpline', '0800 654 655', ['gambling'], '24/7', 'https://gamblinghelpline.co.nz/contact', text='Text 8006')
v('nz-quit', 'NZ', 'Quitline', '0800 778 778', ['smoking'], None, 'https://quit.org.nz/')
v('nz-refuge', 'NZ', 'Women\'s Refuge', '0800 733 843', ['domestic-abuse'], '24/7', 'https://womensrefuge.org.nz/get-help/')
v('nz-safetotalk', 'NZ', 'Safe to talk (sexual harm)', '0800 044 334', ['sexual-violence'], '24/7', 'https://www.safetotalk.nz/contact-us/', text='Text 4334')
v('nz-111', 'NZ', 'Emergency services', '111', ['emergency'], '24/7', 'https://www.govt.nz/browse/law-crime-and-justice/crimes-and-emergencies/111-emergency-service/', note='Cost and hours not stated on the page.')
# ---------------------------------------------------------------- Saudi Arabia
v('ca-gbv-provincial', 'CA', 'Find your province or territory\u2019s crisis line for gender-based violence', None, ['domestic-abuse', 'sexual-violence'], None, 'https://www.canada.ca/en/women-gender-equality/gender-based-violence/get-help-now.html', ['en', 'fr'], text='Open the Government of Canada list', url='https://www.canada.ca/en/women-gender-equality/gender-based-violence/get-help-now.html', aud='adult-or-concerned', note='Canada has no single national line for this. The Government of Canada page lists the provincial and territorial lines and says to call 911 in an emergency (read 2026-10-27).')
v('sa-937', 'SA', 'Ministry of Health 937 (health information line)', '937', ['general'], '24/7 for medical consultations', 'https://www.moh.gov.sa/Ministry/MediaCenter/Ads/Documents/937%20BOOKLET-V2.pdf',
  ['ar'], note='Health information and consultation. The booklet does not mention mental-health counselling: do not present as a suicide or crisis line.')
v('sa-1919', 'SA', 'Domestic Violence Reporting Centre', '1919', ['domestic-abuse', 'child', 'elder'], None, 'https://www.hrsd.gov.sa/en/ministry-services/services/%D8%A7%D9%84%D8%A5%D8%A8%D9%84%D8%A7%D8%BA-%D8%B9%D9%86-%D8%A7%D9%84%D8%B9%D9%86%D9%81-%D8%A7%D9%84%D8%A3%D8%B3%D8%B1%D9%8A',
  ['ar', 'en'], aud='adult-or-concerned', note='For citizens and residents; third-party reports allowed. Hours not stated on the page.')
# ---------------------------------------------------------------- UAE
v('ae-999', 'AE', 'Police', '999', ['emergency'], '24/7', 'https://u.ae/en/information-and-services/justice-safety-and-the-law/Safety/handling-emergencies')
v('ae-998', 'AE', 'Ambulance', '998', ['emergency'], '24/7', 'https://u.ae/en/information-and-services/justice-safety-and-the-law/Safety/handling-emergencies')
v('ae-997', 'AE', 'Fire / Civil Defence', '997', ['emergency'], '24/7', 'https://u.ae/en/information-and-services/justice-safety-and-the-law/Safety/handling-emergencies')
# ---------------------------------------------------------------- Qatar
v('qa-mh', 'QA', 'National Mental Health Helpline (HMC)', '16000 then option 4', ['suicide', 'general'], None, 'https://www.hamad.qa/EN/news/2025/April/Pages/National-Mental-Health-Helpline-Celebrates-Milestone-in-Providing-Specialized-Support-Across-Qatar.aspx',
  ['ar', 'en', 'tl', 'hi', 'ur', 'ml'], note='Hours not stated on the page.')
v('qa-aman', 'QA', 'Aman Centre hotline', '919', ['domestic-abuse', 'child', 'elder'], '24/7', 'https://www.aman.org.qa/en/faq', ['multiple'], aud='adult-or-concerned', note='Eligibility not stated; services open to all citizens and residents.')
v('qa-999', 'QA', 'Emergency services', '999', ['emergency'], '24/7', 'https://portal.moi.gov.qa/UNCCPCJDoha/English/Emergency_Services.html', note='992 is the service for deaf people.')
# ---------------------------------------------------------------- Malaysia
v('my-befrienders', 'MY', 'Befrienders Kuala Lumpur', '+603-7627 2929', ['suicide', 'general'], '24/7', 'https://www.befrienders.org.my/contact', note='Phone only; no chat; does not do crisis support by DM.')
v('my-kasih', 'MY', 'Talian Kasih', '15999', ['domestic-abuse', 'child', 'elder'], '24/7', 'https://www.malaysia.gov.my/en/topics/talian-kasih-15999', text='WhatsApp 019-261 5999', aud='adult-or-concerned')
v('my-999', 'MY', 'Emergency services (MERS 999)', '999', ['emergency'], '24/7', 'https://www.malaysia.gov.my/en/categories/safety-and-community/public-safety/mers-999-emergency-line')
# ---------------------------------------------------------------- Indonesia
v('id-healing119', 'ID', 'Healing119.id (Ministry of Health)', '119 then extension 8', ['suicide', 'general'], 'Morning to night (exact hours not stated)', 'https://kesprimkom.kemkes.go.id/konten/158/151/0/cegah-bunuh-diri-dukung-kesehatan-jiwa-kenali-layanan-healing119-id', ['id'], note='Free; WhatsApp chat via the website.')
v('id-129', 'ID', 'SAPA 129 (women and children)', '129', ['domestic-abuse', 'child', 'sexual-violence'], None, 'https://laporsapa129.kemenpppa.go.id/', ['id'], text='WhatsApp 08-111-129-129', aud='adult-or-concerned', note='Hours not stated.')
v('id-bnn', 'ID', 'BNN Call Center', '184', ['addiction'], '24/7', 'https://bnn.go.id/resmi-diluncurkan-layanan-bnn-call-center-184-siap-terima-laporan-dan-pengaduan/', ['id'], note='Narcotics reports and rehabilitation consultation.')
# ---------------------------------------------------------------- Pakistan
v('pk-rozan', 'PK', 'Rozan Counselling Helpline', '0304-111-1741', ['general', 'child', 'domestic-abuse'], 'Mon-Fri 09:30-17:00 (to 15:00 in Ramadan)', 'https://rozan.org/rozan-counseling-helpline/', note='Toll-free 0800-22-444. Not a 24-hour crisis line.')
v('pk-1099', 'PK', 'Ministry of Human Rights helpline', '1099', ['general', 'domestic-abuse', 'child'], None, 'https://portal.mohr.gov.pk/media_library/helpline-1099/', aud='adult-or-concerned', note='Human-rights complaints. Hours not stated.')
# ---------------------------------------------------------------- Bangladesh
v('bd-999', 'BD', 'National emergency service', '999', ['emergency'], '24/7', 'https://bangladesh.gov.bd/pages/static-pages/69a55ba386514399668e4e89')
v('bd-109', 'BD', 'National Helpline Centre (violence against women and children)', '109', ['domestic-abuse', 'child'], None, 'https://bangladesh.gov.bd/pages/static-pages/69a55ba386514399668e4e89', ['bn'], aud='adult-or-concerned', note='Page text truncated after the purpose line; hours not stated.')
v('bd-kpr', 'BD', 'Kaan Pete Roi', '+880 9612-119911', ['suicide', 'general'], 'Daily 15:00-03:00', 'https://kaanpeteroi.org/helpline-service/', ['bn'], note='Emotional support, not an emergency service.')
# ---------------------------------------------------------------- India
v('in-telemanas', 'IN', 'Tele-MANAS', '14416', ['suicide', 'general'], '24/7', 'https://www.pib.gov.in/PressReleasePage.aspx?PRID=2118790&reg=48&lang=2', ['multiple'], note='20 languages by state.')
v('in-quit', 'IN', 'National Tobacco Quitline', '1800 112 356', ['smoking'], None, 'https://ntcp.mohfw.gov.in/national_tobacco_quit_line_services', ['multiple'], note='Missed call 011-22901701.')
v('in-elderline', 'IN', 'Elderline', '14567', ['elder'], 'Daily 08:00-20:00', 'https://www.pib.gov.in/PressReleasePage.aspx?PRID=2284996&reg=48&lang=2', ['multiple'])
v('in-181', 'IN', 'Women Helpline', '181', ['domestic-abuse', 'sexual-violence'], '24/7', 'https://www.pib.gov.in/PressReleasePage.aspx?PRID=1910101', note='Source is a March 2023 government release.')
v('in-1098', 'IN', 'CHILDLINE', '1098', ['child'], None, 'https://www.childlineindia.org/', aud='child', note='Hours and cost not stated on the page; it points to 112 for immediate danger.')
v('in-112', 'IN', 'Emergency (single number)', '112', ['emergency'], '24/7', 'https://112.gov.in/')
# ---------------------------------------------------------------- Egypt
v('sa-116111', 'SA', 'Child Helpline (National Family Safety Program)', '116111', ['child'], None, 'https://mngha.med.sa/english/MediaCenter/News/Pages/international-child-helpline-day.aspx', ['ar', 'en'], aud='child', note='Government page writes it as 116 111 and names the National Family Safety Program as operator. Hours not stated there.')
v('eg-16000', 'EG', 'Child Rescue Hotline (National Council for Childhood and Motherhood)', '16000', ['child'], None, 'https://www.cairo.gov.eg/en/news/news-eng/2025/9e6d9746382148bea8cc161d0bbda758', ['ar'], aud='child', note='Number and operator read on the Cairo governorate page about NCCM. Hours not stated on that page.')
v('eg-15115', 'EG', 'National Council for Women complaints office hotline', '15115', ['domestic-abuse'], None, 'https://unodc.org/romena/en/Stories/2020/December/egypt_-on-the-other-side-of-the-hotline---interview-with-the-head-of-complaints-office-at-the-national-council-for-women-ncw.html', ['ar'], aud='adult-or-concerned', note='UNODC interview (2020) gives the hotline as 15115 for psychological and legal advice. Hours not stated. Re-check against a National Council for Women page when reachable.')
v('eg-122', 'EG', 'Police emergency (Nagda)', '122', ['emergency'], None, 'https://moi.gov.eg/home/EmergancyNumber', ['ar'], note='Interior Ministry list also gives 180 for civil protection. No ambulance number or 112 on the page.')
# ---------------------------------------------------------------- Turkey
v('tr-183', 'TR', 'ALO 183 Social Support Line', '183', ['domestic-abuse', 'child', 'elder', 'general'], '24/7', 'https://aile.gov.tr/yalova/haberler/alo-183-destek-hatti-ile-bizlere-7-24-ulasabilirsiniz/', ['tr'], aud='adult-or-concerned', note='Free from within Turkey. Page dated 2021.')
v('tr-115', 'TR', 'YEDAM 115 (addiction counselling)', '115', ['addiction'], None, 'https://www.yedam.org.tr/telefon-ile-danismanlik', ['tr'], note='Hours not on the fetched page.')
# ---------------------------------------------------------------- South Africa
v('za-sadag', 'ZA', 'SADAG Suicide Crisis Line', '0800 567 567', ['suicide', 'general'], '24/7', 'https://www.sadag.org/')
v('za-dsd', 'ZA', 'Substance Abuse Line (Dept of Social Development)', '0800 12 13 14', ['addiction'], '24/7', 'https://www.sadag.org/', text='SMS 32312')
v('za-gbv', 'ZA', 'GBV Command Centre', '0800 428 428', ['domestic-abuse', 'sexual-violence'], '24/7', 'https://www.gov.za/about-government/government-call-centres-and-help-lines')
v('za-lifeline', 'ZA', 'LifeLine National Crisis Line', '0861 322 322', ['suicide', 'general'], '24/7', 'https://www.gov.za/about-government/government-call-centres-and-help-lines')
v('za-childline', 'ZA', 'Childline South Africa', '116', ['child'], None, 'https://www.gov.za/about-government/government-call-centres-and-help-lines', aud='child-or-adult-concerned', note='Listed for reporting child abuse; hours not stated.')
# ---------------------------------------------------------------- Nigeria
v('ng-surpin', 'NG', 'SURPIN helpline', '+234-908-021-7555', ['suicide', 'general'], '24/7 (per site)', 'https://www.surpinng.com/', note='Site lists four numbers (+234-903-440-0009, +234-814-224-1007, +234-8000787746); does not say which is toll-free. Non-governmental.')
v('ng-ndlea', 'NG', 'NDLEA hotline', '0800 1020 3040', ['addiction'], None, 'https://ndlea.gov.ng/contact', note='Law-enforcement reporting line for drug activity, not a counselling service. Hours not stated.')
# ---------------------------------------------------------------- International
v('int-findahelpline', 'INT', 'Find A Helpline (ThroughLine)', None, ['suicide', 'general', 'domestic-abuse', 'addiction'], None, 'https://findahelpline.com/', ['multiple'], url='https://findahelpline.com/', note='Free directory covering 175+ countries, by topic. A directory, not a service.')
v('int-befrienders', 'INT', 'Befrienders Worldwide', None, ['suicide', 'general'], None, 'https://befrienders.org/find-support-now/suicide-prevention-services/', ['multiple'], url='https://befrienders.org/find-support-now/suicide-prevention-services/', note='Directory of emotional-support centres by country and language.')
v('int-chi', 'INT', 'Child Helpline International', None, ['child'], None, 'https://childhelplineinternational.org/helplines/', ['multiple'], url='https://childhelplineinternational.org/helplines/', aud='child-or-adult-concerned', note='Directory of national child helplines.')

# ---------------------------------------------------------------- TO VERIFY (not displayed)
t('us-anad', 'US', 'ANAD Eating Disorders Helpline', '1-888-375-7767', ['eating'], 'In the app; not re-confirmed today.')
t('sg-sos', 'SG', 'Samaritans of Singapore', '1767', ['suicide', 'general'], 'In the app; not re-confirmed today.')
t('ca-911', 'CA', 'Emergency services', '911', ['emergency'], 'RCMP page blocked automated reads; not confirmed on an official page.')
t('ca-smokers', 'CA', 'Smokers\' Helpline', None, ['smoking'], 'Operator page returned no content when fetched.', 'https://www.smokershelpline.ca/')
t('gb-mch', 'GB', 'Muslim Community Helpline', '020 8904 8193', ['muslim', 'general'], 'In the app (checked 2026-10-20); not re-confirmed on an operator page today.')
t('gb-beat', 'GB', 'Beat Eating Disorders', '0808 801 0677', ['eating'], 'In the app; not re-confirmed today.')
t('gb-elder', 'GB', 'Action on Elder Abuse helpline', None, ['elder'], 'Operator page blocked automated reads.', 'https://www.elderabuse.org.uk/reporting-options')
t('ie-gambling', 'IE', 'National gambling helpline', None, ['gambling'], 'The only page read was a regional Wexford service, not a national helpline.', 'https://www.gamblingsupport.ie/contact/')
t('au-gho', 'AU', 'Gambling Help Online', '1800 858 858', ['gambling'], 'Operator pages returned an error when fetched.', 'https://www.gamblinghelponline.org.au/immediate-help')
t('au-poison', 'AU', 'Poisons Information Centre', '13 11 26', ['poison'], 'Only the NSW centre page was read; national coverage not confirmed.', 'https://www.poisonsinfo.nsw.gov.au/')
t('au-butterfly', 'AU', 'Butterfly Foundation', '1800 33 4673', ['eating'], 'In the app; not re-confirmed today.')
t('nz-elder', 'NZ', 'Elder Abuse Response Service', None, ['elder'], 'Age Concern page gave no number for it.', 'https://ageconcern.org.nz/get-support/elder-abuse-and-neglect-prevention/')
t('sa-emergency', 'SA', 'Emergency numbers (911, 997, 999)', None, ['emergency'], 'my.gov.sa lists services without digits; numbers not confirmed on an official page.', 'https://my.gov.sa/en/emergency-contact')
t('ae-hope', 'AE', 'National Mental Health Support Line (800 HOPE)', '800 4673', ['suicide', 'general'], 'No official page found; u.ae mental-health page lists no helpline.', 'https://u.ae/en/information-and-services/health-and-fitness/Health-and-wellbeing/mental-health')
t('kw-112', 'KW', 'Emergency services', '112', ['emergency'], 'Official e.gov.kw page returned an error.', 'https://e.gov.kw/sites/kgoenglish/Pages/Visitors/TourismInKuwait/EssintialServicesEmergencies.aspx')
t('kw-mh', 'KW', 'Kuwait mental-health / family lines', None, ['suicide', 'domestic-abuse'], 'No official number found.')
t('id-112', 'ID', 'Emergency services', '112', ['emergency'], 'Official page blocked automated reads.', 'https://layanan112.komdigi.go.id/tentang')
t('pk-umang', 'PK', 'Umang Pakistan', '0311-7786264', ['suicide', 'general'], 'Operator page does not show the number; it describes paid therapy sessions.')
t('pk-emergency', 'PK', 'Rescue 1122 and Police 15', '1122', ['emergency'], 'Official Punjab page blocked automated reads.', 'https://pcsw.punjab.gov.pk/important_helplines')
t('bd-drug', 'BD', 'Department of Narcotics Control', '+880 1908888888', ['addiction'], 'Source page not re-confirmed in this pass.')
t('in-ncb', 'IN', 'NCB MANAS helpline', '14446', ['addiction'], 'Government page showed no number.', 'https://nmba.dosje.gov.in/toll-free')
t('in-telemanas-page', 'IN', 'Tele-MANAS operator site', None, ['suicide'], 'telemanas.mohfw.gov.in blocks automated reads; number confirmed via PIB instead.', 'https://telemanas.mohfw.gov.in/')
t('eg-mh', 'EG', 'Egypt mental-health hotline', None, ['suicide', 'general'], 'Ministry page blocked automated reads.', 'https://nmhp.mohp.gov.eg/mental/web/en', ['ar'])
t('eg-ambulance', 'EG', 'Ambulance 123 / unified 112', '123', ['emergency'], 'Interior Ministry page lists neither; 112 reported only unofficially.', 'https://moi.gov.eg/home/EmergancyNumber', ['ar'])
t('tr-112', 'TR', 'Emergency 112', '112', ['emergency'], 'Both official pages blocked automated reads.', 'https://www.112.gov.tr/', ['tr'])
t('tr-mh', 'TR', 'Turkey crisis / mental-health line', None, ['suicide', 'general'], 'No official suicide-prevention line confirmed.', None, ['tr'])
t('za-emergency', 'ZA', 'Emergency 10111 / 10177 / 112', '10111', ['emergency'], 'Not on the pages read.')
t('ng-112', 'NG', 'Emergency 112', '112', ['emergency'], 'Not read on an official page.')
t('int-iasp', 'INT', 'IASP crisis centres directory', None, ['suicide'], 'Page returned only a redirect notice.', 'https://www.iasp.info/crisis-centres-helplines/')
t('us-nat-elder', 'US', 'National elder abuse hotline', None, ['elder'], 'NCEA page blocked automated reads.', 'https://stg-ncea.acl.gov/Suspect-Abuse/Reporting-Abuse.aspx')


def build():
    return {
        'schema': 1,
        'verifiedOn': ON,
        'about': ('Help lines joined to support snippets by country and scope. Only entries in "helplines" '
                  '(status verified, read on an operator or official page on verifiedOn) may be shown. '
                  '"toVerify" entries were not confirmed and must never be shown. Numbers are never typed into snippet text. '
                  'Child lines (audience child) are kept apart from adult lines. Hours are null where the source did not state them.'),
        'scopes': SC,
        'helplines': V,
        'toVerify': T,
    }


def main():
    text = json.dumps(build(), indent=1, ensure_ascii=False) + '\n'
    if '--check' in sys.argv:
        cur = open(OUT, encoding='utf-8').read() if os.path.exists(OUT) else ''
        if cur != text:
            print('helplines.json is stale: run tool/support/build_helplines.py')
            return 1
        print('helplines.json up to date')
        return 0
    open(OUT, 'w', encoding='utf-8').write(text)
    print('wrote %s: %d verified, %d toVerify' % (OUT, len(V), len(T)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
