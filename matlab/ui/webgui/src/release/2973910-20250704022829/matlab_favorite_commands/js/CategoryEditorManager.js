/* Copyright 2017 The MathWorks, Inc. */

/**
 * The Category Editor Manager is responsible for ...
 */

define([
    'dojo/_base/declare',
    'dojo/_base/lang',
    './CategoryEditorModule'
], function (declare, lang, CategoryEditorModule) {
    return declare(null, {

        _dialog: null,

        constructor: function (args) {
            this.categoryActionsModule = args.categoryActionsModule;
            this.uiBuilder = args.uiBuilder;
        },

        open: function (args) {
            if (args) {
                args.isEditing = true;
            } else {
                args = {};
                args.isEditing = false;
            }

            args.categoryActionsModule = this.categoryActionsModule;
            args.uiBuilder = args.uiBuilder || this.uiBuilder;

            this._dialog = new CategoryEditorModule(args);
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
