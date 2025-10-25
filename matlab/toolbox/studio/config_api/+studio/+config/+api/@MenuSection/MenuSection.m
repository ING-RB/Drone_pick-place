% Copyright 2024 The MathWorks, Inc.
% The FQN of the Class is studio.config.api.MenuSection
% DO NOT TOUCH
classdef  MenuSection < studio.config.api.Widget
    methods (Access = private, Hidden)
        function result = getModel(obj)
            result = mf.zero.getModel(obj.Internal);
        end
    end
    methods (Access = public)
        function obj = MenuSection(varargin)
            obj@studio.config.api.Widget(struct('IgnoreSuperCtor', true));
            if nargin == 0
                error(message('MATLAB:modeling:messages:NotDefaultConstructible', 'studio.config.api.MenuSection'));
            else
                fields = varargin{1};
                if ismissing(fields)
                    obj = [];
                elseif ~isstruct(fields)
                    error(message('MATLAB:modeling:messages:IllegalArguments', 'studio.config.api.MenuSection'));
                elseif isfield(fields, 'IgnoreSuperCtor') && fields.IgnoreSuperCtor == true
                    % Do nothing
                else
                    fNames = fieldnames(fields);
                    for i = 1:numel(fNames)
                        field = fNames{i};
                        if isprop(obj, field)
                            obj.(field) = fields.(field);
                        end
                    end
                    if isempty(obj.Internal)
                        if ~(isfield(fields, 'Model') & isa(fields.Model, 'mf.zero.Model'))
                            error(message('MATLAB:modeling:messages:MissingArguments', 'studio.config.api.MenuSection'));
                        end
                    end 
                    % Ensure encapsulated properties are initialized
                    if isempty(obj.Internal)
                        obj.Internal = studio.config.ConfigElement(fields.Model);
                    end
                end
            end
        end
        
        function delete(obj)
            obj.cascadeDeleteContainments();
            if isvalid(obj.Internal)
                obj.Internal.destroy;
            end
        end
    end
    
    methods(Access = protected)
        function cascadeDeleteContainments(obj)
            delete(obj.Items);
        end
    end
    properties (GetAccess = public, SetAccess = private)
        Items (1,:) studio.config.api.ConfigElement
    end
    methods (Access = private)
        doSetItemsInternalHierarchy(obj, toInsert);
        doUnsetItemsInternalHierarchy(obj, toRemove);
    end
    methods (Access = public)
        function result = createIntoItems(obj, id, varargin)
            if ~isempty(obj.Items) && any(strcmp([obj.Items.Name], id))
                error('An element with the same id already exists.');
            end
            fields = struct();
            fields.Model = obj.getModel();
            if nargin == 3
                className = varargin{1};
                if (~isequal(className, 'studio.config.api.ConfigElement') && ...
                       ~any(strcmp(superclasses(className), 'studio.config.api.ConfigElement')))
                    error('%s is not a subtype of studio.config.api.ConfigElement.', className);
                end
                result = feval(className, fields);
            else
                result = studio.config.api.ConfigElement(fields);
            end
            result.Name = id;
            obj.doSetItemsInternalHierarchy(result);
            result.ContainerObject = obj;
            obj.Items(end+1) = result;
            addlistener(result, 'ObjectBeingDestroyed', ...
                @(src, data) obj.onObjectBeingDestroyedInItems(src, data));
        end
        
        function removeFromItems(obj, elementOrIndex)
            if ~isempty(obj.Items)
                if isa(elementOrIndex, 'studio.config.api.ConfigElement')
                    index = find(ismember(obj.Items, elementOrIndex));
                    element = elementOrIndex;
                elseif  ischar(elementOrIndex) || isstring(elementOrIndex)
                    index = find(strcmp([obj.Items.Name], string(elementOrIndex)), 1);
                    if ~isempty(index)
                        element = obj.Items(index);
                    else
                        error('Element not found');
                    end
                elseif isnumeric(elementOrIndex)
                    element = obj.Items(elementOrIndex);
                    index = elementOrIndex;
                else
                    error('Illegal argument. Cannot remove element');
                end
                obj.doUnsetItemsInternalHierarchy(element);
                obj.Items(index) = [];
                delete(element);
            end
        end
        
        function clearItems(obj)
            txn = obj.getModel().beginRevertibleTransaction();
            for i = 1:numel(obj.Items)
                obj.doUnsetItemsInternalHierarchy(obj.Items(i));
            end
            txn.commit;
            delete(obj.Items);
            obj.Items = studio.config.api.ConfigElement.empty;
        end
        
    end
    methods (Access = protected)
        function onObjectBeingDestroyedInItems(obj, src, ~)
            if ~isvalid(obj)
                return;
            end
            obj.removeFromItems(src);
        end
    end
    methods (Access = public)
        result = addItem(obj, id, type);
        removeItem(obj, id);
        result = findAction(obj, name);
    end
    methods
        function S = saveobj(obj)
            error(message('MATLAB:modeling:messages:UnableToSave', 'studio.config.api.MenuSection'));
        end
    end
    methods(Hidden)
        function S = doSave(obj)
            S = struct();
            % Add the UUID of each encapsulated property to the struct.
            S.InternalUUID = obj.Internal.UUID;
            % Add associated properties to the struct.
            if isempty(obj.Items)
                S.Items = studio.config.api.ConfigElement.empty(1,0);
            else
                ItemsStruct = struct();
                for i = 1:numel(obj.Items)
                    ItemsStruct.(strcat('ItemsElement', num2str(i))) = obj.Items(i).doSave();
                end
                S.Items = ItemsStruct;
            end
        end
    end
    methods(Static, Hidden)
        function obj = loadobj(S)
            error(message('MATLAB:modeling:messages:UnableToLoad', 'studio.config.api.MenuSection'));
        end
        function obj = doLoad(S)
            if ~isfield(S, 'Model')
                warning(message('MATLAB:modeling:messages:LoadInvalidValueForType', 'studio.config.api.MenuSection'));
            else
                % retrieve the encapsulated element
                S.Internal = S.Model.findElement(S.InternalUUID);
                S = rmfield(S, 'InternalUUID');
                % restore the associated properties
                if isstruct(S.Items)
                    fields = fieldnames(S.Items);
                    Items = [];
                    
                    for i = 1:numel(fields)
                        elementStruct = S.Items.(fields{i});
                        elementStruct.Model = S.Model;
                        element = studio.config.api.ConfigElement.doLoad(elementStruct);
                        Items = [Items element];
                    end
                    S.Items = Items;
                end
                % reconstruct the object
                obj = studio.config.api.MenuSection(S);
            end
        end
    end
end
