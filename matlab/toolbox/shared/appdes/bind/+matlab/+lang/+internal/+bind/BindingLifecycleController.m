classdef BindingLifecycleController < handle
    %BINDINGLIFECYCLECONTROLLER manages the lifecycle of all bindings
    % created with BIND

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (SetAccess=private)
        Bindings (1,:) matlab.lang.Binding
    end

    properties (Access=private)
        SourcesDic = dictionary(string.empty, cell.empty);
        DestinationsDic = dictionary(string.empty, cell.empty);
        BindingsDic = dictionary(double.empty, matlab.lang.Binding.empty);
        BindingIdCounter = 0;
    end

    methods

        function bindings = get.Bindings(obj)
            bindings = obj.BindingsDic.values;
        end

        function binding = createBinding(obj, source, sourceParameter, destination, destinationParameter, nameValueArgs)
            % CREATEBINDING - creates a matlab.lang.Binding and holds a
            % reference to it to manage its lifecycle.
            arguments
                obj
                source (1,1) {mustBeA(source,'handle')}
                sourceParameter char
                destination (1,1) {mustBeA(destination,'handle')}
                destinationParameter char
                nameValueArgs.Enabled (1,1) logical = true;
            end

            sourceId = string(keyHash(source));
            destinationId = string(keyHash(destination));
            bindingId = getNextBindingId(obj);

            if obj.SourcesDic.isKey(sourceId)
                sourceBindingIds = obj.SourcesDic(sourceId);
                sourceBindingIds = sourceBindingIds{:};
            else
                sourceBindingIds = [];
            end

            if obj.DestinationsDic.isKey(destinationId)
                destinationBindingIds = obj.DestinationsDic(destinationId);
                destinationBindingIds = destinationBindingIds{:};
            else
                destinationBindingIds = [];
            end

            % Check if binding already exists & delete it
            if ~isempty(sourceBindingIds) && ~isempty(destinationBindingIds)
                for bn = sourceBindingIds
                    existingBinding = obj.BindingsDic(bn);
                    
                    % A binding is the same if the source and destination
                    % are the same handles, and the properties being bound
                    % are the same
                    if ...
                            existingBinding.Source == source &&...
                            isequal(existingBinding.SourceParameter, sourceParameter) &&...
                            existingBinding.Destination == destination &&...
                            isequal(existingBinding.DestinationParameter, destinationParameter)
                        
                        sourceBindingIds(sourceBindingIds == bn) = [];
                        destinationBindingIds(destinationBindingIds == bn) = [];
                        
                        delete(existingBinding);
                        continue;
                    end
                end
            end

            optionArgs = namedargs2cell(nameValueArgs);

            binding = matlab.lang.Binding(source, sourceParameter, destination, destinationParameter, optionArgs{:});
    
            addlistener(binding,"ObjectBeingDestroyed", @(~,~)obj.handleBindingDestroyed(bindingId, sourceId, destinationId));
            addlistener(binding.Source, "ObjectBeingDestroyed", @(~,~)delete(binding));
            addlistener(binding.Destination, "ObjectBeingDestroyed", @(~,~)delete(binding));

            obj.SourcesDic(sourceId) = {[sourceBindingIds bindingId]};
            obj.DestinationsDic(destinationId) = {[destinationBindingIds bindingId]};
            obj.BindingsDic(bindingId) = binding;                       
        end

        function bindings = find(obj, sourceOrDestination, type)
            % FIND - finds bindings for a specified source or destination
            %   sourceOrDestination - object that is a source or
            %       destination of a binding
            %   type - use 'source' or 'destination' to indicate that you
            %       want to find the binding where the object is a source
            %       or destination respectively. If type is not specified
            %       or is '', it will find bindings where the object is
            %       either a source or a destination.
            arguments
                obj
                sourceOrDestination
                type = ""
            end

            bindings = matlab.lang.Binding.empty;

            key = string(keyHash(sourceOrDestination));

            if type == "source"
                if obj.SourcesDic.isKey(key)
                    bindingIds = obj.SourcesDic(key);
                    bindings = obj.BindingsDic([bindingIds{:}]);
                end
            elseif type == "destination"
                if obj.DestinationsDic.isKey(key)
                    bindingIds = obj.DestinationsDic(key);
                    bindings = obj.BindingsDic([bindingIds{:}]);
                end
            else
                bindingIds = {};
                if obj.SourcesDic.isKey(key)
                    bindingIds = [bindingIds obj.SourcesDic(key)];                  
                end

                if obj.DestinationsDic.isKey(key)
                    bindingIds = [bindingIds obj.DestinationsDic(key)];                        
                end
                
                bindings = [bindings obj.BindingsDic([bindingIds{:}])];
            end
        end
        
        function clearAllBindings(obj)
            % Clears all bindings and resets everything
            %
            % Currently only used by tests
            
            % Delete all bindings
            delete(obj.BindingsDic.values)
            
            % Refresh dictionaries / graph
            obj.SourcesDic = dictionary(string.empty, cell.empty);
            obj.DestinationsDic = dictionary(string.empty, cell.empty);
            obj.BindingsDic = dictionary(double.empty, matlab.lang.Binding.empty);
        end
    end
    
    methods (Access=private)

        function id = getNextBindingId(obj)
            obj.BindingIdCounter = obj.BindingIdCounter + 1;
            id = obj.BindingIdCounter;
        end

        function dic = removeBindingIdsFromDictionary(~, dic, objectId, bindingId)
            if dic.isKey(objectId)
                bindingIds = dic(objectId);
                bindingIds = bindingIds{:};
                bindingIds(bindingIds == bindingId) = [];
                if isempty(bindingIds)
                    dic(objectId) = [];
                else
                    dic(objectId) = {bindingIds};
                end
            end
        end

        function handleBindingDestroyed(obj, bindingId, sourceId, destinationId)

            if obj.BindingsDic.isKey(bindingId)
                obj.BindingsDic(bindingId) = [];
            end

            obj.SourcesDic = removeBindingIdsFromDictionary(obj, obj.SourcesDic, sourceId, bindingId);
            obj.DestinationsDic = removeBindingIdsFromDictionary(obj, obj.DestinationsDic, destinationId, bindingId);
        end
    end
end

