/** Copyright 2017 The MathWorks, Inc. */

define([
    'dojo/_base/declare',
    './MapItem'
], function (declare, MapItem) {
    var map = {};
    var PUT_WRITE_TYPES = { // Key and value must match for logic to work
        overwrite: 'overwrite',
        append: 'append',
        drop: 'drop'
    };
    var appendCnt = {};
    var appendMap = {};

    return declare([], {
        _defaultKey: 'New Item',
        _itemType: MapItem,

        constructor: function (options) {
            //            this.parent = options.popupId;
        },

        add: function (key, value /* ? */) {
            if (value === undefined) {
                value = null;
            }

            // TODO: May want to change the wrtieType to append
            this.put(key, value, PUT_WRITE_TYPES.overwrite);
        },

        createAndAdd: function (item) {
            var itemType = new this._itemType(item);
            this.add(itemType.id, itemType);
        },

        remove: function (key) {
            if (this.contains(key)) {
                if (appendMap.hasOwnProperty(key)) {
                    appendCnt[key] = appendCnt[appendMap[key]] - 1;
                }

                delete this._getMap()[key];
                return true;
            }
            return false;
        },

        contains: function (key) {
            return this._getMap().hasOwnProperty(key);
        },

        get: function (key) {
            if (this.contains(key)) {
                return this._getMap()[key];
            }
            return null;
        },

        put: function (key, value, writeType) {
            if ((key === undefined)) {
                throw new Error('The input value for "key" was not defined.');
            } else if ((typeof key !== 'string')) {
                throw new Error('The input value for "key" must be of type "string".');
            }

            if ((value === undefined)) {
                throw new Error('The input value for "value" was not defined.');
            } else if (!(this._isValidValue(value))) {
                throw new Error('The input value for "value" is not valid.');
            }

            if (writeType === undefined) {
                writeType = PUT_WRITE_TYPES.overwrite;
            } else if (!PUT_WRITE_TYPES.hasOwnProperty(writeType)) {
                throw new Error('The input value for "writeType" must be one of ' +
                                '[ "overwrite" | "append" | "drop" ].');
            }

            if ((PUT_WRITE_TYPES[writeType] === PUT_WRITE_TYPES.drop) && this.contains(key)) {
                return null;
            } else if ((PUT_WRITE_TYPES[writeType] ===
                PUT_WRITE_TYPES.append) && this.contains(key)) {
                key = this._getUniqueKey(key);
            }

            // PUT Logic
            this._getMap()[key] = value;
            return key;
        },

        size: function () {
            return this.keys().length;
        },

        keys: function () {
            return Object.keys(this._getMap());
        },

        // TODO: Update logic to account for already serialized unique keys
        _getUniqueKey: function (key) {
            if (key !== undefined) {
                if (this.contains(key)) {
                    var cnt, newKey;

                    if (appendCnt.hasOwnProperty(key)) {
                        cnt = appendCnt[key] + 1;
                    } else {
                        cnt = 1;
                    }

                    appendCnt[key] = cnt;
                    newKey = key + cnt;
                    appendMap[newKey] = key;
                    key = newKey;
                }
            } else {
                key = this._getUniqueKey(this._defaultKey);
            }

            return key;
        },

        _getMap: function () {
            return map;
        },

        // Can be overridden in order to handle specific types
        _isValidValue: function (value) {
            return value instanceof this._itemType;
        }
    });
});
