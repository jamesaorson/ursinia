;; Greek Source Bible concordance: one English gloss per Greek lemma per sense.
;;
;; Format (see gsb/translation/README.md):
;;   (lemma "<lemma as in gsb/greek/*.tsv>"
;;     (sense <name>
;;       (gloss "<gloss>" "<other accepted form>" ...)   ; "" = left unrendered
;;       (why "<the reasoning>")))
;;
;; Every Greek word aligned in a literal layer names one of these senses
;; (implicitly when its lemma has only one). `make gsb/lint` checks that the
;; English segment holds one of the sense's glosses. Kept in Greek alphabetical
;; order, accents ignored. Status: draft, for owner review.
;;
;; Lemmas marked "(LXX, supplied)" in their why are not lemmatized in the
;; Greek table (Septuagint-only forms); the lemma was supplied by hand in the
;; translation file with the (N sense "lemma") form.

(lemma "ἄβυσσος"
  (sense abyss
    (gloss "abyss")
    (why "The deep of Genesis 1:2. Kept as \"abyss\" (not \"the deep\") so it matches the same word in Luke 8:31, Romans 10:7 and Revelation 9-20.")))

(lemma "ἀγρός"
  (sense field
    (gloss "field" "fields")
    (why "Open, uncultivated or farmed land outside a town: \"field\" in both testaments (\"the lilies of the field\", Matthew 6:28).")))

(lemma "ἄγω"
  (sense bring
    (gloss "bring" "brought" "bringing" "brings")
    (why "To lead or bring a person or animal somewhere (Genesis 2:19, 22). \"Lead\" (as in Romans 8:14) becomes its own sense if the context needs it.")))

(lemma "Ἀδάμ"
  (sense name
    (gloss "Adam")
    (why "The personal name. The Septuagint first uses it at Genesis 2:16; before that it says ἄνθρωπος, \"human\". We follow the Greek exactly: Ἀδάμ is always \"Adam\", ἄνθρωπος never is (see the Genesis book notes).")))

(lemma "ἁγιάζω"
  (sense sanctify
    (gloss "sanctify" "sanctified" "sanctifies" "sanctifying")
    (why "To make or treat as holy (ἅγιος). \"Sanctify\" rather than \"make holy\" or \"hallow\", one English verb for one Greek verb; it keeps the link with the noun ἁγιασμός, \"sanctification\".")))

(lemma "Αἰθιοπία"
  (sense name
    (gloss "Ethiopia")
    (why "(LXX, supplied.) The country name as the Greek gives it (Genesis 2:13), where the Hebrew has Cush. Same English as Αἰθίοψ in Acts 8:27 (\"an Ethiopian\").")))

(lemma "αἰσχύνω"
  (sense ashamed
    (gloss "ashamed")
    (why "Lemma form as in the New Testament table. The middle/passive, the only voice used so far, is \"be ashamed\"; the imperfect is \"were being ashamed\" in the literal layer (Genesis 2:25).")))

(lemma "αἰών"
  (sense age
    (gloss "age" "ages")
    (why "An age, a long or unending span of time. Kept as \"age\" in the literal layer so εἰς τὸν αἰῶνα reads \"into the age\" and its plural forms (\"into the ages of the ages\") stay visible; the readable layer says \"forever\".")))

(lemma "ἀκατασκεύαστος"
  (sense unfurnished
    (gloss "unfurnished")
    (why "(LXX, supplied.) \"Not built, not equipped\", from κατασκευάζω, \"to prepare, build, furnish\" (Hebrews 3:3-4, God the builder of all things; 11:7, the ark). Genesis 1:2 describes an earth not yet furnished with what days 3-6 bring. \"Unformed\" would import the Hebrew-based \"without form\"; \"unfurnished\" is the Greek word's own sense.")))

(lemma "ἄκανθα"
  (sense thorn
    (gloss "thorn" "thorns")
    (why "Thorn, thornbush (Genesis 3:18; Matthew 7:16; 27:29, the crown of thorns; Hebrews 6:8).")))

(lemma "ἀκούω"
  (sense hear
    (gloss "hear" "heard" "hears" "hearing")
    (why "To hear. With the genitive of a person's voice it can mean \"heed, obey\" (Genesis 3:17); the literal layer keeps \"hear\" and the readable layer may say \"listen to\".")))

(lemma "ἄν"
  (sense ever
    (gloss "ever")
    (why "The particle of contingency. After a relative (ᾗ ἂν ἡμέρᾳ, Genesis 2:17; 3:5) it makes the clause indefinite; rendered \"ever\" (\"in which ever day\") so the particle is visible rather than absorbed into \"whatever\". In conditions (\"would\") it becomes its own sense. ἐάν after a relative takes the same gloss.")))

(lemma "ἀνά"
  (sense meson
    (gloss "")
    (why "In the Septuagint ἀνά almost always stands in the fixed phrase ἀνὰ μέσον, \"between\" (also 1 Corinthians 6:5). The phrase is one English word, carried by μέσος (sense between); ἀνά is aligned with it and left unrendered. The distributive ἀνά (\"each\", Matthew 20:9) becomes its own sense when it occurs.")))

(lemma "ἀναβαίνω"
  (sense go-up
    (gloss "go up" "goes up" "going up" "went up" "gone up")
    (why "(Supplied in Genesis 2:6, where the form is LXX-only.) To go up, ascend. \"Go up\" covers both a spring rising (Genesis 2:6) and going up to Jerusalem (Mark 10:33).")))

(lemma "ἀναγγέλλω"
  (sense declare
    (gloss "declare" "declared" "declares" "declaring")
    (why "To report, announce, declare (John 4:25; 16:13-15). \"Declare\" keeps it apart from λέγω \"say\" and ἀπαγγέλλω.")))

(lemma "ἀναπληρόω"
  (sense fill-up
    (gloss "fill up" "filled up" "fills up" "filling up")
    (why "(Supplied in Genesis 2:21.) To fill up, make complete (Galatians 6:2; 1 Thessalonians 2:16). The ἀνα- prefix is kept as \"up\" to distinguish it from πληρόω \"fill\".")))

(lemma "ἀνατέλλω"
  (sense rise
    (gloss "rise" "rose" "risen" "rises" "rising")
    (why "(Supplied in Genesis 2:5, 3:18.) Intransitive: to rise, spring up, of the sun (Matthew 5:45), light (Matthew 4:16) or plants (Genesis 2:5). \"Rise\" serves all of these and keeps the link with ἀνατολή, the rising of the sun, the east."))
  (sense raise
    (gloss "raise" "raised" "raises" "raising")
    (why "Transitive: to make rise, make spring up (Genesis 3:18, the earth raising thorns). A separate English verb because English \"rise\" cannot take an object.")))

(lemma "ἀνατολή"
  (sense east
    (gloss "east" "easts")
    (why "(Supplied in Genesis 2:8.) The rising (of the sun), hence the east: Matthew 2:1-2. Genesis 2:8 has the plural κατὰ ἀνατολάς, an idiom for \"eastward\"; the literal layer gives \"[the] east\" and the plural is noted there.")))

(lemma "ἄνθραξ"
  (sense carbuncle
    (gloss "carbuncle")
    (why "(Supplied in Genesis 2:12.) A glowing-red precious stone, the carbuncle (also Exodus 28:18). The same word means a live coal in Romans 12:20; that becomes its own sense, \"coal\", there.")))

(lemma "ἄνθρωπος"
  (sense human
    (gloss "human" "humans")
    (why "The literal layer keeps ἄνθρωπος (a human being, of either sex) apart from ἀνήρ (a man, a husband), so the two cannot share \"man\". \"Human\" is the one English noun with exactly that sense. The readable layer may say \"people\" or \"men\" where English idiom wants it, and \"man\" for the first human in Genesis 1-2.")))

(lemma "ἀνήρ"
  (sense man
    (gloss "man" "men")
    (why "A male human, and so also a husband. One gloss, \"man\", in the literal layer (\"her man\", Genesis 3:6, 16), because the Greek has one word; the readable layer says \"husband\" where English needs it. Never used for ἄνθρωπος (sense human).")))

(lemma "ἀντί"
  (sense in-place-of
    (gloss "in place of")
    (why "(Supplied in Genesis 2:21, where it is elided ἀντ’.) Substitution: \"in place of\" (Matthew 2:22; 20:28, a ransom in place of many). \"Instead of\" would serve equally; one phrase is chosen and kept.")))

(lemma "ἀόρατος"
  (sense invisible
    (gloss "invisible")
    (why "(Supplied in Genesis 1:2.) Unseen, invisible. Same gloss as Colossians 1:15-16 (\"the image of the invisible God\") and Romans 1:20, so the Greek link between the invisible earth of Genesis 1:2 and the New Testament's invisible things stays visible.")))

(lemma "ἀπατάω"
  (sense deceive
    (gloss "deceive" "deceived" "deceives" "deceiving")
    (why "(Supplied in Genesis 3:13.) To deceive (1 Timothy 2:14; Ephesians 5:6). The compound ἐξαπατάω (2 Corinthians 11:3, retelling Genesis 3:13) will need its own gloss, such as \"deceive thoroughly\", so the difference shows.")))

(lemma "ἀπέναντι"
  (sense facing
    (gloss "facing")
    (why "Over against, facing (Matthew 27:61, sitting facing the tomb). Kept apart from κατέναντι \"opposite\" (Genesis 2:14) so the two prepositions are distinguishable in English.")))

(lemma "ἀπέρχομαι"
  (sense go-away
    (gloss "go away" "goes away" "going away" "went away" "gone away")
    (why "(Supplied in Genesis 3:19.) To go away, depart. \"Go away\" keeps the ἀπο- of the compound against πορεύομαι \"go\".")))

(lemma "ἀπό"
  (sense from
    (gloss "from")
    (why "Separation or source: \"from\". Partitive uses (\"from every tree\", \"of\") keep \"from\" in the literal layer.")))

(lemma "ἀποθνῄσκω"
  (sense die
    (gloss "die" "died" "dies" "dying")
    (why "To die. θανάτῳ ἀποθανεῖσθε (Genesis 2:17; 3:4) is \"by death you will die\" in the literal layer.")))

(lemma "ἀποστρέφω"
  (sense turn-back
    (gloss "turn back" "turns back" "turning back" "turned back")
    (why "(Supplied in Genesis 3:19.) To turn back, return; transitive \"turn away\" (Romans 11:26) will be its own sense. \"Turn back\" rather than \"return\" keeps the link with στρέφω \"turn\" and ἀποστροφή \"turning\" (Genesis 3:16).")))

