The spirit of the classes in this folder is to let artists not only create the graphics for your games, but enable them to define the collision shapes and physics properties at the same time.

For now the only loader class is qb2FlashLoader, which takes assets produced in Flash CSx, and parses them both graphically and physics-wise for use in your game.  But I can easily envision other classes like qb2XmlLoader, where you use some 3rd party program to define physics shapes, export as XML, then read into QuickB2.

The loaders.proxies folder contains a bunch of classes that you use to define physics objects graphically in Flash CSx.  They all extend from MovieClip, and all use the component framework to define properties.