/* Copyright 2017 The MathWorks, Inc. */

/**
 * The Favorite Commands Editor Manager is responsible for ...
 */

define([
    'dojo/_base/declare',
    'dojo/_base/lang',
    './FavoriteCommandsEditorModule'
], function (declare, lang, FavoriteCommandsEditorModule) {
    return declare(null, {

        _dialog: null,

        constructor: function (args) {
            this.favoriteActionsModule = args.favoriteActionsModule;
            this.categoryActionsModule = args.categoryActionsModule;
            this.uiBuilder = args.uiBuilder;
        },

        open: function (favoriteAction) {
            if (!favoriteAction) {
                favoriteAction = {};
            }

            if (favoriteAction.favoriteId) {
                favoriteAction.isEditing = true;
            } else {
                favoriteAction.isEditing = false;
            }

            favoriteAction.favoriteActionsModule = this.favoriteActionsModule;
            favoriteAction.categoryActionsModule = this.categoryActionsModule;

            this._dialog = new FavoriteCommandsEditorModule({
                favoriteAction: favoriteAction || {},
                uiBuilder: this.uiBuilder });
        },

        close: function () {
            if (this._dialog) {
                this._dialog.close();
                this._dialog.destroy();
                delete this._dialog;
            }
        }
    });
});
