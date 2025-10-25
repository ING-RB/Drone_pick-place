/*
    Copyright 2020-2023 The MathWorks, Inc.
*/

define('preprocessing/dataExplorer/FigureInterface', [
    'gbtcomponents/controller/interface/DivFigureToAppLayerInterface'
], function (DivFigureToAppLayerInterface) {
    'use strict';

    class FigureInterface extends DivFigureToAppLayerInterface {
        constructor () {
            super();
            this.initialWidth = null;
            this.initialHeight = null;
            this.figureCreatedCallbackFn = null;
        }

        /*
         * Although these functions do nothing special, removing them will result in errors.
         * These were directly copied from: matlab/test/data/gbt/divfiguredemo/standalone/dfSimpleDemo.js
         */

        // Set the specified property to the value specified by the server.
        // @param {property} - name of property
        // @param {value} - new property value
        handleFigurePropertyChange (property, value) {
            switch (property) {
                case 'Position':
                    this._setPositionFromServer(value);
                    break;
                case 'Resize':
                    this._setResizeFromServer(value);
                    break;
                case 'Title':
                    this._setTitleFromServer(value);
                    break;
                case 'IconView':
                    this._setIconViewFromServer(value);
                    break;
                case 'Visible':
                    this._setVisibleFromServer(value);
                    break;
                case 'WindowState':
                    this._setWindowStateFromServer(value);
                    break;
                case 'WindowStyle':
                    this._setWindowStyleFromServer(value);
                    break;
                case 'DockControls':
                    this._setDockControlsFromServer(value);
                    break;
                default:
                    throw new Error('Server attempt to set value of unsupported property: ' + property);
            }
        }

        // Set Figure Position.
        // @param {newPosition} 4-element array containing new Position
        _setPositionFromServer (newPosition) {
            // not yet supported
            // Important note: For DivFigure users that are changing their custom domNode's/div's
            // dimensions in which they have placed their DivFigure, the resize() method should be called
            // on the DivFigure after resizing the parent domNode/div to appropriately trigger resizing. This
            // should be followed by updating the server with the true rendered dimensions of the DivFigure
            // by using the appropriate API.
        }

        // Set Figure Resize value using the UIContainer resizable API
        // @param {newResize} new boolean Resize value
        _setResizeFromServer (newResize) { }

        // Set Figure Title.
        // @param {newTitle} new Title string
        _setTitleFromServer (newTitle) { }

        // Set Figure IconView.
        // @param {newIcon} new IconView
        _setIconViewFromServer (newIcon) { }

        // Set Figure Visible.
        // @param {newVisible} new boolean Visible value
        _setVisibleFromServer (newVisible) { }

        // Set Figure WindowState.
        // @param {newWindowState} new WindowState: "fullscren", "maximized", "minimized", or "normal"
        _setWindowStateFromServer (newWindowState) { }

        // Set Figure WindowStyle.
        // @param {newWindowStyle} new WindowStyle: "docked", "modal", or "normal"
        _setWindowStyleFromServer (newWindowStyle) { }

        // Set Figure DockControls state.
        // @param {newDockControls} new boolean DockControls state
        _setDockControlsFromServer (newDockControls) { }

        // ----- handleFigureEvent() et al

        // Handle events coming from the server.
        // @param {type} - event type
        // @param {data} - optional data associated with the event
        handleFigureEvent (type, data) {
            // After the figure is created, if a callback function is defined, call it.
            // This is used to resize the figure as soon as it can be resized.
            if (type === 'figureControllerViewCreated') this.figureCreatedCallbackFn?.();
        }

        handleSizeChanged (newWidth, newHeight) {
            const newSize = [0, 0, newWidth, newHeight];
            this._msgFromAppLayerHandler.setFigureProperty('Position', newSize);
        }

        getDocumentProperties () {
            return {
                isDocked: true,
                isDocking: false,
                isUndocking: false
            };
        }

        getDocumentGroupProperties () {
            return {
                isDocked: true,
                isDocking: false,
                isUndocking: false
            };
        }

        registerDivFigureMsgHandler (msgFromAppLayerHandler) {
            // save the msgFromAppLayerHandler for use in _setPosition
            this._msgFromAppLayerHandler = msgFromAppLayerHandler;
        }
    }

    return FigureInterface;
});