(lemma "ἀποστροφή"
  (sense turning
    (gloss "turning")
    (why "(LXX, supplied.) A turning (away or back) to someone, recourse. Genesis 3:16 \"your turning [is] to your man\", where translations from the Hebrew have \"desire\". Same root as ἀποστρέφω (sense turn-back), as in Genesis 3:19.")))

(lemma "ἅπτω"
  (sense touch
    (gloss "touch" "touched" "touches" "touching")
    (why "(Supplied in Genesis 3:3.) Middle: to touch, take hold of (Matthew 8:3; John 20:17). The active \"kindle\" (Luke 8:16) becomes its own sense.")))

(lemma "ἀρεστός"
  (sense pleasing
    (gloss "pleasing")
    (why "Pleasing, acceptable (John 8:29, the things pleasing to him). \"Pleasing\" against εὐάρεστος, which will take \"well-pleasing\".")))

(lemma "ἄρσην"
  (sense male
    (gloss "male")
    (why "Male (Genesis 1:27; Matthew 19:4; Galatians 3:28). Against ἀνήρ \"man\".")))

(lemma "ἄρτος"
  (sense bread
    (gloss "bread" "breads")
    (why "Bread, a loaf; by extension food (Genesis 3:19). Kept as \"bread\" everywhere so \"our daily bread\" and \"you will eat your bread\" match.")))

(lemma "ἀρχή"
  (sense beginning
    (gloss "beginning" "beginnings")
    (why "The start of time or of a thing, as in Genesis 1:1 (ἐν ἀρχῇ), which John 1:1 echoes word for word; one gloss in both keeps the echo visible. Also the head or source of a river (Genesis 2:10, \"four beginnings\")."))
  (sense rule
    (gloss "rule" "rules")
    (why "Rule, dominion, and (plural) rulers or powers: Genesis 1:16 εἰς ἀρχὰς τῆς ἡμέρας, \"for rules of the day\"; Luke 12:11; Ephesians 1:21; Colossians 1:16. Same English root as ἄρχω (sense rule).")))

(lemma "ἄρχω"
  (sense rule
    (gloss "rule" "rules" "ruled" "ruling")
    (why "Active: to rule, govern (Genesis 1:16-28; Mark 10:42; Romans 15:12). With the genitive of what is ruled; the English \"over\" belongs to that noun's segment, like any case ending."))
  (sense begin
    (gloss "begin" "began" "begun" "begins" "beginning")
    (why "Middle: to begin (Genesis 2:3; Matthew 4:17, and very often in the Gospels).")))

(lemma "Ἀσσύριος"
  (sense name
    (gloss "Assyrian" "Assyrians")
    (why "(LXX, supplied.) The people name, plural in Genesis 2:14 (\"opposite [the] Assyrians\").")))

(lemma "ἀστήρ"
  (sense star
    (gloss "star" "stars")
    (why "A star (Genesis 1:16; Matthew 2:2). ἄστρον, a near synonym, will take \"constellation\" or a note if needed.")))

(lemma "αὐξάνω"
  (sense grow
    (gloss "grow" "grew" "grown" "grows" "growing")
    (why "(Supplied in Genesis 1:22, 28.) To grow, increase (Matthew 6:28; Luke 2:40; Acts 6:7). Genesis 1:22, 28 αὐξάνεσθε is \"grow\", where translations from the Hebrew have \"be fruitful\". The middle/passive forms are rendered with intransitive English \"grow\".")))

(lemma "ἀφορίζω"
  (sense set-apart
    (gloss "set apart" "sets apart" "setting apart")
    (why "(Supplied in Genesis 2:10.) To mark off by a boundary, set apart, separate (Romans 1:1; Galatians 1:15; Matthew 25:32). \"Set apart\" keeps it apart from διαχωρίζω \"separate\". Genesis 2:10, of the river: \"from there it is being set apart into four beginnings\".")))

(lemma "αὐτός"
  (sense pronoun
    (gloss "he" "him" "his" "she" "her" "hers" "it" "its" "they" "them" "their" "theirs")
    (why "The third-person pronoun. The English form follows the Greek gender, number and case; a neuter referring to a thing is \"it\". The intensive (\"himself\") and identifying (\"the same\") uses become their own senses when they occur. A nominative αὐτός (Genesis 3:15-16) is emphatic; the literal layer still says \"he\" and the emphasis is noted, not added.")))

(lemma "βίβλος"
  (sense book
    (gloss "book" "books")
    (why "A book or written record (Genesis 2:4; 5:1; Matthew 1:1). βιβλίον, its diminutive, will take \"scroll\".")))

(lemma "βλαστάνω"
  (sense sprout
    (gloss "sprout" "sprouts" "sprouted" "sprouting")
    (why "(Supplied in Genesis 1:11.) To sprout, put forth shoots; transitively, to make sprout (Genesis 1:11; James 5:18). Hebrews 9:4, Aaron's rod \"that sprouted\".")))

(lemma "βοηθός"
  (sense helper
    (gloss "helper" "helpers")
    (why "(Supplied in Genesis 2:18, where the form is LXX-only.) One who helps (Hebrews 13:6, \"the Lord is my helper\"). In the Septuagint it is often God himself (Psalm 54:4), which is why the word does not imply inferiority.")))

(lemma "βοτάνη"
  (sense vegetation
    (gloss "vegetation")
    (why "Green growth, pasture (Genesis 1:11-12; Hebrews 6:7). \"Vegetation\" against χόρτος \"grass\".")))

(lemma "βρέχω"
  (sense rain
    (gloss "rain" "rained" "rains" "raining")
    (why "To rain, send rain (Genesis 2:5; Matthew 5:45). The sense \"wet\" (Luke 7:38) becomes its own sense.")))

(lemma "βρῶσις"
  (sense eating
    (gloss "eating")
    (why "The act of eating, or what is eaten. \"Eating\" (1 Corinthians 8:4) keeps it apart from βρῶμα, which will take \"food\". In Genesis 2:16 βρώσει φάγῃ is \"with eating you will eat\", a Hebrew-style intensive kept in the literal layer.")))

(lemma "γάρ"
  (sense for
    (gloss "for")
    (why "The explanatory particle, always rendered \"for\" and always placed first in its English clause (the Greek puts it second).")))

(lemma "γένεσις"
  (sense genesis
    (gloss "genesis")
    (why "Origin, coming into being, birth; the noun of γίνομαι. Genesis 2:4 αὕτη ἡ βίβλος γενέσεως and Matthew 1:1 βίβλος γενέσεως open with the same two words; one gloss keeps that visible. \"Genesis\" (the English loanword) is used rather than \"origin\" or \"generation\" because it is the only English word that carries the link to the book's name; the owner may prefer \"origin\" (see the Genesis book notes).")))

(lemma "γένος"
  (sense kind
    (gloss "kind" "kinds")
    (why "Kind, sort, race (Genesis 1:11-25; Matthew 13:47, every kind of fish). \"Race\" or \"nation\" (1 Peter 2:9) will be a separate sense if needed.")))

(lemma "γῆ"
  (sense earth
    (gloss "earth")
    (why "The earth, as opposed to heaven or sea, and its soil. The Septuagint uses γῆ both for the Hebrew 'erets (earth, land) and 'adamah (ground); the literal layer keeps \"earth\" for all of them so the Greek's own links stay visible (Genesis 2:7 \"dust from the earth\", 3:19 \"earth you are, and into earth you will go away\")."))
  (sense land
    (gloss "land" "lands")
    (why "A particular land or region: \"the land of Havilah\", \"the land of Ethiopia\" (Genesis 2:11-13), \"the land of Judah\" (Matthew 2:6).")))

(lemma "Γηών"
  (sense name
    (gloss "Gihon")
    (why "(LXX, supplied.) The second river of Genesis 2:13, given its traditional English name.")))

(lemma "γίνομαι"
  (sense come-to-be
    (gloss "come to be" "came to be" "comes to be" "coming to be" "has come to be" "have come to be" "had come to be" "will come to be")
    (why "γίνομαι is coming into existence or into a state, against εἰμί, being. \"Come to be\" keeps that contrast everywhere (John 1:1-3 sets ἦν against ἐγένετο; Genesis 1:3 γενηθήτω φῶς καὶ ἐγένετο φῶς); \"was made\" would wrongly suggest a passive, and \"became\" needs a complement. Aorist: \"came to be\"; perfect: \"has come to be\". γίνομαι εἰς (Genesis 2:7) is literally \"come to be into\"; the readable layer says \"became\".")))

(lemma "γινώσκω"
  (sense know
    (gloss "know" "knew" "known" "knows" "knowing")
    (why "To know, come to know. It shares \"know\" with οἶδα: no English pair keeps the two apart without distorting one of them, so the alignment, not the English, shows which verb the Greek uses (Genesis 2:9 has οἶδα, 2:17 γινώσκω). The owner may prefer \"come to know\" or \"recognize\" for γινώσκω.")))

(lemma "γνωστός"
  (sense known
    (gloss "known")
    (why "Known, knowable (Acts 1:19; Romans 1:19, τὸ γνωστὸν τοῦ θεοῦ). Genesis 2:9 has the tree τοῦ εἰδέναι γνωστὸν καλοῦ καὶ πονηροῦ, \"of knowing [what is] known of good and evil\".")))

(lemma "γυμνός"
  (sense naked
    (gloss "naked")
    (why "Naked, without the outer garment (Genesis 2:25; 3:7-11; Matthew 25:36).")))

(lemma "γυνή"
  (sense woman
    (gloss "woman" "women")
    (why "A woman, and so also a wife. One gloss, \"woman\", in the literal layer (\"his woman\", Genesis 2:24) because the Greek has one word; the readable layer says \"wife\" where English needs it. This also keeps Genesis 2:22-23 (\"built ... into [a] woman\", \"this [one] will be called Woman\") continuous with \"his woman\" in 2:24-25.")))

(lemma "δέ"
  (sense but
    (gloss "but")
    (why "The commonest Greek connective after καί, mildly contrastive or simply marking a new step. Always rendered, as the owner requires, and always \"but\" so it can never be confused with καί \"and\". Alternatives considered: \"now\" (collides with νῦν), \"and\" (collides with καί). The cost is that \"but\" overstates the contrast in narrative (Matthew 1:2-16); the owner is asked to rule (Genesis book notes). Placed first in its English clause, though the Greek puts it second.")))

