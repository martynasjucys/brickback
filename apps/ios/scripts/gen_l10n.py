#!/usr/bin/env python3
"""Generate Localizable.xcstrings + L.swift from one compact table.

One source of truth keeps the String Catalog keys and the typed `L` accessors in lockstep and
applies the format rules uniformly (positional %1$@/%1$lld for multi-arg, %% for a literal
percent, plural variation nodes). Run from anywhere; it writes into the app target.
"""
import json, os

# apps/ios/BrickBack, resolved relative to this script (apps/ios/scripts/gen_l10n.py).
APP = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "BrickBack"))

entries = []  # (kind, key, payload)

def plain(key, en, lt):
    entries.append(("plain", key, {"en": en, "lt": lt}))

def fmt(key, sig, default, en, lt):
    # sig: Swift param list; default: Swift interpolation used as defaultValue (English fallback)
    entries.append(("fmt", key, {"sig": sig, "default": default, "en": en, "lt": lt}))

def plural(key, sig, default, en, lt):
    # en/lt: dicts of CLDR category -> value (%lld for the count)
    entries.append(("plural", key, {"sig": sig, "default": default, "en": en, "lt": lt}))

# ─────────────────────────── COMMON ───────────────────────────
plain("navRebuilds", "Rebuilds", "Surinkimai")
plain("navParty", "Party", "Sesija")
plain("navProfile", "Profile", "Profilis")
plain("couldntLoad", "Couldn't load", "Nepavyko įkelti")
plain("ok", "OK", "Gerai")
plain("cancel", "Cancel", "Atšaukti")
plain("done", "Done", "Atlikta")
plain("remove", "Remove", "Šalinti")
plain("unknownColor", "Unknown", "Nežinoma")
plain("noMatches", "No matches", "Nėra atitikmenų")
plain("everyPartAccountedFor", "Every part for this set is accounted for.",
      "Visos šio rinkinio dalys suskaičiuotos.")
plain("rebuildGone", "This rebuild no longer exists.", "Šio surinkimo nebėra.")

# ─────────────────────────── HOME ───────────────────────────
plain("addASet", "Add a set", "Pridėti rinkinį")
plain("homeEmptyTitle", "No rebuilds yet", "Kol kas nėra surinkimų")
plain("homeEmptyMessage", "Search a set to start counting its parts back into place.",
      "Ieškokite rinkinio ir pradėkite skaičiuoti jo dalis.")
plain("homeNoMatchTitle", "No matching sets", "Nėra tinkamų rinkinių")
plain("homeNoMatchMessage", "None of your added sets match the current filter.",
      "Nė vienas pridėtas rinkinys neatitinka filtro.")
plain("clearFilter", "Clear filter", "Išvalyti filtrą")
plain("filterSets", "Filter sets", "Filtruoti rinkinius")
plural("filterSetsActive", "_ count: Int", "\\(count) active",
       {"one": "Filter sets, %lld active", "other": "Filter sets, %lld active"},
       {"one": "Filtruoti rinkinius, %lld aktyvus", "few": "Filtruoti rinkinius, %lld aktyvūs",
        "other": "Filtruoti rinkinius, %lld aktyvių"})
plain("continueBuilding", "Continue building", "Tęsti surinkimą")
plain("allSets", "All sets", "Visi rinkiniai")
plain("verifiedBadge", "Verified", "Patvirtinta")
plain("filter", "Filter", "Filtras")
plain("close", "Close", "Uždaryti")
plain("statusLabel", "Status", "Būsena")
plain("themeLabel", "Theme", "Tema")
plain("themeFilterHint", "Add sets to filter them by LEGO theme.",
      "Pridėkite rinkinių, kad galėtumėte filtruoti pagal LEGO temą.")
plain("clearAll", "Clear all", "Išvalyti viską")
plain("filterAll", "All", "Visi")
plain("filterIncomplete", "Incomplete", "Nebaigti")
plain("filterComplete", "Complete", "Baigti")
fmt("partsHaveTotal", "have: Int, total: Int", "\\(have) / \\(total) parts",
    "%1$lld / %2$lld parts", "%1$lld / %2$lld dalys")
