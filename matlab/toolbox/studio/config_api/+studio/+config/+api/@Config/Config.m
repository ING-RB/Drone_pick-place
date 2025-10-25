% Copyright 2024 The MathWorks, Inc.
% The FQN of the Class is studio.config.api.Config
% DO NOT TOUCH
classdef  Config < mf.zero.matlab.HeterogeneousHandleClass
    methods (Access = private, Hidden)
        function result = getModel(obj)
            result = obj.Model;
        end
    end
    methods (Access = public)
        function obj = Config(varargin)
            if nargin == 0
                obj.Model = mf.zero.Model;
                obj.IsModelManaged = true;
                obj.Internal = studio.config.Config(obj.Model);
            else
                fields = varargin{1};
                if ismissing(fields)
                    obj = [];
                elseif ~isstruct(fields)
                    error(message('MATLAB:modeling:messages:IllegalArguments', 'studio.config.api.Config'));
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
                    if isempty(obj.Model)
                        obj.Model = mf.zero.Model;
                        obj.IsModelManaged = true;
                    else
                        obj.IsModelManaged = false;
                    end
                    % Ensure encapsulated properties are initialized
                    if isempty(obj.Internal)
                        obj.Internal = studio.config.Config(obj.Model);
                    end
                end
            end
        end
        
        function delete(obj)
            obj.cascadeDeleteContainments();
            if obj.IsModelManaged
                obj.Model.destroy;
            else
                if isvalid(obj.Internal)
                    obj.Internal.destroy;
                end
            end
        end
    end
    
    methods(Access = protected)
        function cascadeDeleteContainments(obj)
            delete(obj.Elements);
        end
    end
    properties (Hidden)
        Model mf.zero.Model;
        IsModelManaged logical;
    end
    properties (GetAccess = public, SetAccess = protected, Hidden)
        Internal studio.config.Config
    end
    
    properties (GetAccess = public, SetAccess = private)
        Elements (1,:) studio.config.api.ConfigElement
    end
    methods (Access = private)
        doSetElementsInternalHierarchy(obj, toInsert);
        doUnsetElementsInternalHierarchy(obj, toRemove);
    end
    methods (Access = public)
        function result = createIntoElements(obj, id, varargin)
            if ~isempty(obj.Elements) && any(strcmp([obj.Elements.Name], id))
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
            obj.doSetElementsInternalHierarchy(result);
            result.ContainerObject = obj;
            obj.Elements(end+1) = result;
            addlistener(result, 'ObjectBeingDestroyed', ...
                @(src, data) obj.onObjectBeingDestroyedInElements(src, data));
        end
        
        function removeFromElements(obj, elementOrIndex)
            if ~isempty(obj.Elements)
                if isa(elementOrIndex, 'studio.config.api.ConfigElement')
                    index = find(ismember(obj.Elements, elementOrIndex));
                    element = elementOrIndex;
                elseif  ischar(elementOrIndex) || isstring(elementOrIndex)
                    index = find(strcmp([obj.Elements.Name], string(elementOrIndex)), 1);
                    if ~isempty(index)
                        element = obj.Elements(index);
                    else
                        error('Element not found');
                    end
                elseif isnumeric(elementOrIndex)
                    element = obj.Elements(elementOrIndex);
                    index = elementOrIndex;
                else
                    error('Illegal argument. Cannot remove element');
                end
                obj.doUnsetElementsInternalHierarchy(element);
                obj.Elements(index) = [];
                delete(element);
            end
        end
        
        function clearElements(obj)
            txn = obj.getModel().beginRevertibleTransaction();
            for i = 1:numel(obj.Elements)
                obj.doUnsetElementsInternalHierarchy(obj.Elements(i));
            end
            txn.commit;
            delete(obj.Elements);
            obj.Elements = studio.config.api.ConfigElement.empty;
        end
        
    end
    methods (Access = protected)
        function onObjectBeingDestroyedInElements(obj, src, ~)
            if ~isvalid(obj)
                return;
            end
            obj.removeFromElements(src);
        end
    end
    methods (Access = public)
        result = addElement(obj, id, type);
        removeElement(obj, id);
        result = getElement(obj, id);
        result = findAction(obj, name);
    end
    methods
        function S = saveobj(obj)
            S = struct();
            
            % Serialize the model to string in a root class. Add the serialized model to the struct.
            serializer = mf.zero.io.JSONSerializer();
            ModelData = serializer.serializeToString(obj.Model);
            S.ModelData = ModelData;
            % Add the UUID of each encapsulated property to the struct.
            S.InternalUUID = obj.Internal.UUID;
            % Add the associated properties to the struct
            if isempty(obj.Elements)
                S.Elements = studio.config.api.ConfigElement.empty(1,0);
            else
                ElementsStruct = struct();
                for i = 1:numel(obj.Elements)
                    ElementsStruct.(strcat('ElementsElement', num2str(i))) = obj.Elements(i).doSave();
                end
                S.Elements = ElementsStruct;
            end
        end
    end
    methods(Static, Hidden)
        function obj = loadobj(S)
            LoadStruct = struct();
            
            % parse the model
            parser = mf.zero.io.JSONParser;
            Model = mf.zero.Model();
            parser.Model = Model;
            parser.parseString(S.ModelData);
            LoadStruct.Model = Model;
            LoadStruct.IsModelManaged = true;
            % restore the associated properties
            if ~isstruct(S.Elements)
                LoadStruct.Elements = S.Elements;
            else
                fields = fieldnames(S.Elements);
                Elements = [];
                % restore each element
                for i = 1:numel(fields)
                    elementStruct = S.Elements.(fields{i});
                    elementStruct.Model = Model;
                    element = studio.config.api.ConfigElement.doLoad(elementStruct);
                    Elements = [Elements element];
                end
                LoadStruct.Elements = Elements;
            end
            % restore the encapsulated properties
            LoadStruct.Internal = Model.findElement(S.InternalUUID);
            % reconstruct the object
            obj = studio.config.api.Config(LoadStruct);
        end
    end
end
