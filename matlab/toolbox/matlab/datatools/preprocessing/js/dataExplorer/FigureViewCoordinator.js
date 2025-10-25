/*
    Copyright 2020-2023 The MathWorks, Inc.
*/

define('preprocessing/dataExplorer/FigureViewCoordinator', [
    'preprocessing/dataExplorer/FigureFactory',
    'preprocessing/dataExplorer/FigureInterface'
], function (FigureFactory, FigureInterface) {
    'use strict';

    class FigureViewCoordinator {
        constructor () {
            this._divFigure = null;
            this._interfaceHandler = new FigureInterface();
            this._figureFactory = new FigureFactory();
        }

        _printError (error) {
            console.log(error);
        }

        getFigureParentNode () {
            return this._divFigure
                ? this._divFigure.domNode.parentNode
                : null;
        }

        removeDivFigureFromDOM () {
            this._divFigure.domNode.remove();
        }

        createFigureView (parentNode, figInfo, postFigureCreationFn) {
            try {
                this._interfaceHandler.initialWidth = parentNode.offsetWidth;
                this._interfaceHandler.initialHeight = parentNode.offsetHeight;
                this._interfaceHandler.figureCreatedCallbackFn = postFigureCreationFn;

                const factory = this._figureFactory.getFactory();
                const divFigureProperties = {
                    state: figInfo,
                    handler: this._interfaceHandler,
                    div: parentNode
                };

                this._divFigure = factory.createWidget(divFigureProperties);
                // TODO: Remove the line of code below and the associated server-side
                // code/messages involved.
                //
                // This was originally meant to aid in destroying the DivFigure;
                // now that this process is automatically taken care of elsewhere
                // (i.e., the DivFigure automatically gets removed from the DOM & is
                // destroyed by the removal), this is redundant.
                this._divFigure.domNode.classList.add(figInfo.Uuid);

                this._divFigure.startup();
            } catch (e) {
                this._printError(e);
            }
        }

        handleResize () {
            // g3037526: Resize the div figure before updating the server with the
            // updated width and height. This is according to the Div Figure User Guide.
            //
            // This fixes the legends not being toggle-able after the Div Figure gets resized.
            const parentNode = this.getFigureParentNode();
            if (parentNode == null) return;

            const width = parentNode.getBoundingClientRect().width;
            const height = parentNode.getBoundingClientRect().height;
            this._divFigure.resize({ l: 0, t: 0, w: width, h: height });

            this._interfaceHandler.handleSizeChanged(width, height);
        }

        destroy () {
            this._divFigure?.remove();
            if (this._interfaceHandler) delete this._interfaceHandler;
            this._interfaceHandler = null;
        }
    }

    return FigureViewCoordinator;
});