plural("completeParts", "_ count: Int", "Complete · \\(count) parts",
       {"one": "Complete · %lld part", "other": "Complete · %lld parts"},
       {"one": "Baigta · %lld dalis", "few": "Baigta · %lld dalys", "other": "Baigta · %lld dalių"})
fmt("partsProgress", "have: Int, total: Int, pct: Int", "\\(have) / \\(total) parts · \\(pct)%",
    "%1$lld / %2$lld parts · %3$lld%%", "%1$lld / %2$lld dalys · %3$lld%%")

# ─────────────────────────── SEARCH ───────────────────────────
plain("searchHint", "Search by set number or name…", "Ieškokite pagal rinkinio numerį ar pavadinimą…")
plain("searchEmptyTitle", "Search the catalog", "Ieškokite kataloge")
plain("searchEmptyMessage",
      "Find a LEGO set by name or number, e.g. “911” or “Millennium Falcon”.",
      "Raskite LEGO rinkinį pagal pavadinimą ar numerį, pvz., „911“ arba „Millennium Falcon“.")
plain("searchFailed", "Search failed", "Paieška nepavyko")
plain("searchNoMatchesMessage", "Try a different name or set number.",
      "Pabandykite kitą pavadinimą ar rinkinio numerį.")
plural("partsCount", "_ count: Int", "\\(count) parts",
       {"zero": "no parts", "one": "%lld part", "other": "%lld parts"},
       {"zero": "nėra dalių", "one": "%lld dalis", "few": "%lld dalys", "other": "%lld dalių"})

# ─────────────────────────── SET DETAIL ───────────────────────────
plain("setHeader", "Set", "Rinkinys")
plain("setCouldntLoad", "Couldn't load set", "Nepavyko įkelti rinkinio")
plain("uniqueParts", "Unique parts", "Unikalios dalys")
plain("minifigs", "Minifigs", "Minifigūrėlės")
plain("startSorting", "Start sorting", "Pradėti rūšiuoti")
plain("startSortingHint",
      "Adds a local copy you can sort offline. Add the same set again for a second physical copy.",
      "Prideda vietinę kopiją, kurią galite rūšiuoti neprisijungę. Pridėkite tą patį rinkinį dar kartą antrai fizinei kopijai.")
plain("couldntAddSet", "Couldn't add set", "Nepavyko pridėti rinkinio")

# ─────────────────────────── SET PARTS ───────────────────────────
plain("partsCouldntLoad", "Couldn't load parts", "Nepavyko įkelti dalių")
plain("partsEmptyTitle", "No parts", "Nėra dalių")
plain("partsEmptyMessage", "This set has no part list in the catalog.",
      "Šis rinkinys kataloge neturi dalių sąrašo.")
plural("uniquePartsCount", "_ count: Int", "\\(count) unique parts",
       {"one": "%lld unique part", "other": "%lld unique parts"},
       {"one": "%lld unikali dalis", "few": "%lld unikalios dalys", "other": "%lld unikalių dalių"})

# ─────────────────────────── SET MINIFIGS ───────────────────────────
plain("minifigsCouldntLoad", "Couldn't load minifigs", "Nepavyko įkelti minifigūrėlių")
plain("minifigsEmptyTitle", "No minifigs", "Nėra minifigūrėlių")
plain("minifigsEmptyMessage", "This set has no minifigs.", "Šis rinkinys neturi minifigūrėlių.")

# ─────────────────────────── SIGN IN ───────────────────────────
plain("signInTitle", "Sign in", "Prisijungti")
plain("signInHeadline", "Sync across your devices", "Sinchronizuokite tarp įrenginių")
plain("signInSubtitle",
      "Sign in to unlock premium cloud sync and party mode. Everything else works offline — you can skip this.",
      "Prisijunkite, kad atrakintumėte premium sinchronizavimą ir bendrą režimą. Visa kita veikia neprisijungus — galite praleisti.")