(lemma "δειλινός"
  (sense afternoon
    (gloss "afternoon")
    (why "(LXX, supplied.) Of the afternoon or early evening; τὸ δειλινόν (Genesis 3:8) is an accusative of time, \"in the afternoon\", where translations from the Hebrew have \"in the cool (wind) of the day\".")))

(lemma "δερμάτινος"
  (sense leather
    (gloss "leather")
    (why "(Supplied in Genesis 3:21.) Made of skin or hide, leather (Mark 1:6; Matthew 3:4, John's leather belt). Same gloss in both.")))

(lemma "δεύτερος"
  (sense second
    (gloss "second")
    (why "The ordinal \"second\".")))

(lemma "διά"
  (sense through
    (gloss "through")
    (why "With the genitive: agency or means passing through someone or something. With the accusative (\"because of\") it is a separate sense.")))

(lemma "διανοίγω"
  (sense open
    (gloss "open" "opened" "opens" "opening")
    (why "(Supplied in Genesis 3:5.) To open fully, of eyes (Genesis 3:5, 7; Luke 24:31, their eyes were opened), ears, the womb, the Scriptures. \"Open\", against ἀνοίγω, which will need its own gloss or a note.")))

(lemma "διαχωρίζω"
  (sense separate
    (gloss "separate" "separated" "separates" "separating")
    (why "(Supplied in Genesis 1, where the forms are LXX-only.) To divide, separate one thing from another (Luke 9:33, middle: \"part from\"). \"Separate\" in all five uses of Genesis 1. ἀφορίζω takes \"set apart\".")))

(lemma "δίδωμι"
  (sense give
    (gloss "give" "gave" "given" "gives" "giving")
    (why "To give. Perfect δέδωκα (Genesis 1:29) is \"I have given\".")))

(lemma "δύο"
  (sense two
    (gloss "two")
    (why "The numeral. οἱ δύο, \"the two\", in Genesis 2:24-25 and 3:7, is kept because the New Testament quotes it (Matthew 19:5; Mark 10:8; 1 Corinthians 6:16; Ephesians 5:31).")))

(lemma "ἐάν"
  (sense ever
    (gloss "ever")
    (why "After a relative pronoun ἐάν stands for ἄν and makes the relative indefinite (ὃ ἐάν, \"which ever\", Genesis 2:19; Matthew 5:19). Same gloss as ἄν. The conditional \"if\" becomes its own sense when first needed.")))

(lemma "ἑαυτοῦ"
  (sense self
    (gloss "itself" "himself" "herself" "themselves" "yourself" "yourselves" "myself" "ourselves")
    (why "The reflexive pronoun; the English form follows the referent's person, gender and number. A dative \"for themselves\" carries its case in \"for\".")))

(lemma "ἕβδομος"
  (sense seventh
    (gloss "seventh")
    (why "The ordinal \"seventh\" (Genesis 2:2-3; Hebrews 4:4).")))

(lemma "ἐγώ"
  (sense pronoun
    (gloss "I" "me" "my" "mine" "we" "us" "our" "ours")
    (why "The first-person pronoun, singular and plural (the table lemmatizes ἡμεῖς under ἐγώ). The English form follows the Greek case and number.")))

(lemma "Ἐδέμ"
  (sense name
    (gloss "Eden")
    (why "(LXX, supplied.) The place name, given its traditional English form; the Greek spells it Ἐδέμ, with final μ. In Genesis 3:23-24 the Septuagint translates the same Hebrew word instead, τρυφή \"delight\" (\"the paradise of the delight\").")))

(lemma "εἰ"
  (sense if
    (gloss "if")
    (why "The conditional \"if\". εἰ μή in Genesis 3:11 is rendered word for word (\"if not\") and discussed in a note.")))

(lemma "εἰκών"
  (sense image
    (gloss "image" "images")
    (why "Image, likeness that represents (Genesis 1:26-27; 2 Corinthians 4:4; Colossians 1:15; 3:10). Kept apart from ὁμοίωσις \"likeness\".")))

(lemma "εἰμί"
  (sense be
    (gloss "be" "am" "is" "are" "was" "were" "been" "being" "will be")
    (why "The verb of being. εἰμί has no aorist, so its imperfect is plain \"was\", not \"was being\"; the progressive is kept for the imperfect of verbs that also have an aorist.")))

(lemma "εἷς"
  (sense one
    (gloss "one")
    (why "The numeral, kept as \"one\" so emphatic uses (οὐδὲ ἕν, \"not even one\") stay visible. Genesis 1:5 ἡμέρα μία is \"day one\", a cardinal, not \"the first day\".")))

(lemma "εἰς"
  (sense into
    (gloss "into")
    (why "Motion into, and the Hebrew-style \"come to be into\" / \"be into\" (Genesis 2:7, 24), which the literal layer keeps (\"the two will be into one flesh\") and the readable layer renders \"become\". Also εἰς τὸν αἰῶνα, \"into the age\"."))
  (sense for
    (gloss "for")
    (why "Purpose or destination: \"for signs\", \"for eating\" (Genesis 1:14, 29). A different English preposition because \"into food\" would mislead; the Greek is the same word.")))

(lemma "ἐκ"
  (sense out-of
    (gloss "out of")
    (why "Origin, \"out of\", against ἀπό \"from\" (Genesis 2:23 ἐκ τῶν ὀστέων μου, \"out of my bones\").")))

(lemma "ἐκβάλλω"
  (sense cast-out
    (gloss "cast out" "casts out" "casting out")
    (why "To throw out, drive out (Genesis 3:24; Mark 1:34, casting out demons). Same gloss in both testaments.")))

(lemma "ἐκεῖ"
  (sense there
    (gloss "there")
    (why "The adverb of place.")))

(lemma "ἐκεῖθεν"
  (sense from-there
    (gloss "from there")
    (why "The adverb of place from which (Genesis 2:10).")))

(lemma "ἐκεῖνος"
  (sense that
    (gloss "that" "those")
    (why "The far demonstrative, against οὗτος \"this\". Never turned into a personal pronoun.")))

(lemma "ἐκπορεύομαι"
  (sense go-out
    (gloss "go out" "goes out" "going out" "went out")
    (why "To go out, come out. Genesis 2:10 (a river going out of Eden) is echoed in Revelation 22:1 (a river ἐκπορευόμενον from the throne); one gloss keeps the echo. John 15:26 (the Spirit who ἐκπορεύεται from the Father) will read \"goes out\", not the traditional \"proceeds\".")))

(lemma "ἔκστασις"
  (sense trance
    (gloss "trance")
    (why "(Supplied in Genesis 2:21.) A standing outside oneself: trance (Acts 10:10; 11:5; 22:17), and astonishment (Mark 5:42), which will be its own sense. Genesis 2:21 says God cast a trance on Adam where translations from the Hebrew have \"a deep sleep\".")))

(lemma "ἐκτείνω"
  (sense stretch-out
    (gloss "stretch out" "stretched out" "stretches out" "stretching out")
    (why "(Supplied in Genesis 3:22.) To stretch out the hand (Matthew 8:3; 12:13).")))

(lemma "ἕκτος"
  (sense sixth
    (gloss "sixth")
    (why "The ordinal \"sixth\".")))

(lemma "ἐκφέρω"
  (sense bring-forth
    (gloss "bring forth" "brought forth" "brings forth" "bringing forth")
    (why "To carry out, bring forth; of the earth, to produce (Genesis 1:12; Hebrews 6:8). \"Bring forth\" keeps it apart from ἐξάγω \"bring out\". The sense \"carry out\" (a corpse, Acts 5:6) becomes its own sense.")))

(lemma "ἐλάσσων"
  (sense lesser
    (gloss "lesser")
    (why "Smaller, lesser (Genesis 1:16; John 2:10; Romans 9:12, \"the greater will serve the lesser\" from Genesis 25:23, where traditional English says \"the younger\").")))

(lemma "ἐμφυσάω"
  (sense breathe
    (gloss "breathe" "breathed" "breathes" "breathing")
    (why "To breathe into or on. Rare: in the New Testament only John 20:22, where Jesus ἐνεφύσησεν on the disciples and says \"Receive the Holy Spirit\", the same verb God uses in Genesis 2:7. One gloss keeps the echo.")))

(lemma "ἐν"
  (sense in
    (gloss "in")
    (why "Location in, among or within, of place or time. The instrumental use (\"with, by\") becomes its own sense when first needed.")))

(lemma "ἐνδύω"
  (sense clothe
    (gloss "clothe" "clothed" "clothes" "clothing")
    (why "(Supplied in Genesis 3:21.) Active: to clothe someone; middle: to put on, clothe oneself (Romans 13:14; Galatians 3:27). \"Clothe\" for both so the image of being clothed carries across.")))

(lemma "ἕνεκα"
  (sense on-account-of
    (gloss "on account of")
    (why "Cause: \"on account of\" (ἕνεκεν τούτου, Genesis 2:24; Matthew 19:5 has ἕνεκα τούτου). Kept apart from διὰ τοῦτο, which will take \"because of this\".")))

(lemma "ἐνιαυτός"
  (sense year
    (gloss "year" "years")
    (why "A year, a cycle of seasons (Genesis 1:14; Luke 4:19). ἔτος, the other word for year, will be distinguished in a note if needed.")))

(lemma "ἐντέλλομαι"
  (sense command
    (gloss "command" "commanded" "commands" "commanding")
    (why "To command, give an order (Genesis 2:16; 3:11, 17; Matthew 28:20). The noun ἐντολή will take \"commandment\".")))

(lemma "ἐξάγω"
  (sense bring-out
    (gloss "bring out" "brought out" "brings out" "bringing out")
    (why "To lead out, bring out (Genesis 1:20-24; Acts 7:36, Moses leading Israel out). Against ἐκφέρω \"bring forth\".")))

(lemma "ἐξανατέλλω"
  (sense cause-to-spring-up
    (gloss "caused to spring up" "cause to spring up" "causes to spring up")
    (why "Transitive in Genesis 2:9 (God made every tree spring up out of the earth). Intransitive \"spring up\" (Matthew 13:5) becomes its own sense. Kept apart from ἀνατέλλω \"rise\" by the ἐξ- (\"spring up out\").")))

