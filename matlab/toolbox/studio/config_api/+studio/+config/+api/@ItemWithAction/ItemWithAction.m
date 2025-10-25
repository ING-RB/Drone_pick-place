% Copyright 2024 The MathWorks, Inc.
% The FQN of the Class is studio.config.api.ItemWithAction
% DO NOT TOUCH
classdef  ItemWithAction < studio.config.api.Item
    methods (Access = private, Hidden)
        function result = getModel(obj)
            result = mf.zero.getModel(obj.Internal);
        end
    end
    methods (Access = public)
        function obj = ItemWithAction(varargin)
            obj@studio.config.api.Item(struct('IgnoreSuperCtor', true));
            if nargin == 0
                error(message('MATLAB:modeling:messages:NotDefaultConstructible', 'studio.config.api.ItemWithAction'));
            else
                fields = varargin{1};
                if ismissing(fields)
                    obj = [];
                elseif ~isstruct(fields)
                    error(message('MATLAB:modeling:messages:IllegalArguments', 'studio.config.api.ItemWithAction'));
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
                            error(message('MATLAB:modeling:messages:MissingArguments', 'studio.config.api.ItemWithAction'));
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
            delete(obj.Action);
        end
    end
    properties (GetAccess = public, SetAccess = public, Dependent)
        TextOverride string
        DescriptionOverride string
        IconOverride string
        Userdata string
        ClosePopupOnClick logical
    end
    
    properties (GetAccess = public, SetAccess = private)
        Action studio.config.api.ConfigElement
    end
    methods (Access = protected, Hidden)
        value = doGetTextOverride(obj);
        doSetTextOverride(obj, value);
        value = doGetDescriptionOverride(obj);
        doSetDescriptionOverride(obj, value);
        value = doGetIconOverride(obj);
        doSetIconOverride(obj, value);
        value = doGetUserdata(obj);
        doSetUserdata(obj, value);
        value = doGetClosePopupOnClick(obj);
        doSetClosePopupOnClick(obj, value);
    end
    methods
        function value = get.TextOverride(obj)
            value = doGetTextOverride(obj);
            if ~isstring(value)
                error(message('MATLAB:modeling:messages:InvalidValueForProperty', 'TextOverride'));
            end
        end
        function set.TextOverride(obj, value)
            doSetTextOverride(obj, value);
        end
        function value = get.DescriptionOverride(obj)
            value = doGetDescriptionOverride(obj);
            if ~isstring(value)
                error(message('MATLAB:modeling:messages:InvalidValueForProperty', 'DescriptionOverride'));
            end
        end
        function set.DescriptionOverride(obj, value)
            doSetDescriptionOverride(obj, value);
        end
        function value = get.IconOverride(obj)
            value = doGetIconOverride(obj);
            if ~isstring(value)
                error(message('MATLAB:modeling:messages:InvalidValueForProperty', 'IconOverride'));
            end
        end
        function set.IconOverride(obj, value)
            doSetIconOverride(obj, value);
        end
        function value = get.Userdata(obj)
            value = doGetUserdata(obj);
            if ~isstring(value)
                error(message('MATLAB:modeling:messages:InvalidValueForProperty', 'Userdata'));
            end
        end
        function set.Userdata(obj, value)
            doSetUserdata(obj, value);
        end
        function value = get.ClosePopupOnClick(obj)
            value = doGetClosePopupOnClick(obj);
            if ~islogical(value)
                error(message('MATLAB:modeling:messages:InvalidValueForProperty', 'ClosePopupOnClick'));
            end
        end
        function set.ClosePopupOnClick(obj, value)
            doSetClosePopupOnClick(obj, value);
        end
    end
    methods (Access = private)
        doSetActionInternalHierarchy(obj, toInsert);
        doUnsetActionInternalHierarchy(obj, toRemove);
    end
    methods (Access = public)
        function result = createAction(obj, varargin)
            fields = struct();
            fields.Model = obj.getModel();
            if nargin == 2
                className = varargin{1};
                if (~isequal(className, 'studio.config.api.ConfigElement') && ...
                       ~any(strcmp(superclasses(className), 'studio.config.api.ConfigElement')))
                    error('%s is not a subtype of studio.config.api.ConfigElement.', className);
                end
                result = feval(className, fields);
            else
                result = studio.config.api.ConfigElement(fields);
            end
            obj.doSetActionInternalHierarchy(result);
            result.ContainerObject = obj;
            oldObj = obj.Action;
            obj.Action = result;
            addlistener(result, 'ObjectBeingDestroyed', ...
                @(src, data) obj.onObjectBeingDestroyedInAction(src, data));
            delete(oldObj);
        end
        
        function removeAction(obj)
            element = obj.Action;
            if ~isempty(element)
                obj.doUnsetActionInternalHierarchy(element);
                obj.Action = studio.config.api.ConfigElement.empty(0,0);
                delete(element);
            end
        end
        
    end
    methods (Access = protected)
        function onObjectBeingDestroyedInAction(obj, src, ~)
            if ~isvalid(obj)
                return;
            end
            if isequal(src, obj.Action)
                obj.removeAction;
            end
        end
    end
    methods (Access = public)
        result = initAction(obj);
        result = findAction(obj, name);
    end
    methods
        function S = saveobj(obj)
            error(message('MATLAB:modeling:messages:UnableToSave', 'studio.config.api.ItemWithAction'));
        end
    end
    methods(Hidden)
        function S = doSave(obj)
            S = struct();
            % Add the UUID of each encapsulated property to the struct.
            S.InternalUUID = obj.Internal.UUID;
            % Add associated properties to the struct.
            if isempty(obj.Action)
                S.Action = studio.config.api.ConfigElement.empty(0,0);
            else
                S.Action = obj.Action.doSave();
            end
        end
    end
    methods(Static, Hidden)
        function obj = loadobj(S)
            error(message('MATLAB:modeling:messages:UnableToLoad', 'studio.config.api.ItemWithAction'));
        end
        function obj = doLoad(S)
            if ~isfield(S, 'Model')
                warning(message('MATLAB:modeling:messages:LoadInvalidValueForType', 'studio.config.api.ItemWithAction'));
            else
                % retrieve the encapsulated element
                S.Internal = S.Model.findElement(S.InternalUUID);
                S = rmfield(S, 'InternalUUID');
                % restore the associated properties
                if isstruct(S.Action)
                    S.Action.Model = S.Model;
                    Action = studio.config.api.ConfigElement.doLoad(S.Action);
                    S.Action = Action;
                end
                % reconstruct the object
                obj = studio.config.api.ItemWithAction(S);
            end
        end
    end
end
