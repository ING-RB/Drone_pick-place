'use strict';
/* eslint-disable no-prototype-builtins */
/* Copyright 2018-2024 The MathWorks, Inc. */

define([
    'mw-remote/Remote',
    'MW/uiframework/PreferenceDirectoryService',
    'dojo/i18n!../l10n/nls/favcommands',
    'mw-messageservice/MessageService'
], function (Remote, PreferenceDirectoryService, favcommandsL10n, MessageService) {
    const OUT_CHANNEL = '/desktop/datamigrator/toProvider';
    const IN_CHANNEL = '/desktop/datamigrator/toConsumer';
    let model;
    let _testMode = false;
    const artifactName = 'favorite_commands.json';
    let modelLoading = false;
    let modelLoaded = false;
    let modelDirty = false;
    let modelUpdateBacklog = [];
    const validateId = function (id, type) {
        if (!model.data[type].hasOwnProperty(id)) {
            throw new Error("Invalid 'id'.  Does not exist in " + type + '.');
        }
    };
    const validateData = function (data, type) {
        // If any of the input fields match the supported fields, then we can work with it
        if (!Object.keys(data).some(function (key) {
            return (supportedFields[type].indexOf(key) > -1);
        })) {
            throw new Error("Invalid 'data'.  Does not match format for " + type + '.');
        }
    };
    const serializeModel = function (factoryReset) {
        if (_testMode) {
            modelDirty = false;
            return;
        }
        if (!factoryReset && !isModelCustomized()) {
            // If the user modified the model, and the state has not already been updated, then do so.
            model.state = '1';
        }
        PreferenceDirectoryService.writeFileToPreferenceDirectory(artifactName, JSON.stringify(model)).then(function (value) {
            // value = "File Created"; // This always seems to be the case
            modelDirty = false;
        }, function (err) {
            throw err;
        });
    };
    const getModel = function () {
        if (modelLoaded) {
            return copyObj(model);
        } else {
            return null;
        }
    };
    const loadFactoryModel = function () {
        model = JSON.parse(factoryDataset);
        modelLoaded = true;

        if (modelUpdateBacklog.length > 0) {
            updateModel(); // process backlog before serializing
        } else {
            serializeModel(true);
        }
    };

    const isModelCustomized = function () {
        return (model.hasOwnProperty('state') && model.state !== '0'); // model.state === "0" means factory default
    };
    const parseSerializedData = function (serializedData, factoryData = factoryDataset) {
        // Fallback to the factory dataset if we fail to parse the serialized data
        let parsedModel = JSON.parse(factoryData);

        try {
            parsedModel = JSON.parse(serializedData);
        } catch (error) {
            // g3221772, g3485390: For some reason the serialized data can end up with extra duplicate characters at the end of the file.
            // We can eliminate these extra characters to recover the underlying data and continue loading Favorites unimpeded.
            // TODO: Figure out what adds these extra characters and get rid of the workaround.

            const maxIter = 10; // Arbitrary maximum number of characters to attempt to remove from corrupted data
            const iterCnt = Math.min(serializedData.length, maxIter); // Math.min in the unlikely case serializedData is shorter than maxIter number of characters
            const iterationArray = [...Array(iterCnt)]; // Somewhat cryptic means of creating an array of length 'iterCnt' for us to loop over with Array.prototype.some

            // Iteratively remove the last character from the value and try parsing again
            const recoverySucceded = iterationArray.some(() => { // We use Array.prototype.some for short circuit loop termination and boolean output
                try {
                    serializedData = serializedData.slice(0, -1);
                    parsedModel = JSON.parse(serializedData);
                    return true;
                } catch (_) {
                    return false;
                }
            });

            if (recoverySucceded) {
                model = parsedModel;
                serializeModel();
            }
        }

        return parsedModel;
    };
    const updateFactoryExamples = function () {
        if (model.version !== getFactoryVersion()) {
            if (isModelCustomized()) {
                // We need to be careful about what to replace, if anything
                modelLoaded = true;

                const factoryModel = JSON.parse(factoryDataset);

                Object.keys(model.data.categories).forEach((catId) => {
                    const cat = model.data.categories[catId];
                    const fCat = factoryModel.data.categories[catId];

                    if (!fCat) {
                        // Remove fields from category
                        Object.keys(cat).forEach((key) => {
                            // Field removed from model
                            if (supportedFields.categories.indexOf(key) < 0) {
                                delete model.data.categories[catId][key];
                            }
                        });

                        // Add new fields to category
                        supportedFields.categories.forEach((key) => {
                            // New field added to model
                            if (!cat.hasOwnProperty(key)) {
                                cat[key] = supportedFieldDefaultValues.categories[key];
                            }
                        });
                    } else if (!cat.hasOwnProperty('state') || cat.state === '0') {
                        model.data.categories[catId] = fCat;
                    } else {
                        // Compare actual data
                        supportedFields.categories.forEach((key) => {
                            // New field added to model
                            if (!cat.hasOwnProperty(key) && fCat.hasOwnProperty(key)) {
                                cat[key] = fCat[key];
                                return;
                            }

                            // Field removed from model
                            if (cat.hasOwnProperty(key) && !fCat.hasOwnProperty(key)) {
                                delete model.data.categories[catId][key];
                                return;
                            }

                            // Field changed in model
                            if (fCat[key] !== cat[key]) {
                                if (supportedFields.exposed.categories.indexOf(key) > -1) {
                                    // User modified an exposed field, we want to preserve their changes
                                    // TODO: If we are changing the value of an exposed field, we will need a mechanism here to check if user field matches old factory value
                                } else {
                                    // Safe to update
                                    model.data.categories[catId][key] = fCat[key];
                                }
                            }
                        });
                    }
                });

                Object.keys(model.data.favorites).forEach((favId) => {
                    const fav = model.data.favorites[favId];
                    const fFav = factoryModel.data.favorites[favId];

                    if (!fFav) {
                        // Remove fields from favorite
                        Object.keys(fav).forEach((key) => {
                            // Field removed from model
                            if (supportedFields.favorites.indexOf(key) < 0) {
                                delete model.data.favorites[favId][key];
                            }
                        });

                        // Add new fields to favorite
                        supportedFields.favorites.forEach((key) => {
                            // New field added to model
                            if (!fav.hasOwnProperty(key)) {
                                fav[key] = supportedFieldDefaultValues.favorites[key];
                            }
                        });
                    } else if (!fav.hasOwnProperty('state') || fav.state === '0') {
                        model.data.favorites[favId] = fFav;
                    } else {
                        // Compare actual data
                        supportedFields.favorites.forEach(function (key) {
                            // New field added to model
                            if (!fav.hasOwnProperty(key) && fFav.hasOwnProperty(key)) {
                                fav[key] = fFav[key];
                                return;
                            }

                            // Field removed from model
                            if (fav.hasOwnProperty(key) && !fFav.hasOwnProperty(key)) {
                                delete model.data.favorites[favId][key];
                                return;
                            }

                            // Field changed in model
                            if (fFav[key] !== fav[key]) {
                                if (supportedFields.exposed.favorites.indexOf(key) > -1) {
                                    // User modified an exposed field, we want to preserve their changes
                                    // TODO: If we are changing the value of an exposed field, we will need a mechanism here to check if user field matches old factory value
                                } else {
                                    // Safe to update
                                    model.data.favorites[favId][key] = fFav[key];
                                }
                            }
                        });
                    }
                });

                model.version = getFactoryVersion();

                serializeModel();
            } else {
                // We can replace the whole file
                loadFactoryModel();
            }
        } else {
            modelLoaded = true;
        }
    };
    const loadModel = function (successCallback, failureCallback) {
        if (_testMode) {
            model = JSON.parse(factoryDataset);
            modelLoading = false;
            modelLoaded = true;
            if (successCallback && (typeof successCallback === 'function')) {
                successCallback(getModel());
            }
            return;
        }
        modelLoading = true;
        PreferenceDirectoryService.readFileFromPreferenceDirectory(artifactName).then(function (serializedData) {
            modelLoading = false;

            model = parseSerializedData(serializedData);
            updateFactoryExamples();

            if (successCallback && (typeof successCallback === 'function')) {
                successCallback(getModel());
            }
        }, function (err) {
            modelLoading = false;

            // If the file does not exist, we will create it, and not consider it an error
            if (err && (err.length > 0) && err.some(function (errItem) {
                return (errItem.faultConditions && (errItem.faultConditions.length > 0))
                    ? errItem.faultConditions.some(function (condition) {
                        return (condition.faultId === 'FileNotFound');
                    })
                    : false;
            })) {
                if (!MessageService.isRunning()) {
                    MessageService.start();
                }
                const _handleReceivedMessage = (message) => {
                    if (message.data.service === 'favoritecommands_datamigrator') {
                        if (message.data.status === '0') {
                            // Successful Migration
                            loadModel(successCallback);
                        } else {
                            // Migration failed or clean installation
                            loadFactoryModel();
                        }
                        if (model && successCallback && (typeof successCallback === 'function')) {
                            successCallback(getModel());
                        }
                    }
                };
                MessageService.subscribe(IN_CHANNEL, _handleReceivedMessage);
                MessageService.publish(OUT_CHANNEL, { service: 'favoritecommands_datamigrator', action: 'migrate' });
                return;
            }

            if (failureCallback && (typeof failureCallback === 'function')) {
                failureCallback(err);
            }
        });
    };
    const updateModel = function (options, recursive) {
        // ===== Load model if it is unloaded =====
        if (!modelLoaded) { // TODO: batch jobs so we are not overwhelming the server with requests
            modelUpdateBacklog.push(options);

            if (!modelLoaded && !modelLoading) { // Extra "modelLoaded" check is for future batching support
                loadModel(updateModel, function (err) {
                    throw new Error(err);
                });
            }

            return;
        }

        // ===== Process update backlog if one was generated during load =====
        if (!recursive) {
            while (modelUpdateBacklog.length > 0) {
                // FIFO processing
                updateModel(modelUpdateBacklog.shift(), true);
            }
        }

        // ===== Parse options =====
        if (!options) {
            return;
        }
        //   1. get "action"
        const validActions = ['create', 'delete', 'update', 'move'];
        if (!options.action || (typeof options.action !== 'string') || (validActions.indexOf(options.action) < 0)) {
            throw new Error('Input object must contain "action" attribute set to one of: ' +
                    JSON.stringify(validActions));
        }

        //   2. get "type"
        const validTypes = ['categories', 'favorites'];
        if (!options.type || (typeof options.type !== 'string') || (validTypes.indexOf(options.type) < 0)) {
            throw new Error('Input object must contain "type" attribute set to one of: ' +
                    JSON.stringify(validActions));
        }

        // ===== Create a tempModel to modify =====
        let idx; const tempModel = getModel();

        // ===== Modify the temporary model =====
        switch (options.action) {
            case validActions[0]: // "create"
                // Modify data
                tempModel.data[options.type][options.data.tag] = {
                    label: options.data.label || options.data.title || '',
                    icon: options.data.icon || '',
                    code: options.data.code, // undefined for category
                    isInQAB: options.data.isInQAB || false,
                    showText: options.data.showText || false,
                    editable: options.data.editable || true,
                    state: '1'
                };

                // Modify layout
                if (options.type === validTypes[0]) { // "categories"
                    tempModel.layout.categories.push(options.data.tag);
                    tempModel.layout.favorites[options.data.tag] = [];
                } else { // "favorites"
                    tempModel.layout.favorites[options.data.parentTag].push(options.data.tag);
                }
                break;
            case validActions[1]: // "delete"
                if (tempModel.data[options.type].hasOwnProperty(options.id) && (tempModel.data[options.type][options.id].editable === true)) {
                    // Modify data
                    delete tempModel.data[options.type][options.id];

                    // Modify layout
                    if (options.type === validTypes[0]) { // "categories"
                        idx = tempModel.layout.categories.indexOf(options.id);
                        tempModel.layout.categories.splice(idx, (idx > -1) ? 1 : 0);

                        tempModel.layout.favorites[options.id].forEach(function (favId) {
                            delete tempModel.data.favorites[favId];
                        });

                        delete tempModel.layout.favorites[options.id];
                    } else { // "favorites"
                        tempModel.layout.categories.some(function (categoryId) {
                            idx = tempModel.layout.favorites[categoryId].indexOf(options.id);
                            tempModel.layout.favorites[categoryId].splice(idx, (idx > -1) ? 1 : 0);
                            return (idx > -1);
                        });
                    }
                }
                break;
            case validActions[2]: // "update"
                if (tempModel.data[options.type].hasOwnProperty(options.id) && (tempModel.data[options.type][options.id].editable === true)) {
                    // Modify data
                    let label = options.data.label;
                    let code = options.data.code;
                    let isInQAB = options.data.isInQAB;
                    let showText = options.data.showText;
                    let editable = options.data.editable;

                    if (label === undefined) {
                        label = tempModel.data[options.type][options.id].label;
                    }

                    if (code === undefined) {
                        code = tempModel.data[options.type][options.id].code;
                    }

                    if (isInQAB === undefined) {
                        isInQAB = tempModel.data[options.type][options.id].isInQAB;
                    }

                    if (showText === undefined) {
                        showText = tempModel.data[options.type][options.id].showText;
                    }

                    if (editable === undefined) {
                        editable = tempModel.data[options.type][options.id].editable;
                    }

                    tempModel.data[options.type][options.id] = {
                        label,
                        icon: options.data.icon || tempModel.data[options.type][options.id].icon, // can't be falsy, so this logic works
                        code, // undefined for category
                        isInQAB,
                        showText,
                        editable,
                        state: '1'
                    };
                }

                // Intentional fallthrough
            case validActions[3]: // "move"
                if (tempModel.data[options.type].hasOwnProperty(options.id)) {
                    // Modify layout
                    if (options.type === validTypes[0]) { // "categories"
                        idx = tempModel.layout.categories.indexOf(options.id);

                        // Update the index location
                        if (options.data.hasOwnProperty('index') && (idx !== options.data.index)) {
                            tempModel.layout.categories.splice(options.data.index, 0, tempModel.layout.categories.splice(idx, 1)[0]);
                        }
                    } else { // "favorites"
                        if (options.data.hasOwnProperty('parentTag')) {
                            tempModel.layout.categories.some(function (categoryId) {
                                idx = tempModel.layout.favorites[categoryId].indexOf(options.id);

                                if (idx > -1) {
                                    // Move from old category
                                    if (categoryId !== options.data.parentTag) {
                                        tempModel.layout.favorites[categoryId].splice(idx, (idx > -1) ? 1 : 0);
                                        tempModel.layout.favorites[options.data.parentTag].push(options.id);
                                        idx = tempModel.layout.favorites[options.data.parentTag].indexOf(options.id);
                                    }

                                    // Update the index location
                                    if (options.data.hasOwnProperty('index') && (idx !== options.data.index)) {
                                        tempModel.layout.favorites[options.data.parentTag].splice(options.data.index, 0, tempModel.layout.favorites[options.data.parentTag].splice(idx, 1)[0]);
                                    }
                                }

                                return (idx > -1);
                            });
                        }
                    }
                }
                break;
        }

        // ===== Diff tempModel with model and serialize if changes to the model =====
        if (!recursive && !deepEquals(tempModel, model)) {
            model = tempModel;
            modelDirty = true;
            serializeModel();
        }
    };
    const deepEquals = function (obj1, obj2) { // Not generic enough to be a general utility
        let key; const keyArr = [];

        if (!(obj1 instanceof Object) && !(obj2 instanceof Object)) {
            return (obj1 === obj2);
        }

        if ((obj1 === undefined) || (obj2 === undefined)) {
            return false;
        }

        for (key in obj1) {
            keyArr.push(key);

            if (!deepEquals(obj1[key], obj2[key])) {
                return false;
            }
        }

        for (key in obj2) {
            if (keyArr.indexOf(key) < 0) {
                return false;
            }
        }

        return true;
    };
    const assign = (typeof Object.assign === 'function')
        ? Object.assign
        : function assign (target, varArgs) { // .length of function is 2
        // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/assign
            if (target == null) { // TypeError if undefined or null
                throw new TypeError('Cannot convert undefined or null to object');
            }

            const to = Object(target);

            for (let index = 1; index < arguments.length; index++) {
                const nextSource = arguments[index];

                if (nextSource != null) { // Skip over if undefined or null
                    for (const nextKey in nextSource) {
                    // Avoid bugs when hasOwnProperty is shadowed
                        if (Object.prototype.hasOwnProperty.call(nextSource, nextKey)) {
                            to[nextKey] = nextSource[nextKey];
                        }
                    }
                }
            }
            return to;
        };
    const copyObj = function (obj, method) {
        if (!obj || !(obj instanceof Object)) {
            return null;
        }

        const validMethods = ['spread', 'assign', 'json', 'create'];
        if (!method || (typeof method !== 'string') || (validMethods.indexOf(method) < 0)) {
            method = 'json';
        }

        switch (method) {
            case 'json':
                // Type: Deep
                // Known limitations: Does not work for functions, dates will be stringified and will remain strings, will not work for objects with circular references
                return JSON.parse(JSON.stringify(obj));
            case 'assign':
                // Type: Shallow
                // Known limitations: Shallow, no IE support
                try {
                    return assign({}, obj);
                } catch (err) {
                    return null;
                }
            case 'create':
                // Type: Prototypal inheritance
                // Known limitations: Shallow, Object.keys/hasOwnProperty are wrong
                return Object.create(obj);
                // case "spread":
                //     // Type: Shallow
                //     // Known limitations: Shallow, no IE support
                //     try {
                //         return { ...obj };
                //     } catch (err) {
                //         return null;
                //     }
        }
    };
    /*
     * ===== Factory Semantic Versioning =====
     * The semantic versioning of the Factory Favorite Commands (FFC) is formatted as: X.Y.Z
     *
     * Changing any of the values for X, Y, or Z will cause the model loading logic to attempt to resolve
     * the new changes in the FFCs with the data already serialized on user machines.
     *
     * X: Breaking changes that may require updates to the loading resolution logic itself.
     *    An example would be structural changes to the JSON schema.
     *
     * Y: Feature-level changes that are backwards compatible with regards to the model.
     *    Examples would be the addition of a new property, removal of a deprecated property, or renaming a property.
     *
     * Z: Small changes to the property values only.
     *    An example would be updating the code executed by an FFC when clicked in the UI.
     */
    const factoryX = 1;
    const factoryY = 1;
    const factoryZ = 1;
    const getFactoryVersion = function () {
        return factoryX.toString() + '.' + factoryY.toString() + '.' + factoryZ.toString();
    };
    const supportedFields = {
        categories: ['label', 'icon', 'editable', 'state', 'isInQAB', 'showText', 'index'],
        favorites: ['label', 'icon', 'code', 'editable', 'state', 'isInQAB', 'showText', 'parentId', 'index'],
        exposed: {
            categories: ['label', 'icon', 'isInQAB', 'showText'],
            favorites: ['label', 'icon', 'code', 'isInQAB', 'showText']
        }
    };
    const supportedFieldDefaultValues = {
        categories: {
            label: '',
            icon: 'Favorite Command Icon',
            editable: true,
            state: '1',
            isInQAB: false,
            showText: false
        },
        favorites: {
            label: '',
            icon: 'Favorite Command Icon',
            code: '',
            editable: true,
            state: '1',
            isInQAB: false,
            showText: false
        }
    };
    const factoryDataset =
            '{' +
                '"version":"' + getFactoryVersion() + '",' +
                '"state":"0",' +
                '"data":{' +
                    '"categories":{' +
                        '"CAT_1":{' +
                            '"label":"' + favcommandsL10n.generalCategoryTitle + '",' +
                            '"icon":"Category Icon",' +
                            '"isInQAB":false,' +
                            '"showText":false,' +
                            '"editable":false,' +
                            '"state":"0"' +
                        '},' +
                        '"CAT_2":{' +
                            '"label":"' + favcommandsL10n.examplesCategoryTitle + '",' +
                            '"icon":"Category Icon",' +
                            '"isInQAB":false,' +
                            '"showText":false,' +
                            '"editable":true,' +
                            '"state":"0"' +
                        '}' +
                    '},' +
                    '"favorites":{' +
                        '"FAV_1":{' +
                            '"label":"' + favcommandsL10n.aboutFavoriteCommands + '",' +
                            '"icon":"icon_help_favorite_16",' +
                            '"code":"% ' + favcommandsL10n.aboutFavoriteCommandsComment + '\\nhelpview(\'matlab\', \'matlab_favorites\');",' +
                            '"isInQAB":false,' +
                            '"showText":false,' +
                            '"editable":true,' +
                            '"state":"0"' +
                        '},' +
                        '"FAV_2":{' +
                            '"label":"' + favcommandsL10n.clearVariablesAndCommands + '",' +
                            '"icon":"fav_command_c",' +
                            '"code":"% ' + favcommandsL10n.clearVariablesAndCommandsComment1 + '\\nclear;\\n\\n% ' + favcommandsL10n.clearVariablesAndCommandsComment2 + '\\nclc;",' +
                            '"isInQAB":false,' +
                            '"showText":false,' +
                            '"editable":true,' +
                            '"state":"0"' +
                        '},' +
                        '"FAV_3":{' +
                            '"label":"' + favcommandsL10n.goToUserFolder + '",' +
                            '"icon":"icon_favorite_command_16",' +
                            '"code":"% ' + favcommandsL10n.goToUserFolderComment + '\\ncd(userpath);",' +
                            '"isInQAB":false,' +
                            '"showText":false,' +
                            '"editable":true,' +
                            '"state":"0"' +
                        '},' +
                        '"FAV_4":{' +
                            '"label":"' + favcommandsL10n.matlabLogo + '",' +
                            '"icon":"icon_matlab_favorite_16",' +
                            '"code":"% ' + favcommandsL10n.matlabLogoComment1 + '\\nlogo;\\n\\n% ' + favcommandsL10n.matlabLogoComment2 + '\\ndrawnow;\\n\\n% ' + favcommandsL10n.matlabLogoComment3 + '\\n[az,el] = view;\\nfor step = 1: 360\\n    % ' + favcommandsL10n.matlabLogoComment4 + '\\n    view(az + step, el);\\n    % ' + favcommandsL10n.matlabLogoComment5 + '\\n    pause(0.005);\\nend\\n",' +
                            '"isInQAB":false,' +
                            '"showText":false,' +
                            '"editable":true,' +
                            '"state":"0"' +
                        '}' +
                    '}' +
                '},' +
                '"layout":{' +
                    '"categories":[' +
                        '"CAT_1",' +
                        '"CAT_2"' +
                    '],' +
                    '"favorites":{' +
                        '"CAT_1":[],' +
                        '"CAT_2":["FAV_1","FAV_2","FAV_3","FAV_4"]' +
                    '}' +
                '}' +
            '}';
    const favoriteCommandsDataService = { // should only have package level clients
        category: {
            create: function (data) {
                validateData(data, 'categories');

                updateModel({ action: 'create', type: 'categories', data });
            },
            get: function (id) { // TODO: support getting and setting specific properties instead of batch operations
                let obj;

                if (!modelLoaded) {
                    loadModel();
                    return null;
                }

                validateId(id, 'categories');

                if (model.data.categories.hasOwnProperty(id)) {
                    obj = copyObj(model.data.categories[id]);
                    obj.index = model.layout.categories.indexOf(id);
                    obj.children = model.layout.favorites[id].slice();
                }

                delete obj.code;

                return obj;
            },
            set: function (id, data) { // TODO: support getting and setting specific properties instead of batch operations
                validateId(id, 'categories');
                validateData(data, 'categories');

                updateModel({ action: 'update', type: 'categories', id, data });
            },
            delete: function (id) {
                validateId(id, 'categories');

                updateModel({ action: 'delete', type: 'categories', id });
            }
        },
        favorite: {
            create: function (data) {
                validateData(data, 'favorites');

                updateModel({ action: 'create', type: 'favorites', data });
            },
            get: function (id) { // TODO: support getting and setting specific properties instead of batch operations
                let obj;

                if (!modelLoaded) {
                    loadModel();
                    return null;
                }

                validateId(id, 'favorites');

                if (model.data.favorites.hasOwnProperty(id)) {
                    obj = copyObj(model.data.favorites[id]);

                    model.layout.categories.some(function (categoryId) {
                        const idx = model.layout.favorites[categoryId].indexOf(id);
                        if (idx > -1) {
                            obj.index = idx;
                            obj.parentId = categoryId;
                            return true;
                        }
                        return false;
                    });
                }

                return obj;
            },
            set: function (id, data) { // TODO: support getting and setting specific properties instead of batch operations
                validateId(id, 'favorites');
                validateData(data, 'favorites');

                updateModel({ action: 'update', type: 'favorites', id, data });
            },
            delete: function (id) {
                validateId(id, 'favorites');

                updateModel({ action: 'delete', type: 'favorites', id });
            }
        },
        model: {
            get: function () {
                return getModel();
            },
            load: function (successCallback, failureCallback) {
                if (successCallback && typeof successCallback !== 'function') {
                    throw new Error("Input argument 'successCallback' expected to be of type 'function'.");
                }
                if (failureCallback && typeof failureCallback !== 'function') {
                    throw new Error("Input argument 'failureCallback' expected to be of type 'function'.");
                }

                if (modelLoaded) {
                    if (successCallback) {
                        successCallback(getModel());
                    }
                } else {
                    loadModel(successCallback, failureCallback);
                }
            },
            close: function () {
                if (modelDirty) {
                    // Try one last time to update and serialize the model
                    updateModel();
                }
                model = null;
                modelLoading = false;
                modelLoaded = false;
                modelDirty = false;
                modelUpdateBacklog = [];
            },
            updateFirstLoadAfterMigration: function () {
                model.firstLoadAfterMigration = false;
                serializeModel();
            },
            getVersion: getFactoryVersion
        },
        _qe: {
            isTestMode: function (value) {
                if (typeof value === 'boolean') {
                    _testMode = value;
                } else {
                    return _testMode;
                }
            },
            privateMethods: {
                parseSerializedData
            }
        }
    };

    return favoriteCommandsDataService;
});