(lemma "ἐξαποστέλλω"
  (sense send-out
    (gloss "send out" "sent out" "sends out" "sending out")
    (why "To send out, send away (Genesis 3:23; Luke 1:53; Galatians 4:4-6, God sent out his Son). Against ἀποστέλλω, which will take \"send\".")))

(lemma "ἐπάνω"
  (sense over
    (gloss "over")
    (why "Above, over, on top of (Genesis 1:2, 7, 29; Matthew 2:9, the star stood over where the child was). One gloss, \"over\". The sense \"more than\" (Mark 14:5) becomes its own sense.")))

(lemma "ἐπί"
  (sense upon
    (gloss "upon")
    (why "Of place, with the genitive, dative or accusative: \"upon\" (upon the earth, upon Adam, upon your breast). \"Upon\" rather than \"on\" because it also covers the birds flying \"upon the earth\" (Genesis 1:20). The many non-spatial uses (\"in the time of\", \"on the basis of\", \"against\") will be separate senses.")))

(lemma "ἐπιβάλλω"
  (sense cast
    (gloss "cast" "casts" "casting")
    (why "To throw or lay upon (Genesis 2:21, a trance; Mark 14:46, laying hands on). \"Cast\", from βάλλω, which will also take \"cast\" with its own note; the compound's ἐπι- is usually echoed by the following ἐπί \"upon\".")))

(lemma "ἐπικατάρατος"
  (sense cursed
    (gloss "cursed")
    (why "Accursed, under a curse (Genesis 3:14, 17; Galatians 3:10, 13 quoting Deuteronomy). καταράομαι and its participle will need a note so the two do not merge.")))

(lemma "ἐπιφέρω"
  (sense borne
    (gloss "borne")
    (readable "moving")
    (why "(Supplied in Genesis 1:2, where the form is LXX-only.) Active: to bring upon; middle/passive: to be borne or carried over, to move over. Genesis 1:2 ἐπεφέρετο is imperfect middle/passive, \"was being borne\" in the literal layer. The readable layer says \"was moving\" (Genesis 1:2): \"borne\" is no longer natural English (gsb/lexicon/readable-avoid.scm). The active (Romans 3:5, \"inflict\") will be its own sense.")))

(lemma "ἐργάζομαι"
  (sense work
    (gloss "work" "worked" "works" "working")
    (why "To work, to work the soil (Genesis 2:5, 15; 3:23); to do, perform (John 6:28). Kept as \"work\" so the verb and the noun ἔργον stay visibly related.")))

(lemma "ἔργον"
  (sense work
    (gloss "work" "works")
    (why "A work, deed (Genesis 2:2-3; Hebrews 4:4; John 6:28-29). Same English as ἐργάζομαι, deliberately.")))

(lemma "ἑρπετόν"
  (sense creeping-thing
    (gloss "creeping thing" "creeping things" "creeping")
    (why "A creeping or crawling animal, reptile (Genesis 1:20-30; Acts 10:12; Romans 1:23). \"Creeping thing\" keeps its link with ἕρπω \"creep\" (Genesis 1:26, \"the creeping things creeping upon the earth\"). Used attributively with ζῷα (Genesis 1:21) it is \"creeping\".")))

(lemma "ἕρπω"
  (sense creep
    (gloss "creep" "creeps" "crept" "creeping")
    (why "(LXX, supplied.) To creep, crawl, move along the ground. Not in the New Testament.")))

(lemma "ἑσπέρα"
  (sense evening
    (gloss "evening")
    (why "Evening (Genesis 1; Luke 24:29).")))

(lemma "ἐσθίω"
  (sense eat
    (gloss "eat" "ate" "eaten" "eats" "eating")
    (why "To eat. The Greek of Genesis 2-3 uses the future (φάγῃ, φάγεσθε) both for commands and for permission; the literal layer keeps \"you will eat\".")))

(lemma "ἔτι"
  (sense further
    (gloss "further")
    (why "Additive \"further, besides\" (Genesis 2:9, 19, where the Septuagint has God make trees and animals \"further\", after Genesis 1; the Hebrew has no such word). Temporal \"still, yet\" (Luke 1:15) becomes its own sense.")))

(lemma "Εὑειλάτ"
  (sense name
    (gloss "Havilah")
    (why "(LXX, supplied.) The land of Genesis 2:11, given its traditional English name; the Greek spells it Εὑειλάτ (Heuilat).")))

(lemma "εὐλογέω"
  (sense bless
    (gloss "bless" "blessed" "blesses" "blessing")
    (why "(Supplied in Genesis 1-2, where the augmented form ηὐλόγησεν is LXX-only.) To bless, speak well of (Genesis 1:22; Luke 24:50).")))

(lemma "εὑρίσκω"
  (sense find
    (gloss "find" "found" "finds" "finding")
    (why "To find; passive \"be found\" (Genesis 2:20).")))

(lemma "Εὐφράτης"
  (sense name
    (gloss "Euphrates")
    (why "(Supplied in Genesis 2:14.) The river, by its traditional English name, as in Revelation 9:14; 16:12.")))

(lemma "ἔχθρα"
  (sense enmity
    (gloss "enmity")
    (why "Hostility, enmity (Genesis 3:15; Romans 8:7; Ephesians 2:15-16).")))

(lemma "ἔχω"
  (sense have
    (gloss "have" "has" "had" "having")
    (why "To have, hold. The many idioms (\"be ill\", ἔχω + adverb) will be separate senses.")))

(lemma "ἕως"
  (sense until
    (gloss "until")
    (why "Until, as far as. With τοῦ and an infinitive (Genesis 3:19, ἕως τοῦ ἀποστρέψαι σε) it is \"until you turn back\".")))

(lemma "ζάω"
  (sense live
    (gloss "live" "lives" "lived" "living")
    (why "To live. The participle is \"living\": ψυχὴ ζῶσα \"living soul\" (Genesis 1:24; 2:7; 1 Corinthians 15:45), οἱ ζῶντες \"the living\" (Genesis 3:20).")))

(lemma "ζωή"
  (sense life
    (gloss "life")
    (why "ζωή, life itself, against βίος, livelihood or manner of life, which gets its own gloss. In Genesis 3:20 the Septuagint gives the woman's name as Ζωή, \"Life\" (capitalized as a name); see the note there.")))

(lemma "ζῷον"
  (sense animal
    (gloss "animal" "animals")
    (why "A living being, an animal (Genesis 1:21; Hebrews 13:11; 2 Peter 2:12). \"Animal\" keeps it apart from ψυχή (\"soul\") and ζάω (\"living\"). In Revelation 4-6 tradition says \"living creatures\"; the owner may want a separate sense there.")))

(lemma "ἡμέρα"
  (sense day
    (gloss "day" "days")
    (why "Day, both daylight (Genesis 1:5) and a day of the week. A dative of time (ᾗ ἡμέρᾳ) takes \"on\" in the same segment.")))

(lemma "ἡμέτερος"
  (sense our
    (gloss "our" "ours")
    (why "The possessive adjective \"our\" (Genesis 1:26, κατ’ εἰκόνα ἡμετέραν).")))

(lemma "θάλασσα"
  (sense sea
    (gloss "sea" "seas")
    (why "The sea (Genesis 1:10, 22, 26). Some forms are supplied by hand where the table has no lemma.")))

(lemma "θάνατος"
  (sense death
    (gloss "death")
    (why "Death. The dative in θανάτῳ ἀποθανεῖσθε is \"by death\".")))

(lemma "θεός"
  (sense god
    (gloss "God" "god" "gods")
    (why "Capitalized for the God of Israel, lowercase for others. Whether the Greek has the article is shown by the alignment, not by the English (see ὁ, sense unrendered). The plural ὡς θεοί (Genesis 3:5) is \"as gods\".")))

(lemma "θηρίον"
  (sense beast
    (gloss "beast" "beasts")
    (why "A wild animal, beast (Genesis 1:24-25; 2:19-20; 3:1, 14; Mark 1:13). \"Beast\" so the same word stays recognizable in Revelation 13 (the beast). κτῆνος takes \"livestock\" and ζῷον \"animal\".")))

(lemma "θῆλυς"
  (sense female
    (gloss "female")
    (why "Female (Genesis 1:27; Matthew 19:4; Galatians 3:28).")))

(lemma "ἱδρώς"
  (sense sweat
    (gloss "sweat")
    (why "(Supplied in Genesis 3:19.) Sweat. Luke 22:44 (Jesus' sweat like drops of blood) is the only New Testament use.")))

(lemma "ἵνα"
  (sense so-that
    (gloss "so that")
    (why "Purpose: \"so that\". With μή, \"so that ... not\" (Genesis 3:3). The content use (\"that\") becomes its own sense when needed.")))

(lemma "ἰχθύς"
  (sense fish
    (gloss "fish")
    (why "Fish (Genesis 1:26, 28; Matthew 7:10).")))

(lemma "καί"
  (sense and
    (gloss "and")
    (why "The connective, always rendered so the parataxis of the Greek stays visible. At the start of a sentence it stays \"And\" in the literal layer; the readable layer usually keeps it too."))
  (sense also
    (gloss "also")
    (why "Adverbial καί, adding a word rather than joining clauses: \"she gave also to her man\" (Genesis 3:6). \"Even\" becomes its own sense when first needed.")))

(lemma "καιρός"
  (sense season
    (gloss "season" "seasons")
    (why "A fixed or fitting time, a season (Genesis 1:14; Acts 14:17, fruitful seasons). \"Season\" everywhere, so that χρόνος can keep \"time\"; \"the season is fulfilled\" (Mark 1:15) is the cost. The owner may prefer \"time\" for καιρός and \"span\" or \"while\" for χρόνος.")))

(lemma "καλέω"
  (sense call
    (gloss "call" "called" "calls" "calling")
    (why "To call, name, summon. Passive \"will be called\" (Genesis 2:23).")))

(lemma "καλός"
  (sense good
    (gloss "good")
    (why "Good, fine, beautiful: the word of God's verdict in Genesis 1. It shares \"good\" with ἀγαθός; the alignment shows which, and the owner may want ἀγαθός distinguished (\"good\" / \"beneficial\") when it first occurs.")))

(lemma "κάρπιμος"
  (sense fruitful
    (gloss "fruitful")
    (why "(LXX, supplied.) Fruit-bearing, fruitful (Genesis 1:11-12, ξύλον κάρπιμον). Not in the New Testament.")))