plain("continueWithGoogle", "Continue with Google", "Tęsti su Google")
plain("emailHint", "you@example.com", "vardas@pastas.lt")
plain("emailSignInLink", "Email me a sign-in link", "Atsiųsti prisijungimo nuorodą el. paštu")
plain("emailSentConfirm", "Check your email for a sign-in link.",
      "Patikrinkite el. paštą – išsiuntėme prisijungimo nuorodą.")
plain("signInFooter", "We only use your account to sync your rebuilds. No spam.",
      "Paskyrą naudojame tik jūsų surinkimams sinchronizuoti. Jokio šlamšto.")
plain("emailInvalid", "Enter a valid email address.", "Įveskite galiojantį el. pašto adresą.")
plain("appleNoToken", "Apple sign-in returned no identity token.",
      "Apple prisijungimas negrąžino tapatybės žetono.")
plain("orDivider", "or", "arba")

# ─────────────────────────── PAYWALL ───────────────────────────
plain("cloudSyncTitle", "Cloud Sync", "Sinchronizavimas debesyje")
plain("premiumBadge", "PREMIUM", "PREMIUM")
plain("paywallHeadline",
      "Keep every rebuild in sync and backed up. Everything you've sorted so far comes with you.",
      "Visi surinkimai sinchronizuojami ir saugomi. Viskas, ką iki šiol surūšiavote, keliauja kartu.")
plain("turnOnCloudSync", "Turn on Cloud Sync", "Įjungti sinchronizavimą debesyje")
plain("paywallCtaHint", "You'll sign in first — your local rebuilds upload automatically.",
      "Pirmiausia prisijungsite — vietiniai surinkimai įkeliami automatiškai.")
plain("benefitSyncTitle", "Cloud sync", "Sinchronizavimas debesyje")
plain("benefitSyncBody", "Your rebuilds follow you to every device, always up to date.",
      "Surinkimai keliauja į kiekvieną įrenginį ir visada atnaujinti.")
plain("benefitUnlimitedTitle", "Unlimited rebuilds", "Neriboti surinkimai")
plain("benefitUnlimitedBody", "Sort as many sets at once as you like — no cap.",
      "Rūšiuokite tiek rinkinių vienu metu, kiek norite — be apribojimų.")
plain("benefitBackupTitle", "Safe backup", "Saugi atsarginė kopija")
plain("benefitBackupBody", "Never lose your progress if you lose your phone.",
      "Neprarasite progreso, net jei pamesite telefoną.")
plain("partyModeTitle", "Party mode", "Bendras režimas")
plain("benefitPartyBody", "Sort a big set together with friends in real time.",
      "Rūšiuokite didelį rinkinį kartu su draugais realiu laiku.")

# ─────────────────────────── PROFILE ───────────────────────────
plain("profileSubtitle", "Account & settings", "Paskyra ir nustatymai")
plain("statSetsBuilt", "Sets built", "Surinkti rinkiniai")
plain("statPartsCollected", "Parts collected", "Surinktos detalės")
plain("nameLabel", "Name", "Vardas")
plain("nameEditorTitle", "Your name", "Jūsų vardas")
plain("nameEditorSubtitle", "Shown to others in party mode.", "Rodomas kitiems bendrame režime.")
plain("nameEditorHint", "Enter a name", "Įveskite vardą")
plain("shuffleName", "Shuffle name", "Generuoti kitą vardą")
plain("save", "Save", "Išsaugoti")
plain("premium", "Premium", "Premium")
plain("active", "Active", "Aktyvu")
plain("free", "Free", "Nemokama")
plain("syncNow", "Sync now", "Sinchronizuoti dabar")
plain("language", "Language", "Kalba")
plain("languageSystem", "System", "Sistemos")
plain("languageEnglish", "English", "English")
plain("languageLithuanian", "Lietuvių", "Lietuvių")
plain("appearance", "Appearance", "Išvaizda")
plain("themeSystem", "System", "Sistemos")
plain("themeLight", "Light", "Šviesi")
plain("themeDark", "Dark", "Tamsi")
plain("signedIn", "Signed in", "Prisijungta")
plain("yourAccount", "Your account", "Jūsų paskyra")
plain("signOut", "Sign out", "Atsijungti")
plain("notSignedIn", "Not signed in", "Neprisijungta")
plain("profileSignInPrompt",
      "Sign in to unlock premium cloud sync and party mode. Everything else works offline.",
      "Prisijunkite, kad atrakintumėte premium sinchronizavimą ir bendrą režimą. Visa kita veikia neprisijungus.")
