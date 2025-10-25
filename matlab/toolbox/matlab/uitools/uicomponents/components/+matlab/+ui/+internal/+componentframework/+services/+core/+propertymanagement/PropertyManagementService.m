% PROPERTYMANAGEMENTSERVICE As a core service of the MATLAB Component Framework
% (MCF), the Property Management Service (PMS) is designed to configure model
% properties of web components and how they are reflected in the view.

%   Copyright 2014-2022 The MathWorks, Inc.

classdef PropertyManagementService < handle

    properties(Access = 'private')
        % Map of Model Property -> List<ViewModel Property>. These properties are
        % usually the ones where you look up the property, do some property
        % massaging, then rename it and then send it to the viewmodel.
        % Note that multiple Model Properties can be mapped to the same View
        % property. For instance, in figure the NumberTitle, IntegerHandle and
        % Name are mapped to the viewmodel property Title.
        ModelViewDependencies = dictionary(string.empty, cell.empty);

        % Set of properties that are present in the ViewModel. These
        % properties need not be present in the Model. For instance,
        % figure has a Color property in the model but
        % BackgroundColor property in the viewmodel. This is handled by
        % DependenciesMap.
        ModelPropertiesForView = dictionary(string.empty, logical.empty);

        % Dictionary for properties require pre-update
        RequireUpdate = dictionary(string.empty, logical.empty);

        % List of properties that require post set triggers. This is
        % computed once and stored for later.
        TriggerUpdatesProperties = string.empty;

        % List of properties on the view model. This is computed by mapping
        % ModelPropertiesForView to ModelViewDependencies. Computed once,
        % stored for later. Private, not settable. Only Gettable. 
        ViewProperties = string.empty;
    end

    methods ( Access = 'public' )
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:         defineViewProperty
        %  Inputs:         property -> Name of view property.
        %  Outputs:        None.
        %  Postconditions: Initialized property configurations, including the list
        %                  of view properties, renames and dependencies.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineViewProperty( obj, property )
            % MATLAB Component Framework's (MCF) Property Management Service (PMS)
            % provides the ability to control which model properties will participate
            % in the view representation of the web component. This method provides
            % the interface to achieve this capability.
            obj.ModelPropertiesForView(property) = true;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:         getViewProperties
        %  Inputs:         None.
        %  Outputs:        viewProperties -> String array of view properties.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function viewProperties = getViewProperties( obj )
            % Method which retrieves all the view properties from the list maintained
            % by the Property Management Service.
            if ~isempty(obj.ViewProperties)
                viewProperties = obj.ViewProperties;
                return;
            end

            modelProps = obj.getModelPropertiesForView();
            seenProps = struct();
            viewProperties = string(numel(modelProps));
            count = 1;

            for i = 1:numel(modelProps)
                propName = modelProps(i);
                if (obj.hasDependency(propName))
                    depPropName = obj.getDependencies(propName);
                    if isfield(seenProps, depPropName)
                        continue;
                    end

                    propName = depPropName;
                    seenProps.(propName) = true;
                end
                viewProperties(count) = propName;
                count = count + 1;
            end
            viewProperties = viewProperties(1:count - 1);
            obj.ViewProperties = viewProperties;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:         getModelPropertiesForView
        %  Inputs:         None.
        %  Outputs:        viewProperties -> String array of view properties.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function props = getModelPropertiesForView( obj )
            % Method which retrieves all the view properties from the list maintained
            % by the Property Management Service.
            props = keys(obj.ModelPropertiesForView);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:         isViewProperty
        %  Inputs:         None.
        %  Outputs:        hasProperty -> List of view properties.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function hasProperty = isModelPropertyForView( obj, propName)
            % Method which checks if property is present in
            % ViewPropertiesSet
            hasProperty = isKey(obj.ModelPropertiesForView, propName);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:         defineRequireUpdateProperty
        %  Inputs:         property -> Name of property requires update.
        %  Outputs:        None.
        %  Postconditions: Initialized property configurations, including the list
        %                  of properties need updates before updating to view.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function defineRequireUpdateProperty( obj, property )
            % MATLAB Component Framework's (MCF) Property Management Service (PMS)
            % provides the ability to control which model properties will participate
            % in the view representation of the web component. This method provides
            % the interface to achieve this capability.
            obj.RequireUpdate(property) = true;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:         requireUpdate
        %
        %  Inputs :        property -> Name of the property on the model side.
        %  Outputs:        Boolean which indicates if the property requires pre-update.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function isUpdateRequire = requireUpdate( obj, property )
            % Returns a boolean to indicate if the model property has been renamed on
            % the view.
            isUpdateRequire = isKey(obj.RequireUpdate, property);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:         definePropertyDependency
        %
        %  Details:        When a model side property is set, using the PMS, the
        %                  controller logic updates the dependent view side property
        %                  using a "custom update" method defined in the controller
        %                  of the web component.
        %
        %                  If for a given model side property more than one
        %                  dependency is established using the PMS, upon the setting
        %                  of the model side property, every single dependent view
        %                  side property is updated.
        %
        %  Inputs:         property -> Name of the property on the model side.
        %                  dependentProperty  -> Name of the dependent property.
        %  Outputs:        None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function definePropertyDependency( obj, property, dependentProperty )
            % MATLAB Component Framework's (MCF) Property Management Service (PMS)
            % provides the ability to define property dependencies which impact the
            % view. This method provides the interface to achieve this capability.

            % If the model side property already have a dependency, add to it,
            % otherwise create a new dependency
            if obj.hasDependency(property)
                obj.ModelViewDependencies(property) = ...
                    {[obj.getDependencies(property) , dependentProperty]};
            else
                obj.ModelViewDependencies(property) = {dependentProperty};
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:         hasDependency
        %
        %  Inputs:         property -> Name of the model side property.
        %  Outputs:        bool -> Boolean which indicates if the given property has
        %                          a property dependency.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function bool = hasDependency( obj, property )
            % Method which returns a boolean to indicate if the model property has a
            % dependency.
            bool = isKey(obj.ModelViewDependencies, property );
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:         getDependencies
        %
        %  Inputs:         property -> Name of the model property.
        %  Outputs:        dependentProperties -> Cell containing the dependencies
        %                                         for a given model side property.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function dependentProperties = getDependencies( obj, property )
            % Method which returns a cell containing a list of dependencies for a
            % given model side property.
            dependentProperties = obj.ModelViewDependencies(property);
            dependentProperties = dependentProperties{1};
        end

        % Except - list of properties to ignore. 
        function props = getTriggerUpdatesProperties(obj, except)
            % Compute once, and save it for the future. This list does not
            % change through the life cycle of the object. 
            if ~isempty(obj.TriggerUpdatesProperties)
                props = obj.TriggerUpdatesProperties; 
                return; 
            end

            exceptStruct = struct(); 
            if nargin == 2
                for i = 1:numel(except)
                    exceptStruct.(except(i)) = true;
                end
            end


            viewProperties = obj.getModelPropertiesForView();
            seenStruct = struct(); 

            for idx = 1:numel(viewProperties)
                name = viewProperties( idx );
                if isfield(exceptStruct, name)
                    continue; %skip update for given except list.
                end
                
                viewName = name;
                if obj.hasDependency(name)
                    viewName = obj.getDependencies(name);
                end

                % If we already have processed this view property, 
                % continue to the next. This is needed since multiple model
                % properties can be mapped to the same view property.
                if isfield(seenStruct, viewName)
                    continue; 
                end

                if (obj.hasDependency(name) ||  ...
                        obj.requireUpdate(name))
                    obj.TriggerUpdatesProperties = [obj.TriggerUpdatesProperties viewName];
                    seenStruct.(viewName) = true; 
                end
            end

            props = obj.TriggerUpdatesProperties;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:         defineModelPvPairs
        %
        %  Inputs:         model -> Model representation of the component.
        %                  except -> List of properties to ignore. 
        %
        %  Outputs:        pvPairs -> Property/value pairs for the view properties.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function pvPairs = defineModelPvPairs( obj, model, except)
            dirtyProperties = obj.getModelPropertiesForView();

            nDirty = numel(dirtyProperties);
            if (nDirty == 0)
                pvPairs = {};
                return;
            end

            isException = appdesservices.internal.util.ismemberForStringArrays(dirtyProperties, ...
                except);
            pvPairs = cell(1, 2 * nDirty);
            count = 1;
            for idx = 1:nDirty

                propertyName = dirtyProperties(idx);
                % Grab purely model property that does not
                % require call to update() method.
                if (isException(idx) || ...
                        obj.hasDependency(propertyName) || ...
                        obj.requireUpdate(propertyName))
                    continue;
                end

                nameInd = count * 2 - 1;
                valueInd = nameInd + 1;

                propertyValue = model.(propertyName);
                pvPairs(nameInd:valueInd) = {propertyName, propertyValue};
                count = count + 1;
            end

            pvPairs = pvPairs(1:valueInd);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:         definePvPairs
        %
        %  Inputs:         model -> Model representation of the component.
        %                  dirtyProperties -> Properties set by the user.
        %
        %  Outputs:        pvPairs -> Property/value pairs for the view properties.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function pvPairs = definePvPairs( obj, controller, model, dirtyProperties)
            % MATLAB Component Framework's (MCF) Property Management Service (PMS)
            % provides the ability to create property/value pairs based on the view
            % properties and the renames previously defined through the service. This
            % method provides the interface to achieve this capability.

            % Start constructing the property value pairs
            if (nargin == 3)
                dirtyProperties = obj.getModelPropertiesForView();
            end

            pvPairs = processDirtyModelProperties(obj, controller, ...
                model, dirtyProperties);
        end

        function pvPairs = processDirtyModelProperties(obj, controller, ...
                model, dirtyProperties)

            countProps = numel(dirtyProperties);

            if (countProps == 0)
                pvPairs = {};
                return;
            end

            pvPairs = cell(1, 2*countProps);

            % Struct performs faster than a dictionary for small datasets.
            % This dataset is small (< 30)
            seenIndex = struct();
            count = 1;
            nameInd = 0; 

            for idx = 1:countProps
                propertyName = dirtyProperties(idx);
                if ~obj.isModelPropertyForView(propertyName)
                    continue; 
                end

                % Call updateXYZ() on requireUpdate props, but mark it as
                % seen.
                if obj.requireUpdate(propertyName)
                    if isfield(seenIndex, propertyName)
                        continue;
                    end

                    propertyValue = controller.("update" + propertyName);
                    seenIndex.(propertyName) = idx;

                elseif obj.hasDependency(propertyName)
                    % Call updateXYZ() on dependent props, but mark it as
                    % seen, so that we only add it once to the list.
                    propertyName = obj.getDependencies(propertyName);

                    % If we have already dealt with this view property,
                    % ignore.
                    if isfield(seenIndex, propertyName)
                        continue;
                    end
                    propertyValue = controller.("update" + propertyName);

                    % Save this property as seen.
                    seenIndex.(propertyName) = idx;
                else
                    % If there are no requireUpdates, or dependencies, this
                    % has to be a model property. We are guaranteed that
                    % this is a model property that the view is concerned
                    % about. Therefore, lookup.
                    propertyValue = model.(propertyName);
                end
                nameInd = count * 2 - 1;
                valueInd = nameInd + 1;
                pvPairs(nameInd:valueInd) = {propertyName, propertyValue};
                count = count + 1;
            end

            % There may be unassigned pvPairs because the number of
            % ViewProperties may be less than number of Model Properties
            % due to dependencies. Therefore, index just the part we
            % filled.
            if (nameInd == 0) 
                pvPairs = {};
                return;
            end
            pvPairs = pvPairs(1:valueInd);
        end
    end

    methods( Static )

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:         convertPvPairsToStruct
        %
        %  Inputs:         pvPairs -> Property/value pairs to be converted.
        %  Outputs:        structFormat -> MATLAB structure for the PV pairs.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function structFormat = convertPvPairsToStruct( pvPairs )
            % Converts the PV pairs into MATLAB structure.
            structFormat = appdesservices.internal.peermodel.convertPvPairsToStruct( pvPairs );
        end
    end
end
