/** Copyright 2018 The MathWorks, Inc. */

define([
    'dojo/_base/declare',
    './MapItem'
], function (declare, MapItem) {
    return declare([MapItem], {
        constructor: function (args) {
            this._categoryObject = args.categoryObject;
        },

        getCategoryObject: function () {
            return this._categoryObject;
        },

        setCategoryObject: function (widget) {
            this._categoryObject = widget;
        }
    });
});