plain("partyModeBody", "Sort a big pile together in real time — join by code.",
      "Rūšiuokite didelę krūvą kartu realiu laiku — prisijunkite su kodu.")
plain("partyJoinTitle", "Join a party", "Prisijungti prie sesijos")
plain("partyTabSubtitle", "Join a friend's sort — or host your own.",
      "Prisijunkite prie draugo rūšiavimo arba surenkite savo.")
plain("partyHostNote",
      "Hosting a party is Premium — start one from a rebuild's counting screen.",
      "Sesijos surengimas yra Premium funkcija — pradėkite ją iš surinkimo skaičiavimo ekrano.")

# ─────────────────────────── COUNTING ───────────────────────────
plain("countNoInventoryTitle", "No inventory data", "Nėra dalių duomenų")
plain("countNoInventoryMessage", "The catalog has no part list for this set yet.",
      "Šis rinkinys kataloge dar neturi dalių sąrašo.")
plain("countAllSortedTitle", "All sorted!", "Viskas surūšiuota!")
fmt("countHaveOfPartsTypes", "have: Int, total: Int, types: Int",
    "\\(have) of \\(total) parts · \\(types) types",
    "%1$lld of %2$lld parts · %3$lld types", "%1$lld iš %2$lld dalių · %3$lld tipų")
plain("moreActions", "More actions", "Daugiau veiksmų")
plain("closeActions", "Close actions", "Uždaryti veiksmus")
plain("menuReview", "Review & verify", "Peržiūra ir tikrinimas")
plain("menuStartParty", "Start party", "Pradėti sesiją")
plain("menuSearchParts", "Search parts", "Ieškoti dalių")
plain("sortParty", "Sort party", "Bendras rūšiavimas")
plain("couldntStartParty", "Couldn't start party", "Nepavyko pradėti sesijos")
plain("allAccountedFor", "All accounted for", "Viskas suskaičiuota")
plain("step", "Step", "Žingsnis")
plain("viewOnBrickLink", "View on BrickLink", "Žiūrėti BrickLink")
plain("countSearchHint", "Search by name or code…", "Ieškokite pagal pavadinimą ar kodą…")
plain("countNoMatchesMessage", "Try a different name or part code.",
      "Pabandykite kitą pavadinimą ar dalies kodą.")
plain("groupByColor", "Color", "Spalva")
plain("groupByType", "Type", "Tipas")
plain("groupByStatus", "Progress", "Progresas")
plain("groupByNone", "None", "Nėra")
plain("viewSettings", "View settings", "Rodinio nustatymai")
plain("groupBy", "Group by", "Grupuoti pagal")
plain("remainingOnly", "Remaining only", "Tik likusios")
plain("remainingOnlyHint",
      "Hide the parts you've already counted in full — show only what's left to find.",
      "Slėpti pilnai suskaičiuotas dalis — rodyti tik tai, ką dar reikia rasti.")
plain("showExtras", "Show extra parts", "Rodyti atsargines detales")
plain("showExtrasBody",
      "Include the spare pieces the set ships with — counted separately, not part of completion.",
      "Įtraukti atsargines detales, kurias pridėjo gamintojas — skaičiuojamos atskirai, neįeina į užbaigtumą.")
plain("noExtras", "This set has no extra parts.", "Šis rinkinys neturi atsarginių detalių.")

# ─────────────────────────── SECTION TITLES (domain fallbacks) ───────────────────────────
plain("sectionAllParts", "All parts", "Visos detalės")
plain("sectionRemaining", "Remaining", "Liko")
plain("sectionComplete", "Complete", "Surinkta")
plain("sectionExtras", "Extras", "Atsarginės")
plain("sectionOther", "Other", "Kita")

