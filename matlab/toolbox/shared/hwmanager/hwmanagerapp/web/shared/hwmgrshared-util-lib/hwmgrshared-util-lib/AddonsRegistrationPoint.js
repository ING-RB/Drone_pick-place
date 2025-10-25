/* Utility class that serves as a Registration Point for Addons Metadata.
The Hardware Manager based web apps can use this module to listen to Addons events. */

/* Copyright 2021-2024 The MathWorks, Inc. */
'use strict';
define([
    'registration_framework_js/RegistrationFrameworkProvider',
    'registration_framework_js/ResourceType'
], function (RegistrationFrameworkProvider, ResourceType) {
    return class AddonsRegistrationPoint {
        constructor () {
            this.InstalledCallback = null;
            this.UninstalledCallback = null;
            this.Impl = null;
            this.Spec = null;
            const regFwk = RegistrationFrameworkProvider.getRegistrationFramework();
            this.RegFwk = regFwk;

            const regPtImpl = {
                enabled: function (enabledMetadata) {
                    /* Currently for support packages, the enabled event is generated from Addons + RegFwk on support package Install.
                     This is because the support packages don't yet have a "resources" folder to add to the path and get registered.
                     */

                    if (enabledMetadata.resourcesFileContents.addOnsCore.addOnType !== 'support_package') {
                        return;
                    }

                    const basecode = enabledMetadata.resourcesFileContents.addOnsCore.identifier;
                    if (this.InstalledCallback) {
                        this.InstalledCallback(basecode);
                    }
                },
                registered: function (registeredMetadata) {
                    /*
                    We need this callback currently for dev/testing purposes so that a resources folder can be programmatically added to the metadata cache and generate an event
                        matlab.internal.regfwk.registerResources(folder-with-resources);
                    */
                    if (registeredMetadata.resourcesFileContents.addOnsCore.addOnType !== 'support_package') {
                        return;
                    }
                    const basecode = registeredMetadata.resourcesFileContents.addOnsCore.identifier;
                    if (this.InstalledCallback) {
                        this.InstalledCallback(basecode);
                    }
                },
                unregistered: function (unregisteredMetadata) {
                    /* This event is generated on support package uninstall AND dev/testing purposes
                        matlab.internal.regfwk.unregisterResources(folder-with-resources);
                    */
                    if (unregisteredMetadata.resourcesFileContents.addOnsCore.addOnType !== 'support_package') {
                        return;
                    }

                    const basecode = unregisteredMetadata.resourcesFileContents.addOnsCore.identifier;
                    if (this.UninstalledCallback) {
                        this.UninstalledCallback(basecode);
                    }
                }
            };

            this.Impl = regPtImpl;

            regPtImpl.enabled = regPtImpl.enabled.bind(this);
            regPtImpl.registered = regPtImpl.registered.bind(this);
            regPtImpl.unregistered = regPtImpl.unregistered.bind(this);

            // The addons resource
            const resourceSpecification = {
                resourceName: 'addons_core',
                resourceType: ResourceType.XML
            };
            this.Spec = resourceSpecification;

            // Subscribe to the resource
            this.subscribe();
        }

        subscribe () {
            this.RegFwk.subscribe(this.Impl, this.Spec);
        }
    };
});