(lemma "καρπός"
  (sense fruit
    (gloss "fruit" "fruits")
    (why "Fruit. ποιέω καρπόν is \"make fruit\" in the literal layer (Genesis 1:11-12; Matthew 3:10; Revelation 22:2, the tree of life \"making\" twelve fruits).")))

(lemma "κατά"
  (sense according-to
    (gloss "according to")
    (why "With the accusative: standard or correspondence, \"according to\": κατὰ γένος \"according to kind\", κατ’ εἰκόνα \"according to [the] image\" (Genesis 1:26-27), βοηθὸς κατ’ αὐτόν \"a helper according to him\" (2:18). Translations from the Hebrew say \"in our image\"; the Greek preposition says \"according to\"."))
  (sense along
    (gloss "along")
    (why "With the accusative of space: along, across (Genesis 1:20, birds flying along the firmament; Luke 8:39, \"throughout the city\")."))
  (sense toward
    (gloss "toward")
    (why "With the accusative of direction: toward (Genesis 2:8, κατὰ ἀνατολάς \"toward [the] east\"; Acts 8:26, toward the south).")))

(lemma "κατακυριεύω"
  (sense master
    (gloss "master" "mastered" "masters" "mastering")
    (why "(Supplied in Genesis 1:28.) To gain mastery over, subdue, lord it over (Matthew 20:25; 1 Peter 5:3). \"Master\" keeps it apart from κυριεύω \"be lord\" and ἄρχω \"rule\".")))

(lemma "καταλαμβάνω"
  (sense overtake
    (gloss "overtake" "overtook" "overtaken" "overtakes" "overtaking")
    (why "To seize, lay hold of, overtake. John uses the verb again in 12:35 of darkness against the light (ἵνα μὴ σκοτία ὑμᾶς καταλάβῃ, \"so that darkness may not overtake you\"), so 1:5 takes the same gloss. \"Comprehend\" (KJV) belongs to the middle voice (\"perceive\", Acts 4:13), which becomes its own sense.")))

(lemma "καταλείπω"
  (sense leave
    (gloss "leave" "left" "leaves" "leaving")
    (why "To leave behind (Genesis 2:24; Matthew 19:5; Mark 10:7; Ephesians 5:31).")))

(lemma "κατανοέω"
  (sense consider
    (gloss "consider" "considered" "considers" "considering")
    (why "To look closely at, consider (Matthew 7:3; Hebrews 3:1). Genesis 3:6 τοῦ κατανοῆσαι, \"to consider\", where translations from the Hebrew have \"to make one wise\".")))

(lemma "καταπαύω"
  (sense rest
    (gloss "rest" "rested" "rests" "resting")
    (why "Intransitive: to cease, rest (Genesis 2:2-3; Hebrews 4:4, 10). The transitive \"give rest\" (Hebrews 4:8) will be its own sense; the noun κατάπαυσις will take \"rest\" too, deliberately.")))

(lemma "κατέναντι"
  (sense opposite
    (gloss "opposite")
    (why "Opposite, over against (Genesis 2:14; Mark 11:2). ἀπέναντι takes \"facing\".")))

(lemma "κατοικίζω"
  (sense settle
    (gloss "settle" "settled" "settles" "settling")
    (why "To cause to dwell, settle someone somewhere (Genesis 3:24; James 4:5, the spirit God settled in us). Against κατοικέω, which will take \"dwell\".")))

(lemma "κεφαλή"
  (sense head
    (gloss "head" "heads")
    (why "Head (Genesis 3:15; and of Christ, Ephesians 1:22).")))

(lemma "κῆτος"
  (sense sea-monster
    (gloss "sea monster" "sea monsters")
    (why "(Supplied in Genesis 1:21.) A huge sea creature (Matthew 12:40, Jonah's). \"Sea monster\" rather than \"whale\", which is too specific, or \"sea creature\", which is too weak.")))

(lemma "κοιλία"
  (sense belly
    (gloss "belly")
    (why "Belly, stomach; also womb (Luke 1:41), which may become its own sense.")))

(lemma "κόσμος"
  (sense adornment
    (gloss "adornment")
    (why "The root sense of κόσμος is order, arrangement, adornment (1 Peter 3:3). Genesis 2:1 πᾶς ὁ κόσμος αὐτῶν, \"all their adornment\", where translations from the Hebrew have \"all their host\". The New Testament's usual sense, \"world\", becomes its own sense when first translated; the owner may prefer \"world\" or \"array\" here.")))

(lemma "κρύπτω"
  (sense hide
    (gloss "hide" "hid" "hidden" "hides" "hiding")
    (why "(Supplied in Genesis 3:8, 10.) To hide. The aorist passive (ἐκρύβησαν) is intransitive \"hid\", as in John 8:59.")))

(lemma "κτῆνος"
  (sense livestock
    (gloss "livestock")
    (why "A domestic animal, beast of burden, livestock (Genesis 1:24-26; Luke 10:34). \"Livestock\" (singular and plural) rather than \"cattle\", which suggests cows only.")))

(lemma "κυκλόω"
  (sense encircle
    (gloss "encircle" "encircles" "encircled" "encircling")
    (why "(Supplied in Genesis 2:11, 13.) To go around, encircle (Luke 21:20; Hebrews 11:30).")))

(lemma "κυριεύω"
  (sense be-lord
    (gloss "be lord")
    (why "To be lord, have dominion over (Genesis 3:16; Romans 6:9, 14). \"Be lord\" keeps its kinship with κύριος visible; the genitive of what is ruled takes \"of\".")))

(lemma "κύριος"
  (sense lord
    (gloss "Lord" "lord" "lords")
    (why "Lord, master. Without the article it stands in the Septuagint for the divine name; Κύριος ὁ θεός is \"the Lord God\" as one segment, with the Greek article (before θεός) carrying the English \"the\" (see the Genesis book notes). Capitalized for God.")))

(lemma "λαμβάνω"
  (sense take
    (gloss "take" "took" "taken" "takes" "taking")
    (why "To take, receive. \"Take\" in Genesis 2-3; \"receive\" (John 1:12) will be its own sense.")))

(lemma "λέγω"
  (sense say
    (gloss "say" "said" "says" "saying")
    (why "To say. The table lemmatizes εἶπον under λέγω; both are \"say\".")))

(lemma "λίαν"
  (sense very
    (gloss "very")
    (why "Very, exceedingly (Genesis 1:31; Matthew 2:16).")))

(lemma "λίθος"
  (sense stone
    (gloss "stone" "stones")
    (why "A stone, including a precious stone (Genesis 2:12).")))

(lemma "λόγος"
  (sense word
    (gloss "word" "words")
    (why "The traditional rendering. It keeps the link to God's creating word in Genesis 1 and to every other λόγος in Scripture. Capitalized when it is the Son's title (John 1:1, 14).")))

(lemma "λύπη"
  (sense sorrow
    (gloss "sorrow" "sorrows")
    (why "Grief, sorrow, pain (Genesis 3:16-17; John 16:6, 20-22). John 16:21 (\"the woman, when she gives birth, has sorrow\") echoes Genesis 3:16; one gloss keeps it visible.")))

(lemma "μέγας"
  (sense great
    (gloss "great")
    (why "Great, large.")))

(lemma "μέσος"
  (sense between
    (gloss "between")
    (why "In ἀνὰ μέσον (\"in the middle of\"), the compound preposition \"between\"; ἀνά is aligned with it and unrendered."))
  (sense midst
    (gloss "midst")
    (why "ἐν μέσῳ, \"in [the] midst\" (Genesis 1:6; 2:9; 3:3, 8; Revelation 2:7; 22:2). \"Midst\" rather than \"middle\" to match the traditional New Testament phrase.")))

(lemma "μετά"
  (sense with
    (gloss "with")
    (why "With the genitive: accompaniment, \"with\" (Genesis 3:6, 12). It shares \"with\" with πρός in John 1:1; the alignment shows which Greek word stands behind it. With the accusative (\"after\") it is a separate sense.")))

(lemma "μή"
  (sense not
    (gloss "not")
    (why "The negative of the non-indicative moods (infinitive, subjunctive, participle): \"not\", like οὐ."))
  (sense at-all
    (gloss "at all")
    (why "In οὐ μή and οὐδὲ μή with the aorist subjunctive, the strongest Greek negation (Genesis 3:1, 3; John 6:37). The second negative is rendered \"at all\" so both words show: \"not at all will you eat\"."))
  (sense lest
    (gloss "lest")
    (why "Introducing a feared possibility, \"lest\" (μή ποτε, Genesis 3:22; Matthew 4:6, where it is printed as one word μήποτε).")))

(lemma "μήτηρ"
  (sense mother
    (gloss "mother" "mothers")
    (why "Mother.")))

(lemma "μόνος"
  (sense alone
    (gloss "alone")
    (why "Alone, only. \"Alone\" covers both Genesis 2:18 (\"for the human to be alone\") and 3:11, 17 (\"of this alone\"); \"only\" (John 17:3) will be checked against it when John 17 is translated.")))

(lemma "νῦν"
  (sense now
    (gloss "now")
    (why "The temporal adverb \"now\" (Genesis 2:23; 3:22).")))

(lemma "νύξ"
  (sense night
    (gloss "night" "nights")
    (why "Night.")))

(lemma "ξηρός"
  (sense dry
    (gloss "dry")
    (why "Dry. ἡ ξηρά (feminine, understood γῆ) is \"the dry [land]\" (Genesis 1:9-10; Hebrews 11:29).")))

(lemma "ξύλον"
  (sense tree
    (gloss "tree" "trees")
    (why "A tree (Genesis 1-3; Revelation 2:7; 22:2) and in the New Testament the cross (Acts 5:30; Galatians 3:13; 1 Peter 2:24), which will keep \"tree\" so the link with the tree of life is not lost. \"Wood\" (1 Corinthians 3:12) and \"club\" (Matthew 26:47) become their own senses. A singular used collectively (\"in the midst of the tree of the paradise\", Genesis 3:8) stays singular in the literal layer.")))

