This folder contains both pre-compiled .swc's and the source code of a few open-source libraries on which QuickB2 depends.  The source code is pulled automatically using svn:externals, while the .swc's are built manually

As3Math is required and provides some geometry classes and math utilities that didn't make sense to rewrite for exclusive QuickB2 use.

Box2D is also required.  If you plan on using the source of Box2D, you'll also have to bring a pre-compiled .swc into your project (src/Box2DAS/Box2D.swc).  This .swc handles all the Adobe Alchemy C++ voodoo that the ActionScript 3.0 port requires.

MinimalComps is only required if you plan on using qb2DebugPanel.  It's a gui/component library, used because again I didn't want to waste time writing all that stuff myself.