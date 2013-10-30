# import the main window object (mw) from ankiqt
from aqt import mw
# import all of the Qt GUI library
from aqt.qt import *
from anki.importing import TextImporter

def importCsv():
  file = u"/home/deiwin/anki-updater/import.csv"
  # change to the basic note type
  m = mw.col.models.byName("Basic")
  mw.col.models.setCurrent(m)
  # set 'Reading' as the target deck
  m['did'] = mw.col.decks.id("Reading")
  mw.col.models.save(m)
  # import into the collection
  ti = TextImporter(mw.col, file)
  ti.initMapping()
  ti.run()
  
  mw.reset()

# create a new menu item, "test"
action = QAction("Import csv", mw)
# set it to call testFunction when it's clicked
mw.connect(action, SIGNAL("triggered()"), importCsv)
# and add it to the tools menu
mw.form.menuTools.addAction(action)