(lemma "ὁ"
  (sense the
    (gloss "the")
    (why "The article, rendered \"the\" wherever English can carry it, including with abstract nouns (\"the tree of the life\") in the literal layer."))
  (sense unrendered
    (gloss "")
    (why "English puts no article before \"God\" or a personal name (\"Adam\"), so the Greek article there is aligned with the noun and left unrendered. The alignment colors still show that the Greek has it; the literal layer does not invent a distinction English cannot hear (\"the God\")."))
  (sense attributive
    (gloss "")
    (why "The repeated article of the Greek attributive pattern \"the X the Y\" (τοὺς φωστῆρας τοὺς μεγάλους, \"the great luminaries\"; τὸ ὕδωρ τὸ ὑποκάτω τοῦ οὐρανοῦ, \"the water under the heaven\"). English says \"the\" once, so the second article is aligned with the word it marks and left unrendered."))
  (sense infinitive
    (gloss "")
    (why "The article before an infinitive (πρὸ τοῦ γενέσθαι, τοῦ γινώσκειν) marks the infinitive as a noun; English has no article for that, so it is aligned with the infinitive and left unrendered. A genitive τοῦ's \"of\" goes with the infinitive's segment."))
  (sense absorbed
    (gloss "")
    (why "English drops the article when a possessive pronoun or a demonstrative stands with the noun: τὰ ἔργα αὐτοῦ \"his works\", τῆς γῆς ἐκείνης \"that land\". The article is aligned with its noun and left unrendered rather than keeping \"the works of him\". The owner may prefer the fuller \"the works of him\".")))

(lemma "ὁδός"
  (sense way
    (gloss "way" "ways")
    (why "A road, path, way, and so a way of life (Genesis 3:24, \"the way of the tree of the life\"; John 14:6, \"I am the way\"). \"Way\" everywhere; \"road\" or \"journey\" only in the readable layer.")))

(lemma "οἰκοδομέω"
  (sense build
    (gloss "build" "built" "builds" "building")
    (why "To build (Genesis 2:22, the side built into a woman; Matthew 16:18). Figurative \"edify\" (1 Corinthians 8:1) keeps \"build\" (\"build up\").")))

(lemma "οἶδα"
  (sense know
    (gloss "know" "knew" "known" "knows" "knowing")
    (why "To know (a perfect with present meaning; ᾔδει, Genesis 3:5, is its past, \"knew\"). It shares \"know\" with γινώσκω; see that entry.")))

(lemma "ὅμοιος"
  (sense like
    (gloss "like")
    (why "Like, resembling (Genesis 2:20, a helper like him; Matthew 13:31). Against ὡς \"as\".")))

(lemma "ὁμοιότης"
  (sense similarity
    (gloss "similarity")
    (why "Similarity, resemblance (Genesis 1:11-12; Hebrews 4:15; 7:15). Kept apart from ὁμοίωσις (\"likeness\", Genesis 1:26; James 3:9) and ὁμοίωμα (Romans 8:3; Philippians 2:7), which will need its own gloss.")))

(lemma "ὁμοίωσις"
  (sense likeness
    (gloss "likeness")
    (why "Likeness (Genesis 1:26; James 3:9, people \"who have come to be according to [the] likeness of God\"). One gloss keeps James's echo of Genesis visible.")))

(lemma "ὄνομα"
  (sense name
    (gloss "name" "names")
    (why "A name.")))

(lemma "ὁράω"
  (sense see
    (gloss "see" "saw" "seen" "sees" "seeing")
    (why "To see. The table lemmatizes εἶδον (Swete's ἴδεν) and ἰδεῖν under ὁράω; in Genesis 1 the unlemmatized ἴδεν is supplied as ὁράω."))
  (sense appear
    (gloss "appear" "appeared" "appears" "appearing")
    (why "The aorist passive (ὤφθη, ὀφθήτω): to appear, be seen (Genesis 1:9; 1 Corinthians 15:5-8). \"Appear\" because English \"was seen\" loses the sense of showing itself."))
  (sense behold
    (gloss "behold")
    (why "The particle ἰδού, which the table lemmatizes under ὁράω: \"behold\" everywhere (Genesis 1:29, 31; 3:22; Matthew 1:20), never dropped and never \"look\" or \"see\", so it is recognizable at every use.")))

(lemma "ὅρασις"
  (sense sight
    (gloss "sight")
    (why "Seeing, sight, appearance (Genesis 2:9, \"beautiful for sight\"; Revelation 4:3). Visions (Acts 2:17) may become their own sense; ὅραμα will take \"vision\".")))

(lemma "ὅς"
  (sense which
    (gloss "which" "who" "whom" "whose")
    (why "The relative pronoun. The English form follows the referent: \"who/whom\" for persons, \"which\" for things.")))

(lemma "ὅσος"
  (sense as-many-as
    (gloss "as many as" "as much as")
    (why "As many as, as much as (Genesis 1:31, \"all the [things] as many as he made\"; John 1:12, \"as many as received him\").")))

(lemma "ὀστέον"
  (sense bone
    (gloss "bone" "bones")
    (why "Bone (Genesis 2:23; Luke 24:39). The contracted form ὀστοῦν is the same lemma.")))

(lemma "ὅτε"
  (sense when
    (gloss "when")
    (why "The temporal conjunction \"when\".")))

(lemma "ὅτι"
  (sense that
    (gloss "that")
    (why "Introducing what is seen, known or said: \"that\" (Genesis 1:4, God saw ... that [it was] good)."))
  (sense because
    (gloss "because")
    (why "Causal: \"because\" (Genesis 2:3, 23; 3:10, 14, 17, 19, 20). \"For\" is kept for γάρ, so causal ὅτι takes \"because\".")))

(lemma "οὐ"
  (sense not
    (gloss "not")
    (why "The plain negative of fact, always \"not\". English needs \"do\" to negate a simple past (\"did not overtake\"); that \"did\" is part of the verb's tense, aligned with the verb, not a supplied word.")))

(lemma "οὗ"
  (sense where
    (gloss "where")
    (why "The adverb \"where\", lemmatized separately from the relative pronoun ὅς as in the New Testament table (Matthew 2:9). Genesis 2:11 has the table's guess ὅς overridden to οὗ.")))

(lemma "οὐδέ"
  (sense not-even
    (gloss "not even")
    (why "οὐ plus δέ. With a numeral or a single word it is emphatic, \"not even\" (John 1:3)."))
  (sense nor
    (gloss "nor")
    (why "Joining a further negative clause: \"nor\" (Genesis 3:3; Matthew 6:26).")))

(lemma "οὐρανός"
  (sense heaven
    (gloss "heaven" "heavens")
    (why "Heaven, the sky. Singular \"heaven\", plural \"heavens\", following the Greek number: Genesis 1 in the Septuagint is singular throughout (Hebrew has a plural-form noun), while Matthew often has the plural. \"Sky\" is not used, so the one word can be traced from \"the birds of the heaven\" to \"the kingdom of the heavens\".")))

(lemma "οὗτος"
  (sense this
    (gloss "this" "these")
    (why "The near demonstrative. Used alone of a person, English needs a noun after it, supplied in brackets: \"this [one]\". Never turned into \"he\" or \"she\" (owner's rule): Genesis 2:23 and 3:12, 20 αὕτη is \"this [one]\".")))

(lemma "οὕτω"
  (sense so
    (gloss "so")
    (why "Thus, so. καὶ ἐγένετο οὕτως, \"and it came to be so\" (Genesis 1).")))

(lemma "ὀφθαλμός"
  (sense eye
    (gloss "eye" "eyes")
    (why "Eye.")))

(lemma "ὄφις"
  (sense serpent
    (gloss "serpent" "serpents")
    (why "A snake, serpent (Genesis 3; Matthew 10:16; 2 Corinthians 11:3; Revelation 12:9). \"Serpent\" rather than \"snake\" for the link with Revelation's \"the ancient serpent\".")))

(lemma "παράδεισος"
  (sense paradise
    (gloss "paradise")
    (why "An enclosed park or garden; the Septuagint's word for the garden of Eden. Kept as \"paradise\" in both layers (not \"garden\", which belongs to κῆπος, John 18:1) so the New Testament's paradise (Luke 23:43; 2 Corinthians 12:4; Revelation 2:7, \"the tree of the life which is in the paradise of God\") is visibly the same place-word as Genesis 2-3.")))

(lemma "πᾶς"
  (sense all
    (gloss "all")
    (why "With a plural, with the article, or used alone: \"all\" (\"all the earth\", \"all the beasts\")."))
  (sense every
    (gloss "every")
    (why "With a singular noun without the article: \"every\" (πᾶν ξύλον, \"every tree\"; πᾶσαν ψυχήν, \"every soul\").")))

(lemma "πατήρ"
  (sense father
    (gloss "father" "fathers")
    (why "Father.")))

(lemma "πέμπτος"
  (sense fifth
    (gloss "fifth")
    (why "(Supplied in Genesis 1:23.) The ordinal \"fifth\".")))

(lemma "περίζωμα"
  (sense apron
    (gloss "apron" "aprons")
    (why "(LXX, supplied.) Something girded around the waist, an apron or loincloth (Genesis 3:7). Not in the New Testament; ζώνη will take \"belt\".")))

(lemma "περιπατέω"
  (sense walk
    (gloss "walk" "walks" "walked" "walking")
    (why "To walk, walk about; figuratively, to live (Romans 6:4), kept as \"walk\" there too.")))

(lemma "πέτομαι"
  (sense fly
    (gloss "fly" "flies" "flew" "flying")
    (why "(Supplied in Genesis 1:20.) To fly (Revelation 4:7; 14:6).")))

(lemma "πετεινός"
  (sense bird
    (gloss "bird" "birds")
    (why "Winged; as a noun, a bird (Genesis 1-2; Matthew 6:26, \"the birds of the heaven\"). Some forms supplied by hand.")))

(lemma "πηγή"
  (sense spring
    (gloss "spring" "springs")
    (why "A spring, fountain (Genesis 2:6; John 4:14). Genesis 2:6 has a spring where translations from the Hebrew have a mist.")))

(lemma "πλάσσω"
  (sense form
    (gloss "form" "formed" "forms" "forming")
    (why "(Supplied in Genesis 2, where the forms are LXX-only.) To form, mold, as a potter (Romans 9:20; 1 Timothy 2:13, \"Adam was formed first\"). \"Form\" keeps it apart from ποιέω \"make\" and κτίζω \"create\".")))

(lemma "πλευρά"
  (sense side
    (gloss "side" "sides")
    (why "(Supplied in Genesis 2:21.) The side of the body, a rib. \"Side\" because John 19:34 (the soldier pierced his πλευράν) and 20:20-27 need \"side\", and one gloss keeps the old link between the woman taken from Adam's side and the blood and water from Christ's. The Hebrew word (tsela') is also \"side\" elsewhere (Exodus 26:20). The owner may prefer \"rib\" here (Genesis book notes).")))

