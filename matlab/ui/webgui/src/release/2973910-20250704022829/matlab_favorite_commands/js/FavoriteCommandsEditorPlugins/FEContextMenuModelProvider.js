// Copyright 2019 The MathWorks, Inc.

define([
    'dojo/_base/declare',
    'rtc/core/provider/PluginProvider',
    './FEContextMenuModel'
], function (declare, PluginProvider, FEContextMenuModel) {
    return declare(PluginProvider, {

        isApplicable: function () {
            return true;
        },

        requires: function () {
            return {
                createInstance: [
                    'rtc.contextmenu.model'
                ]
            };
        },

        createInstance: function (contextMenuModel) {
            return new FEContextMenuModel(contextMenuModel);
        }
    });
});
