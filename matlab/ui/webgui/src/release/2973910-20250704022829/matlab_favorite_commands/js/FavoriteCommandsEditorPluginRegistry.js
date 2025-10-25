/* Copyright 2019 The MathWorks, Inc. */

define([
    'matlab_favorite_commands/js/FavoriteCommandsEditorPlugins/FEContextMenuModelProvider'
], function () {
    return {
        plugins: [
            {
                id: 'fe.contextmenu.model',
                path: 'matlab_favorite_commands/js/FavoriteCommandsEditorPlugins/FEContextMenuModelProvider'
            }
        ]
    };
});
