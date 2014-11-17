## wad file to do

1. not a wad
2. short header (only IWAD)
3. only number of lumps
4. good header lenght but bogus data (e.g 0 lumps, 0 offset)
5. correct header but short lump directory
6. test that from the start of directory (see header) to EOF there is a multiple of 16 bytes

in directory:

7. offset falls into usable area of file (end of header -> start of lump dir)
8. lump with wrong size: foreach lump check that size is < available space and then
   decrease available space of size of lump
9. name must have at least one ASCII char != 0
10. chars must be ASCII
11. check that the lumps at end of chapter 3 and in 4.1 have 0 lenght

specific

PLAYPAL: There are 14 palettes here, each is 768 bytes = 256 rgb triples.
         interesting is the first (0)
