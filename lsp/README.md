To hack on the LSP, you must jump through a few build hoops
(at least until we get some better monorepo make rules):
1. In `lang`, make sure to run `make libA`. This builds the libraries
   (in `libs.arr`) in addition to the compiler itself, and is needed
   by the LSP.
2. Build CPO, following the instructions in the README
   (it should reference `lang` via symlink)
3. Build this server, using `npm run build`
4. Build and launch the VSCode extension for debugging, following the
   instructions in the README
  
To see the server's logged messages, check VSCode's Output tab
(`CTRL`+`SHIFT`+`U`) and select `Pyret Language Server`.