# ─────────────────────────── REVIEW ───────────────────────────
plain("missingParts", "Missing parts", "Trūkstamos dalys")
plain("shareMissingParts", "Share missing parts", "Bendrinti trūkstamas dalis")
plain("reviewNothingMissing", "Nothing missing", "Nieko netrūksta")
fmt("reviewPartsFound", "found: Int, needed: Int", "\\(found) of \\(needed) parts found",
    "%1$lld of %2$lld parts found", "Rasta %1$lld iš %2$lld dalių")
plain("allPartsAccountedFor", "All parts accounted for", "Visos dalys suskaičiuotos")
plain("minifiguresSection", "Minifigures", "Minifigūrėlės")
plain("viewReport", "View report", "Peržiūrėti ataskaitą")
plain("reverify", "Re-verify", "Tikrinti iš naujo")
plain("markAsVerified", "Mark as verified", "Pažymėti kaip patvirtintą")
plural("typesStillMissing", "_ n: Int", "\\(n) types still missing",
       {"one": "%lld type still missing", "other": "%lld types still missing"},
       {"one": "dar trūksta %lld tipo", "few": "dar trūksta %lld tipų", "other": "dar trūksta %lld tipų"})
plural("typeCount", "_ n: Int", "\\(n) types",
       {"one": "%lld type", "other": "%lld types"},
       {"one": "%lld tipas", "few": "%lld tipai", "other": "%lld tipų"})
plural("notExportableText", "_ n: Int", "\\(n) parts have no BrickLink mapping and won't be in the export.",
       {"one": "%lld part has no BrickLink mapping and won't be in the export.",
        "other": "%lld parts have no BrickLink mapping and won't be in the export."},
       {"one": "%lld dalis neturi BrickLink atitikmens ir nebus eksportuota.",
        "few": "%lld dalys neturi BrickLink atitikmens ir nebus eksportuotos.",
        "other": "%lld dalių neturi BrickLink atitikmens ir nebus eksportuota."})
fmt("needQty", "_ qty: Int", "need \\(qty)", "need %lld", "reikia %lld")
fmt("minifigPresent", "have: Int, needed: Int", "\\(have) of \\(needed) present",
    "%1$lld of %2$lld present", "%1$lld iš %2$lld yra")
plain("neededOne", "Needed ×1", "Reikia ×1")
fmt("pctAllParts", "_ pct: Int", "\\(pct)% — all parts", "%lld%% — all parts", "%lld%% — visos dalys")
fmt("pctOfParts", "_ pct: Int", "\\(pct)% of parts", "%lld%% of parts", "%lld%% dalių")
plain("noMinifigures", "No minifigures", "Nėra minifigūrėlių")
plain("minifiguresIncluded", "Minifigures included", "Minifigūrėlės įtrauktos")
plain("minifiguresIncomplete", "Minifigures incomplete", "Trūksta minifigūrėlių")
plain("whatElseInBox", "What else is in the box?", "Kas dar yra dėžutėje?")
plain("boxIncluded", "Box included", "Dėžutė įtraukta")
plain("instructionsIncluded", "Instructions included", "Instrukcijos įtrauktos")
plain("stickersApplied", "Stickers applied", "Lipdukai užklijuoti")
plain("notesOptional", "Notes (optional)", "Pastabos (nebūtina)")
plain("notesHint", "e.g. one tyre scuffed, otherwise mint",
      "pvz., viena padanga subraižyta, kitaip nepriekaištinga")
plain("saveVerification", "Save verification", "Išsaugoti patvirtinimą")

# ─────────────────────────── REPORT ───────────────────────────
plain("notVerifiedYet", "Not verified yet", "Dar nepatvirtinta")
plain("notVerifiedMessage", "Finish a review and mark it verified to get a report.",
      "Užbaikite peržiūrą ir pažymėkite kaip patvirtintą, kad gautumėte ataskaitą.")
plain("shareImage", "Share image", "Bendrinti paveikslėlį")
plain("sharePdf", "Share PDF", "Bendrinti PDF")
fmt("reportPctComplete", "_ pct: Int", "\\(pct)% COMPLETE", "%lld%% COMPLETE", "%lld%% UŽBAIGTA")
fmt("reportPctPartsMissing", "pct: Int, count: Int", "\\(pct)% · \\(count) parts missing",
    "%1$lld%% · %2$lld parts missing", "%1$lld%% · trūksta %2$lld dalių")
