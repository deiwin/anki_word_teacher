# Anki Word Teacher #

This program will help you keep track of all the words you encounter throughout your day that
you don't know or understand completely, but would like to.

## How it works ##

At the moment it has 2 sources for words: Kindle highlights and Evernote notes. If you start the
software new words will be polled and then Wordnik is used to find definitions, synonyms and
common use-cases for those words. After that the words and definitions can be exported in a format
that can be used to impot this data to Anki. Anki handles all the rest.


## TODO ##

Some of the things that need to be done listed in no particular order.

 - Move all the configurables into a single conf file
 - Instead of the saved_words.yaml file, get the already imported words from Anki
  - Might want to use a separate DB instead
 - Add ignored words
 - Add a way to manually change definitions
 - Remove highlights from kindle if imported (use the newer(other) github repo and improve it)
 - Handle no new words case
 - Write tests (use rspec)
 - Use a Logger for logging instead of a lambda
 - Offer an option to select books for which to download highlights on the MMI
  - Every time a new book is added to Amazon, ask if definitions should be fetched for that book as well
 - __REFACTOR__
