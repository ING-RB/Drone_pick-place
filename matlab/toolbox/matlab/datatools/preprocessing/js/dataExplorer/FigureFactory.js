/*
    Copyright 2023 The MathWorks, Inc.
*/

define('preprocessing/dataExplorer/FigureFactory', [
    'gbtdivfigure/DivFigureFactory',
    'MW/uiframework/CssLoader'
], function (DivFigureFactory, CssLoader) {
    'use strict';

    let factoryWithCSS = null;

    // This is a singleton. If we have previously created an instance, return it.
    class FigureFactory {
        async createFactory () {
            factoryWithCSS = new DivFigureFactory();
            // g3156065: Await for css file loading completion before returning the
            // factory instance for use.
            // This is to avoid rendering the widget before the required CSS styling
            // is ready and end up with wrong styling, e.g., rendering container node
            // with 0 height.
            await CssLoader.loadFiles(factoryWithCSS.getCssFiles());
        }

        getFactory () {
            if (factoryWithCSS == null) {
                throw new Error('Cannot get DivFigure factory; create it first by calling "createFactory()"');
            }

            return factoryWithCSS;
        }

        destroy () {
            factoryWithCSS?.destroy();
        }
    }

    return FigureFactory;
});
