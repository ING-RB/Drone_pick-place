/** Copyright 2018 The MathWorks, Inc. */

define([
    'dojo/_base/declare'
], function (declare) {
    // TODO: See if this can be overridden in sub-classes
    var ATTRIBUTES = { id: 'id', value: 'value' };

    return declare([], {
        id: null,
        value: null,

        get: function (attr) {
            this._validateAttr(attr);
            return this[attr];
        },

        set: function (attr, value) {
            this._validateAttr(attr);
            if (!this._isValidValue(value)) {
                throw new Error("The value of the 'value' attribute is not valid;");
            }
            this[attr] = value;
        },

        // Can be overridden in order to handle specific types
        _isValidValue: function (value) {
            return true;
        },

        _validateAttr: function (attr) {
            if (!ATTRIBUTES.hasOwnProperty(attr)) {
                throw new Error("The input attribute '" + attr.toString() + "' is not valid;");
            }
        }
    });
});
