// Copyright 2019 The MathWorks, Inc.

define([
    'dojo/_base/declare',
    'rtc/abstract/AbstractPlugin'
], function (declare, AbstractPlugin) {
    return declare(AbstractPlugin, {
        _COPY_PASTE_GROUP: 'copyPaste',

        constructor: function (baseContextMenuModel) {
            this._baseContextMenuModel = baseContextMenuModel;
            this._updateContextMenu();
        },

        _updateContextMenu: function () {
            this._baseContextMenuModel.hideGroup(this._COPY_PASTE_GROUP);
        }
    });
});