(lemma "πληθύνω"
  (sense multiply
    (gloss "multiply" "multiplied" "multiplies" "multiplying")
    (why "To multiply; middle/passive, to be multiplied, increase in number (Genesis 1:22, 28; Acts 6:7). The passive forms are rendered with intransitive English \"multiply\". Genesis 3:16 πληθύνων πληθυνῶ is \"multiplying I will multiply\".")))

(lemma "πληρόω"
  (sense fill
    (gloss "fill" "filled" "fills" "filling")
    (why "To fill, and so to fulfill. \"Fill\" in Genesis 1:22, 28. Whether \"fulfill\" (Matthew 1:22) is a separate sense or kept as \"fill\" is for the owner when Matthew is translated.")))

(lemma "πνεῦμα"
  (sense spirit
    (gloss "spirit" "spirits")
    (why "Spirit, wind, breath. \"Spirit\" in Genesis 1:2 (πνεῦμα θεοῦ). Capitalization is an interpretation the Greek does not mark; Genesis 1:2 keeps lowercase \"spirit\" in both layers (see the note there), and the owner should rule on capitalization for the New Testament (\"the Holy Spirit\").")))

(lemma "πνοή"
  (sense breath
    (gloss "breath")
    (why "Breath, blowing (Genesis 2:7; Acts 17:25, God gives to all life and breath).")))

(lemma "ποιέω"
  (sense make
    (gloss "make" "made" "makes" "making")
    (why "To make, produce. Genesis 1:1 ἐποίησεν is \"made\", not \"created\", which is kept for κτίζω (Matthew 19:4 has both: ὁ κτίσας ... ἐποίησεν). Also \"make fruit\" (Genesis 1:11-12; Revelation 22:2)."))
  (sense do
    (gloss "do" "did" "done" "does" "doing")
    (why "To do, perform an act (Genesis 3:13-14, \"you did this\"). English cannot say \"make this\" of a deed.")))

(lemma "πονηρός"
  (sense evil
    (gloss "evil")
    (why "Evil, bad (Genesis 2:9, 17; 3:5, 22). κακός will need its own gloss (\"bad\") so the two do not merge.")))

(lemma "πορεύομαι"
  (sense go
    (gloss "go" "goes" "went" "going" "gone")
    (why "To go, travel; figuratively to live (Luke 1:6). Genesis 3:14 πορεύσῃ, \"you will go\".")))

(lemma "ποταμός"
  (sense river
    (gloss "river" "rivers")
    (why "A river (Genesis 2:10-14; Revelation 22:1).")))

(lemma "ποτέ"
  (sense ever
    (gloss "ever")
    (why "Enclitic \"at some time, ever\". After μή (Genesis 3:22, printed as two words in Swete) it is \"lest ... ever\". The past \"once, formerly\" (Ephesians 2:2) becomes its own sense.")))

(lemma "ποτίζω"
  (sense water
    (gloss "water" "waters" "watered" "watering")
    (why "To give to drink, to water (Genesis 2:6, 10; 1 Corinthians 3:6-8, Apollos watered). English \"water\" serves; the noun ὕδωρ shares the word, and the alignment shows which is which.")))

(lemma "ποῦ"
  (sense where
    (gloss "where")
    (why "The interrogative \"where?\" (Genesis 3:9).")))

(lemma "πράσινος"
  (sense leek-green
    (gloss "leek-green")
    (why "(LXX, supplied.) Leek-green, the color of a leek (πράσον); ὁ λίθος ὁ πράσινος (Genesis 2:12) is a green stone, where translations from the Hebrew have onyx.")))

(lemma "πρό"
  (sense before
    (gloss "before")
    (why "Before, of time or place. πρὸ τοῦ + infinitive is \"before [it] ...\".")))

(lemma "πρός"
  (sense with
    (gloss "with")
    (why "With the accusative after a verb of being, πρός marks presence face to face in someone's company (Mark 6:3, πρὸς ἡμᾶς; 1 John 1:2)."))
  (sense to
    (gloss "to")
    (why "With the accusative after a verb of motion or direction: \"to\" (Genesis 2:19, 22, brought to Adam; 3:16, your turning [is] to your man).")))

(lemma "πρόσωπον"
  (sense face
    (gloss "face" "faces")
    (why "Face; ἀπὸ προσώπου, \"from [the] face of\", is kept in the literal layer (Genesis 3:8).")))

(lemma "προσκολλάω"
  (sense be-joined
    (gloss "be joined")
    (why "To join, glue to; the future passive προσκολληθήσεται (Genesis 2:24; Mark 10:7; Ephesians 5:31) is \"will be joined\", keeping the passive form. Matthew 19:5 and 1 Corinthians 6:16 use the simple verb κολλάω, which will need its own gloss (perhaps \"be glued\") so the difference shows.")))

(lemma "πρωΐ"
  (sense morning
    (gloss "morning")
    (why "Early, in the morning; as a noun, morning (Genesis 1).")))

(lemma "πτέρνα"
  (sense heel
    (gloss "heel")
    (why "Heel (Genesis 3:15; John 13:18, quoting Psalm 41:9).")))

(lemma "πτερωτός"
  (sense winged
    (gloss "winged")
    (why "(LXX, supplied.) Winged (Genesis 1:21). Not in the New Testament.")))

(lemma "ῥάπτω"
  (sense sew
    (gloss "sew" "sewed" "sewn" "sewing")
    (why "(LXX, supplied.) To sew, stitch (Genesis 3:7). Not in the New Testament (ἐπιράπτω, Mark 2:21, is related).")))

(lemma "ῥομφαία"
  (sense sword
    (gloss "sword" "swords")
    (why "A large sword (Genesis 3:24; Luke 2:35; Revelation 1:16). It shares \"sword\" with μάχαιρα, the commoner New Testament word; the owner should decide whether μάχαιρα takes \"short sword\" or the two share the gloss.")))

(lemma "σάρξ"
  (sense flesh
    (gloss "flesh")
    (why "Flesh, and the human being as flesh (Genesis 2:23-24; John 1:14).")))

(lemma "σημεῖον"
  (sense sign
    (gloss "sign" "signs")
    (why "A sign, mark (Genesis 1:14; John 2:11).")))

(lemma "σκοτία"
  (sense darkness
    (gloss "darkness")
    (why "σκοτία and σκότος are near synonyms and both take \"darkness\". John 1:5 has σκοτία where Genesis 1:2-5 has σκότος, so John's echo of Genesis is in the thought, not the word; the alignment shows which noun the Greek uses.")))

(lemma "σκότος"
  (sense darkness
    (gloss "darkness")
    (why "Darkness (Genesis 1:2-18; 2 Corinthians 4:6, \"out of darkness light will shine\", Paul's echo of Genesis 1:3). Shares \"darkness\" with σκοτία; see that entry.")))

(lemma "σπείρω"
  (sense sow
    (gloss "sow" "sows" "sowed" "sown" "sowing")
    (why "(Supplied in Genesis 1:11-12, 29.) To sow (Matthew 13:3). Genesis has σπεῖρον σπέρμα, \"sowing seed\", where translations from the Hebrew have \"yielding seed\"; the Greek repeats the root, and so does the literal layer.")))

(lemma "σπέρμα"
  (sense seed
    (gloss "seed" "seeds")
    (why "Seed, and so offspring. Kept as \"seed\" in both layers, never \"offspring\": Galatians 3:16 argues from the singular σπέρμα, and Genesis 3:15 \"between your seed and her seed\" must stay readable that way.")))

(lemma "σπόριμος"
  (sense sowable
    (gloss "sowable")
    (why "Fit for sowing, sown (Genesis 1:29; Matthew 12:1, \"the sown [fields]\"). \"Sowable\" keeps it apart from σπείρω \"sow\" while showing the root.")))

(lemma "στεναγμός"
  (sense groaning
    (gloss "groaning" "groanings")
    (why "A groan, groaning (Genesis 3:16; Acts 7:34; Romans 8:26). Genesis 3:16 has \"your groaning\" where translations from the Hebrew have \"your conception\" or \"childbearing\".")))

(lemma "στερέωμα"
  (sense firmament
    (gloss "firmament")
    (why "Something made firm or solid; in Genesis 1 the firmament that separates the waters. Colossians 2:5 (\"the firmness of your faith\") will need its own sense.")))

(lemma "στῆθος"
  (sense breast
    (gloss "breast")
    (why "(Supplied in Genesis 3:14.) Chest, breast (Luke 18:13; John 13:25).")))

(lemma "στρέφω"
  (sense turn
    (gloss "turn" "turns" "turned" "turning")
    (why "(Supplied in Genesis 3:24.) To turn; middle, to turn oneself (Genesis 3:24, the turning sword; Matthew 5:39).")))

(lemma "σύ"
  (sense pronoun
    (gloss "you" "your" "yours" "yourself")
    (why "The second-person pronoun, singular and plural (the table lemmatizes ὑμεῖς under σύ). English \"you\" cannot show number; the alignment shows it, and a note marks places where the number matters (Genesis 2:17).")))

(lemma "συκῆ"
  (sense fig-tree
    (gloss "fig tree" "fig trees")
    (why "The fig tree (Genesis 3:7; Matthew 21:19). φύλλα συκῆς is \"leaves of [a] fig tree\".")))

(lemma "συνάγω"
  (sense gather
    (gloss "gather" "gathered" "gathers" "gathering")
    (why "(Some forms supplied.) To gather, bring together (Genesis 1:9; Matthew 3:12). The noun συναγωγή shares the root and the English (\"gathering\").")))

(lemma "συναγωγή"
  (sense gathering
    (gloss "gathering" "gatherings")
    (why "A gathering, a collected body (Genesis 1:9, the waters). The Jewish assembly and its building, \"synagogue\", will be a separate sense in the New Testament; the owner may instead want \"gathering\" there too.")))

(lemma "συντελέω"
  (sense complete
    (gloss "complete" "completed" "completes" "completing")
    (why "(Some forms supplied.) To bring to an end, complete (Genesis 2:1-2; Hebrews 8:8, \"I will complete a new covenant\"). Against τελειόω, which will take \"perfect\", and τελέω \"finish\".")))

(lemma "σύστημα"
  (sense collection
    (gloss "collection" "collections")
    (why "(LXX, supplied; Swete prints συστέματα.) A whole made of parts, a body or collection (Genesis 1:10, \"the collections of the waters\"). Not in the New Testament.")))