plain("noneInSet", "None in set", "Rinkinyje nėra")
plain("inventoryVerification", "INVENTORY VERIFICATION", "INVENTORIAUS PATVIRTINIMAS")
plain("reportPartsFound", "Parts found", "Rasta dalių")
plain("allPartsPresent", "All parts present", "Visos dalys yra")
fmt("verifiedDate", "_ date: String", "Verified \\(date)", "Verified %@", "Patvirtinta %@")
plain("verifiedWithBrickback", "Verified with BrickBack", "Patvirtinta su BrickBack")

# ─────────────────────────── PARTY ───────────────────────────
plain("couldntLoadParty", "Couldn't load party", "Nepavyko įkelti sesijos")
plain("endThisParty", "End this party?", "Užbaigti šią sesiją?")
plain("endParty", "End party", "Užbaigti sesiją")
plain("endPartyBody", "Members won't be able to add parts anymore.", "Nariai nebegalės pridėti detalių.")
plain("statusEnded", "Ended", "Užbaigta")
plain("statusPaused", "Paused", "Pristabdyta")
fmt("partyCodeCaption", "_ code: String", "Party · code \\(code)", "Party · code %@", "Sesija · kodas %@")
fmt("partyProgress", "have: Int, total: Int", "\\(have) of \\(total) parts",
    "%1$lld of %2$lld parts", "%1$lld iš %2$lld detalių")
plain("addFoundParts", "Add found parts", "Pridėti rastas detales")
plain("activity", "Activity", "Veikla")
plain("noActivity", "No parts added yet.", "Kol kas detalių nepridėta.")
plain("invite", "Invite", "Pakviesti")
plural("memberCount", "_ n: Int", "\\(n) members",
       {"one": "%lld member", "other": "%lld members"},
       {"one": "%lld narys", "few": "%lld nariai", "other": "%lld narių"})
fmt("activityLine", "who: String, what: String", "\\(who) added \\(what)",
    "%1$@ added %2$@", "%1$@ pridėjo %2$@")
plain("roleHost", "Host", "Organizatorius")
plain("roleMember", "Member", "Narys")
plain("someone", "Someone", "Kažkas")
plain("partyJoinSubtitle", "Enter the code the host shared with you.",
      "Įveskite kodą, kurį pasidalino organizatorius.")
plain("partyJoinCta", "Join", "Prisijungti")
plain("partyJoinError", "Couldn't find that party. Check the code.",
      "Tokia sesija nerasta. Patikrinkite kodą.")
fmt("inviteTitle", "_ name: String", "Invite to \\(name)", "Invite to %@", "Pakvieskite į „%@“")
plain("inviteSubtitle", "Scan the code or share the link to join the sort.",
      "Nuskenuokite kodą arba pasidalinkite nuoroda, kad prisijungtų.")
plain("joinCode", "Join code", "Prisijungimo kodas")
plain("shareInvite", "Share invite", "Dalintis kvietimu")
fmt("partyShareText", "code: String, link: String",
    "Join my BrickBack sort party — code \\(code)\\n\\(link)",
    "Join my BrickBack sort party — code %1$@\n%2$@",
    "Prisijunk prie mano BrickBack rūšiavimo sesijos — kodas %1$@\n%2$@")
plain("partyNothingLeftTitle", "Nothing left to find", "Nieko nebeliko ieškoti")
plural("addLabel", "_ n: Int", "Add \\(n) parts",
       {"one": "Add %lld part", "other": "Add %lld parts"},
       {"one": "Pridėti %lld detalę", "few": "Pridėti %lld detales", "other": "Pridėti %lld detalių"})
fmt("partyRemainingLabel", "color: String, count: Int", "\\(color) · \\(count) left",
    "%1$@ · %2$lld left", "%1$@ · liko %2$lld")
fmt("couldntAddParts", "_ error: String", "Couldn't add parts: \\(error)",
    "Couldn't add parts: %@", "Nepavyko pridėti detalių: %@")

