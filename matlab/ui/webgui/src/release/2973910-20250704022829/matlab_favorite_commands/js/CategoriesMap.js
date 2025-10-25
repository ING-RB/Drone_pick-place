/** Copyright 2018 The MathWorks, Inc. */

define([
    'dojo/_base/declare',
    './MapBase',
    './CategoryItem',
    'dojo/i18n!../l10n/nls/favcommands'
], function (declare, MapBase, CategoryItem, favcommandsL10n) {
    return declare([MapBase], {
        _defaultKey: favcommandsL10n.newCategoryLabel, // "New Category"
        _itemType: CategoryItem
    });
});