(lemma "τάσσω"
  (sense appoint
    (gloss "appoint" "appointed" "appoints" "appointing")
    (why "(Supplied in Genesis 3:24.) To station, appoint, put in order (Acts 13:48; Romans 13:1). \"Appoint\" serves both the cherubim posted at Eden and the authorities appointed by God.")))

(lemma "τέ"
  (sense both
    (gloss "both")
    (why "τε ... καί, \"both ... and\" (Genesis 2:25; 3:8)."))
  (sense and
    (gloss "and")
    (why "τε alone, a light \"and\" joining a clause (Genesis 2:20). It shares \"and\" with καί; the alignment shows which.")))

(lemma "τέκνον"
  (sense child
    (gloss "child" "children")
    (why "A child (Genesis 3:16; John 1:12).")))

(lemma "τέσσαρες"
  (sense four
    (gloss "four")
    (why "The numeral \"four\".")))

(lemma "τέταρτος"
  (sense fourth
    (gloss "fourth")
    (why "The ordinal \"fourth\".")))

(lemma "τετράπους"
  (sense four-footed
    (gloss "four-footed")
    (why "Four-footed; as a noun, a quadruped (Genesis 1:24; Acts 10:12; Romans 1:23).")))

(lemma "τηρέω"
  (sense watch
    (gloss "watch" "watches" "watched" "watching")
    (why "(Some forms supplied.) To watch, keep watch on (Matthew 27:36, 54). Genesis 3:15 τηρήσει / τηρήσεις, \"will watch\", where translations from the Hebrew have \"bruise\" or \"strike\". The commoner New Testament sense \"keep\" (John 14:15) becomes its own sense; φυλάσσω takes \"guard\".")))

(lemma "Τίγρις"
  (sense name
    (gloss "Tigris")
    (why "(LXX, supplied.) The river, by its Greek and traditional English name (Genesis 2:14), where the Hebrew has Hiddekel.")))

(lemma "τίθημι"
  (sense put
    (gloss "put" "puts" "putting")
    (why "To put, place, set (Genesis 1:17; 2:8, 15; 3:15). \"Lay down\" (John 10:11) will be its own sense.")))

(lemma "τίκτω"
  (sense bear
    (gloss "bear" "bears" "bore" "bearing")
    (why "To bear, give birth to (Genesis 3:16; Luke 2:7; John 16:21). γεννάω will take \"beget\" / \"be born\".")))

(lemma "τίς"
  (sense who
    (gloss "who" "what" "whom")
    (why "The interrogative pronoun: \"who\" of persons, \"what\" of things (Genesis 2:19; 3:11, 13)."))
  (sense why
    (gloss "why")
    (why "τί used adverbially, \"why\" (Genesis 3:1, τί ὅτι, \"why [is it] that\"; Matthew 6:28).")))

(lemma "τρίβολος"
  (sense thistle
    (gloss "thistle" "thistles")
    (why "A thistle, caltrop (Genesis 3:18; Matthew 7:16; Hebrews 6:8, \"thorns and thistles\", echoing Genesis).")))

(lemma "τρίτος"
  (sense third
    (gloss "third")
    (why "The ordinal \"third\".")))

(lemma "τρυφή"
  (sense delight
    (gloss "delight")
    (why "(Supplied in Genesis 3:23-24.) Luxury, delight, soft living (Luke 7:25; 2 Peter 2:13). In Genesis 3:23-24 the Septuagint translates the name Eden by its meaning: \"the paradise of the delight\". \"Delight\" (not \"luxury\") because it is a translation of the place name; the New Testament uses may want \"luxury\" as a second sense.")))

(lemma "ὕδωρ"
  (sense water
    (gloss "water" "waters")
    (why "Water. The Greek number is kept: singular \"water\" in Genesis 1:2-9, plural \"waters\" from 1:10.")))

(lemma "ὑπνόω"
  (sense sleep
    (gloss "sleep" "slept" "sleeps" "sleeping")
    (why "(LXX, supplied.) To fall asleep, sleep (Genesis 2:21). Not in the New Testament, which uses καθεύδω and κοιμάομαι; those will need distinct glosses.")))

(lemma "ὑποκάτω"
  (sense under
    (gloss "under")
    (why "Under, below (Genesis 1:7, 9; Mark 6:11).")))

(lemma "φαίνω"
  (sense shine
    (gloss "shine" "shines" "shining" "shone")
    (why "Active: to shine, give light. Passive \"appear\" becomes its own sense. The present is rendered with the English progressive (\"is shining\") to keep its ongoing aspect apart from the aorist; an infinitive is plain \"to shine\" (Genesis 1:15, 17).")))

(lemma "φαῦσις"
  (sense illumination
    (gloss "illumination")
    (why "(LXX, supplied.) A giving of light, illumination (Genesis 1:14-15). Not in the New Testament.")))

(lemma "Φεισών"
  (sense name
    (gloss "Pishon")
    (why "(LXX, supplied.) The first river of Genesis 2:11, given its traditional English name; the Greek spells it Φεισών (Pheison).")))

(lemma "φλόγινος"
  (sense flaming
    (gloss "flaming")
    (why "(LXX, supplied.) Flaming, fiery (Genesis 3:24). φλόξ \"flame\" is in the New Testament (Acts 7:30).")))

(lemma "φοβέω"
  (sense fear
    (gloss "fear" "feared" "fears" "fearing")
    (why "(Supplied in Genesis 3:10.) Lemma form as in the New Testament table. Middle/passive: to fear, be afraid (Genesis 3:10, \"I feared\"). \"Fear\" also for reverence (Luke 1:50).")))

(lemma "φρόνιμος"
  (sense prudent
    (gloss "prudent")
    (why "(Supplied in Genesis 3:1, a superlative.) Prudent, sensible, shrewd. Genesis 3:1 calls the serpent φρονιμώτατος, \"most prudent\", where translations from the Hebrew have \"crafty\"; Matthew 10:16 (\"be prudent as the serpents\") uses the same word. One gloss keeps the echo.")))

(lemma "φυλάσσω"
  (sense guard
    (gloss "guard" "guards" "guarded" "guarding")
    (why "To guard, keep watch over (Genesis 2:15; 3:24; Luke 2:8). \"Guard\" so that τηρέω can keep \"keep\" / \"watch\". Keeping commandments (Matthew 19:20) will be checked against it.")))

(lemma "φύλλον"
  (sense leaf
    (gloss "leaf" "leaves")
    (why "A leaf (Genesis 3:7; Revelation 22:2).")))

(lemma "φυτεύω"
  (sense plant
    (gloss "plant" "plants" "planted" "planting")
    (why "To plant (Genesis 2:8; 1 Corinthians 3:6, Paul planted).")))

(lemma "φωνή"
  (sense voice
    (gloss "voice" "voices")
    (why "Voice, sound. \"Voice\" in Genesis 3:8-17 (also \"the voice of your woman\", 3:17). \"Sound\" (John 3:8) may become its own sense.")))

(lemma "φῶς"
  (sense light
    (gloss "light" "lights")
    (why "Light itself; φωστήρ (a light-giver, a luminary, Genesis 1:14) gets its own gloss.")))

(lemma "φωστήρ"
  (sense luminary
    (gloss "luminary" "luminaries")
    (why "(Some forms supplied.) A light-giver, a luminary (Genesis 1:14-16; Philippians 2:15, \"you shine as luminaries in the world\"). Kept apart from φῶς \"light\" in both layers.")))

(lemma "χείρ"
  (sense hand
    (gloss "hand" "hands")
    (why "Hand. Greek often has the article where English has a possessive (τὴν χεῖρα, Genesis 3:22): the literal layer keeps \"the hand\".")))

(lemma "Χερούβ"
  (sense cherub
    (gloss "cherub" "cherubim")
    (why "(Supplied in Genesis 3:24; Swete prints τὰ χερουβίν.) The Hebrew loanword, lemmatized as in the New Testament table (Hebrews 9:5); \"cherubim\" for the plural form.")))

(lemma "χιτών"
  (sense tunic
    (gloss "tunic" "tunics")
    (why "The tunic, the garment worn next to the skin (Genesis 3:21; John 19:23). Against ἱμάτιον, which will take \"garment\" or \"cloak\".")))

(lemma "χλωρός"
  (sense green
    (gloss "green")
    (why "Green, pale green (Genesis 1:30; 2:5; Mark 6:39); \"pale\" of the horse in Revelation 6:8 may be its own sense.")))

(lemma "χοῦς"
  (sense dust
    (gloss "dust")
    (why "Dust, loose soil (Genesis 2:7; Mark 6:11). Related to χοϊκός, \"made of dust\" (1 Corinthians 15:47-49), which will take \"dusty\" or \"of dust\".")))

(lemma "χόρτος"
  (sense grass
    (gloss "grass")
    (why "Grass, green plants (Genesis 1:11-12, 29-30; Matthew 6:30).")))

(lemma "χρυσίον"
  (sense gold
    (gloss "gold")
    (why "Gold. χρυσός will share \"gold\" with a note if needed.")))

(lemma "χωρίς"
  (sense apart-from
    (gloss "apart from")
    (why "Separation: \"apart from\", not \"without\", which is kept for ἄνευ.")))

(lemma "ψυχή"
  (sense soul
    (gloss "soul" "souls")
    (why "Soul, the life of a living being, a living being itself. \"Soul\" everywhere in both layers, including the animals of Genesis 1 (ψυχὴ ζῶσα \"living soul\", 1:20-24, 30): the Greek uses the same phrase for animals and for the human in 2:7, and Paul quotes 2:7 in 1 Corinthians 15:45 (\"the first human, Adam, came to be into a living soul\"). \"Creature\" or \"being\" would hide that. \"Life\" (Matthew 16:25) is the owner's call when the New Testament is translated.")))

(lemma "ὡραῖος"
  (sense beautiful
    (gloss "beautiful")
    (why "(Supplied in Genesis 2:9; 3:6.) Timely, ripe, and so beautiful (Matthew 23:27; Acts 3:2, the Beautiful Gate; Romans 10:15).")))

(lemma "ὡς"
  (sense as
    (gloss "as")
    (why "Comparison: \"as\" (Genesis 3:5, 22). ὅμοιος takes \"like\".")))

(lemma "ὥστε"
  (sense so-as
    (gloss "so as")
    (why "Result or purpose with the infinitive: \"so as to\" (Genesis 1:15, 17). \"So that\" is kept for ἵνα.")))