# ─────────────────────────── ACCESSIBILITY (VoiceOver) ───────────────────────────
# Spoken labels/values/hints. Composed at the call site from catalog data (part/colour names),
# so these are the connective phrasing only. Counts stay %lld (VoiceOver reads them as numbers).
plain("a11yProgress", "Progress", "Eiga")
plain("a11yStartParty", "Start party", "Pradėti bendrą rūšiavimą")
plain("a11yDetails", "Details", "Detalės")
plain("a11yAdd", "Add", "Pridėti")
plain("a11yPresent", "Present", "Yra")
plain("a11yAbsent", "Absent", "Nėra")
plain("a11yTileAddHint", "Adds one", "Prideda vieną")
plain("a11yOpensBrickLink", "Opens the BrickLink page", "Atidaro „BrickLink“ puslapį")
# Tile label = "<part name>, <colour>"; value = "<have> of <needed>" (+ ", complete").
fmt("a11yNameColor", "name: String, color: String", "\\(name), \\(color)", "%1$@, %2$@", "%1$@, %2$@")
fmt("a11yCount", "have: Int, needed: Int", "\\(have) of \\(needed)",
    "%1$lld of %2$lld", "%1$lld iš %2$lld")
fmt("a11yCountComplete", "have: Int, needed: Int", "\\(have) of \\(needed), complete",
    "%1$lld of %2$lld, complete", "%1$lld iš %2$lld, baigta")

# ═══════════════════════════ EMIT ═══════════════════════════
def unit(v):
    return {"stringUnit": {"state": "translated", "value": v}}

def loc_plural(d):
    return {"variations": {"plural": {cat: unit(v) for cat, v in d.items()}}}

strings = {}
seen = set()
for kind, key, p in entries:
    assert key not in seen, f"duplicate key {key}"
    seen.add(key)
    if kind in ("plain", "fmt"):
        strings[key] = {"localizations": {"en": unit(p["en"]), "lt": unit(p["lt"])}}
    else:  # plural
        strings[key] = {"localizations": {"en": loc_plural(p["en"]), "lt": loc_plural(p["lt"])}}

catalog = {"sourceLanguage": "en", "strings": strings, "version": "1.0"}
os.makedirs(f"{APP}/Resources", exist_ok=True)
with open(f"{APP}/Resources/Localizable.xcstrings", "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")

# ── L.swift ──
lines = [
    "import Foundation",
    "",
    "/// Typed access to every localized UI string (S7 i18n). GENERATED by",
    "/// `apps/ios/scripts/gen_l10n.py` from the compact table — edit the table + regenerate,",
    "/// don't hand-edit. Each accessor resolves against `I18n.bundle`/`I18n.locale`, so the in-app",
    "/// Language override switches strings live (see `LocaleController`). Keys mirror",
    "/// `Localizable.xcstrings`.",
    "enum L {",
    "    private static func s(_ key: String.LocalizationValue) -> String {",
    "        String(localized: key, bundle: I18n.bundle, locale: I18n.locale)",
    "    }",
    "",
]
for kind, key, p in entries:
    if kind == "plain":
        lines.append(f'    static var {key}: String {{ s("{key}") }}')
    elif kind == "fmt":
        lines.append(f'    static func {key}({p["sig"]}) -> String {{')
        lines.append(f'        String(localized: "{key}", defaultValue: "{p["default"]}", bundle: I18n.bundle, locale: I18n.locale)')
        lines.append('    }')
    else:  # plural
        lines.append(f'    static func {key}({p["sig"]}) -> String {{')
        lines.append(f'        String(localized: "{key}", defaultValue: "{p["default"]}", bundle: I18n.bundle, locale: I18n.locale)')
        lines.append('    }')
lines.append("}")
with open(f"{APP}/Localization/L.swift", "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")

print(f"Wrote {len(entries)} keys → Localizable.xcstrings + L.swift")
plurals = sum(1 for k, _, _ in entries if k == "plural")
fmts = sum(1 for k, _, _ in entries if k == "fmt")
print(f"  plain={len(entries)-plurals-fmts} fmt={fmts} plural={plurals}")
