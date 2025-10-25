classdef ViewPropertiesHandler < appdesservices.internal.interfaces.controller.AbstractControllerMixin
    % VIEWPROPERTIESHANDLER Define interfaces to handle component's
    % properties for view, and provide default implementation for some
    % methods.
    %
    % ViewPropertiesHandler offers two major functionalities:
    % 1) A way to get a list of property names for view.
    %    getPropertyNamesForView() is the template method, which will use
    %    getAdditionalPropertyNamesForView() and
    %    getExcludedPropertyNamesForView() to customize the list.
    % 2) A way to get PV pairs of the properties for view.
    %    getPropertiesForView() is implemented by the subclass to get
    %    values of the properties for view.
    %    getPVPairsForView() is a public method to be get PV pairs for
    %    properties.

    % Copyright 2018-2024 The MathWorks, Inc.

    properties
        % List of property names that do not change from call to call
        PropertyNamesToProcess;
        ExcludedPropertyNamesForView;
        ModePropertyNames = string.empty();
        PropertiesWithModePropertyNames = string.empty();
    end

    methods(Abstract, Access = 'protected')
        % GETPROPERTIESFORVIEW(OBJ, PROPERTYNAMES) gets the properties that
        % will be needed by the view when PROPERTYNAMES of the model
        % changes.
        %
        % Inputs:
        %
        %  propertyNames - a cell array of strings containing the names of
        %                  the properties of the model that have changed.
        %
        % Outputs:
        %
        %  pvPairs - Cell array of alternating names and values for
        %           all properties that the view will need to update the
        %           visual on the screen.
        %
        %           Controllers should do the following:
        %           1) Look at the list of property names and determine for
        %              those propert names if there are any specific
        %              transformations that need to be applied, such as:
        %              a) finessing a property value, maybe by adding padding,
        %                 trimming blanks, etc... before having that value sent
        %                 to the view
        %
        %              b) creating special view specific properties, such
        %              as reading the data from a 'Filename' or 'Icon'
        %              property and encoding it for the view
        %
        %           2) Returna all transformed / finessed values as a list
        %           of pvPairs.
        %
        %           For any property names NOT returned in this list of
        %           pvPairs, those properties will be directly sent to the
        %           view as is with no conversion.

        pvPairsForView = getPropertiesForView(obj, propertyNames);


        % Get the properties to be sent to the view.
        % By default, all the public properties of the component are
        % sent.
        % If more or less properties are to be sent, subclasses should
        % use the methods:
        % -- getAdditionalPropertyNamesForView to add properties
        % -- getExcludedPropertyNamesForView to exclude properties
        %
        % An example of such information is the aspect ratio limits:
        % the information needs to be sent to the view but is not a
        % public property
        propertiesForView = getPropertyNamesForView(obj);
    end

    methods(Access=protected)
        function additionalPropertyNamesForView = getAdditionalPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be sent to the view in addition to the ones pushed
            % to the view by default (i.e. all public properties)
            %
            % Example:
            % ListBox controller returns 'SelectedIndex' because this
            % property is needed by the view, but it is not a public
            % property

            additionalPropertyNamesForView = {};
        end

        function excludedPropertyNames = getExcludedPropertyNamesForView(obj)
            % Hook for subclasses to provide a list of property names that
            % needs to be excluded from the properties to sent to the view
            %
            % Examples:
            % - Children, Parent, are not needed by the view
            % - Position, InnerPosition, OuterPosition are not updated by
            % the view and are excluded so their peer node values don't
            % become stale

            excludedPropertyNames = {};
        end

        function filteredValuesStruct = handleChangedPropertiesWithMode(obj, model, changedValuesStruct, includeHiddenProperty, priorModePropertyOnModel)
            filteredValuesStruct = changedValuesStruct;
        end

    end

    methods(Static)

        function [matchedPropertyNames, modePropertyNames] = parseClassPropertyNamesForMode(classname, includeHiddenProperty)

            % Gather all properties on the object
            mc = meta.class.fromName(classname);
            if includeHiddenProperty
                publicProperties = findobj(mc.PropertyList, 'GetAccess', 'public');
            else
                publicProperties = findobj(mc.PropertyList, 'GetAccess', 'public', 'Hidden', false);
            end
            objectPropertyNames = string({publicProperties.Name});

            % Array for the properties in propertyValuesStruct that have a mode
            % property
            matchedPropertyNames = string.empty;

            % Array for the mode properties
            modePropertyNames = objectPropertyNames(endsWith(objectPropertyNames, 'Mode'));

            % Loop through mode names looking for matching public property
            for idx = 1:numel(modePropertyNames)
                modeName = modePropertyNames(idx);
                propertyName = regexprep(modeName, 'Mode', '');
                if any(strcmp(objectPropertyNames, propertyName))
                    matchedPropertyNames = [matchedPropertyNames, propertyName];
                else
                    % We will later index into ModePropertyNames using the
                    % matching PropertiesWithModePropertyNames, so we need
                    % to fill unmatched indexes to keep them lined up.
                    matchedPropertyNames = [matchedPropertyNames, ""];
                end
            end
        end
    end

    methods(Access = public, Sealed = true)

        function propertyStruct  = getPropertiesForViewDuringConstruction(obj, model, disableCache)
            arguments
                obj
                model
                disableCache = true;
            end
            propertyStruct = struct("PropertyValues", [], ...
                "IsJSON", false);
            if (model.isCacheReady())
                pvPairs = obj.getPVPairsForView(model, string(obj.Model.getDirtyProperties())');
                if disableCache
                    model.disableCache();
                end
            else
                pvPairs = obj.getPVPairsForView(model);
            end

            propertyStruct.PropertyValues = appdesservices.internal.peermodel.convertPvPairsToStruct(pvPairs);

            obj.storeCachedPropertiesForViewDuringConstruction(propertyStruct);
        end

        function pvPairs = getPVPairsForView(obj, model, propertyNames)
            % Gathers up pv pairs that will be sent to the view, given a
            % set of changedPropertyNames
            % VC and GBT components have different access control to Model
            % property, and so this method requires to model be passed in.
            % In the future, if cosolidating to provide a same way to get
            % Model, can get rid of this argument
            %
            % This algorithm will:
            %
            % - exclude all properties that have been dirtied but are not
            % part of 'getPropertyNamesForView'.  These types of properties
            % do not need to be sent.
            %
            % - ask controller subclasses if there are any custom PV pairs
            %
            % - exclude properties not needed by the view
            % Note: this needs to be done after getting custom PV pairs
            % from controller subclasses because those custom PV pairs
            % might depend on propertiesthat won't be sent to the view.
            % e.g. Size/Location depend on Position, but Position is not
            % sent to the view
            %
            % - automatically convert properties that need no conversion

            import appdesservices.internal.util.ismemberForStringArrays;

            if isempty(obj.PropertyNamesToProcess)
                % Get all the property names that can be sent to the view
                obj.PropertyNamesToProcess = string(getPropertyNamesForView(obj));
            end

            allProperties = obj.PropertyNamesToProcess;

            if nargin == 3
                % Keep the ones that have changed
                indicies = ismemberForStringArrays(propertyNames, allProperties);
                changedProperties = propertyNames(indicies);
            else
                changedProperties = allProperties;
            end

            % g3532103: Include property names that needs to be excluded
            % from the properties to sent to the view
            if isempty(obj.ExcludedPropertyNamesForView)
                obj.ExcludedPropertyNamesForView = string(getExcludedPropertyNamesForView(obj));
            end

            if (isempty(changedProperties))
                % Quit if there are no changed properties
                pvPairs = {};
                return;
            end

            % Get view property-value pairs from controller subclass
            customPVPairs = obj.getPropertiesForView(changedProperties);

            % Get all properties that need no conversion
            %
            % Properties that need no conversion are all properties in the
            % 'changedProperties' set that were not present in specific
            % conversions done by the controller subclass
            customPropertyNames = string(customPVPairs(1:2:end))';

            % Remove properties that don't need to be sent to the view
            % Note: this needs to be done after getting the custom PV
            % pairs. see comments at the top.

            excludedProperties = obj.ExcludedPropertyNamesForView;

            nonCustomPropertyNames = changedProperties;
            % Go through all non-converted properties and just directly put
            % them into a pvPair array
            defaultPVPairs = {};
            propertiesToNotAddManually = [excludedProperties; customPropertyNames];

            % get indicies of properties in the non custom PropertyNames
            % that are not permitted to be added manually
            idx = ~ismemberForStringArrays(nonCustomPropertyNames, propertiesToNotAddManually);

            propNames = cellstr(reshape(nonCustomPropertyNames(idx), 1, numel(nonCustomPropertyNames(idx))));
            nonCustomPVPairs = reshape([propNames; get(model, propNames)], 1, numel(propNames) * 2);

            % All properties going to the view are the customPVPairs and
            % the PV Pairs that were automatically converted
            pvPairs = [customPVPairs, defaultPVPairs, nonCustomPVPairs];
        end
    end
end
