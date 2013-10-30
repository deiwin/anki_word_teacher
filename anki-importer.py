import sys
sys.path.append("/usr/share/anki")
from anki import Collection
from anki.importing import TextImporter

file = u"/home/deiwin/anki-updater/import.csv"

col = Collection("../Anki/User 1/collection.anki2")

# change to the basic note type
m = col.models.byName("Basic")
col.models.setCurrent(m)
# set 'Import' as the target deck
m['did'] = col.decks.id("Reading")
col.models.save(m)

col.decks.get([m['did']]).newFact()

#ti = TextImporter(col, file)
#ti.initMapping()
#ti.run()

print col.db.all("SELECT * FROM cards")

note = col.newNote()
#note.setTagsFromStr(tags)
card = note.cards[0]


print card

card.save()
note.save()
col.save()
