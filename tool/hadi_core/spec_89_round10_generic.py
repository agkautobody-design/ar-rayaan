# Generic entries from round 10. They come after every topic entry so a specific answer (the mothers'-feet
# saying, the China saying) wins first.

E('hadith-grade-ask',
  m=[r'\b(?:grade|grading|rating|status|authenticity|strength|classification)\b.*\b(?:hadith|saying|narration)\b', r'\b(?:hadith|saying|narration)\b.*\b(?:grade|graded|rated|authentic|authenticity|sahih|saheeh|hasan|daif|weak|fabricated|mawdu|forged|fake|invented|reliable|real|true|genuine)\b',
     r'\bis (?:this |the |that |it )?(?:hadith|saying|narration)\b.*\b(?:authentic|sahih|saheeh|hasan|daif|weak|fabricated|forged|fake|real|true|genuine|reliable|correct)\b', r'\bis it (?:an? )?(?:authentic|sahih|saheeh|weak|fabricated|real|genuine) (?:hadith|saying)\b',
     r'\bwhat is the (?:grade|status|ruling|authenticity) of\b.*\b(?:hadith|saying|actions are|intentions|narration)\b', r'\b(?:grade|status|rating) of (?:the )?(?:hadith|saying)\b', r'\bwhich hadith (?:are|is) (?:sahih|authentic|weak|fabricated)\b', r'\bhow (?:do|can) i (?:know|check|find out|verify) (?:if |whether )?(?:a |the |this )?(?:hadith|saying) is (?:authentic|sahih|real|true|weak)\b'],
  x=[r'\bchina\b', r'\bhadith (?:number|no|num)\b', r'\bwhat is (?:a )?(?:sahih|hasan|daif|weak|fabricated|mawdu)\b', r'\bwhat does sahih mean\b'],
  topic='hadith',
  text="""
I do not grade hadith myself, and I will not give a grade from memory. A grade is a scholar's judgment on the chain and the text, and it can differ from one scholar to another.

What I can do:
- For hadith from Sahih al-Bukhari and Sahih Muslim, the scholars accepted the collections as sound, so a report found in them is not given a separate grade there. Where this app prints a hadith from the other four books (Abu Dawud, at-Tirmidhi, an-Nasa'i, Ibn Majah), it shows the grade and who gave it, for example "sahih per al-Albani". Look at the source card under an answer.
- If you ask me about one hadith by its first words or its topic, I will tell you whether it is on my shelf and show its source and grade.
- The Hadith screen holds the Forty Hadith of Imam an-Nawawi and a daily hadith, each with its collection, number and grade where one is on file.
- To check a saying you have seen online, search its words in the collections; if it is in none of the six books, be careful with it. A qualified scholar, or a hadith database that names the scholar who graded it, is the place to confirm it.

One example I do hold: "Actions are only by intentions" is in Sahih al-Bukhari (number 1) and in Sahih Muslim (number 1907), so it is among the most firmly established of all hadith. And "Seek knowledge even in China" is not an authentic hadith (ask me about it by name).
""",
  go=['/hadith', '/search'],
  review='Describes how grades are shown in the app and how to check one. The statement that the Bukhari and Muslim reports need no separate grade is the standard view. No grade is given from memory.')

