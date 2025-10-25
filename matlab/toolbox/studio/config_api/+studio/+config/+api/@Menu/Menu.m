% Copyright 2024 The MathWorks, Inc.
% The FQN of the Class is studio.config.api.Menu
% DO NOT TOUCH
classdef  Menu < studio.config.api.Widget
    methods (Access = private, Hidden)
        function result = getModel(obj)
            result = mf.zero.getModel(obj.Internal);
        end
    end
    methods (Access = public)
        function obj = Menu(varargin)
            obj@studio.config.api.Widget(struct('IgnoreSuperCtor', true));
            if nargin == 0
                error(message('MATLAB:modeling:messages:NotDefaultConstructible', 'studio.config.api.Menu'));
            else
                fields = varargin{1};
                if ismissing(fields)
                    obj = [];
                elseif ~isstruct(fields)
                    error(message('MATLAB:modeling:messages:IllegalArguments', 'studio.config.api.Menu'));
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
                            error(message('MATLAB:modeling:messages:MissingArguments', 'studio.config.api.Menu'));
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
            delete(obj.Sections);
        end
    end
    properties (GetAccess = public, SetAccess = private)
        Sections (1,:) studio.config.api.ConfigElement
    end
    methods (Access = private)
        doSetSectionsInternalHierarchy(obj, toInsert);
        doUnsetSectionsInternalHierarchy(obj, toRemove);
    end
    methods (Access = public)
        function result = createIntoSections(obj, id, varargin)
            if ~isempty(obj.Sections) && any(strcmp([obj.Sections.Name], id))
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
            obj.doSetSectionsInternalHierarchy(result);
            result.ContainerObject = obj;
            obj.Sections(end+1) = result;
            addlistener(result, 'ObjectBeingDestroyed', ...
                @(src, data) obj.onObjectBeingDestroyedInSections(src, data));
        end
        
        function removeFromSections(obj, elementOrIndex)
            if ~isempty(obj.Sections)
                if isa(elementOrIndex, 'studio.config.api.ConfigElement')
                    index = find(ismember(obj.Sections, elementOrIndex));
                    element = elementOrIndex;
                elseif  ischar(elementOrIndex) || isstring(elementOrIndex)
                    index = find(strcmp([obj.Sections.Name], string(elementOrIndex)), 1);
                    if ~isempty(index)
                        element = obj.Sections(index);
                    else
                        error('Element not found');
                    end
                elseif isnumeric(elementOrIndex)
                    element = obj.Sections(elementOrIndex);
                    index = elementOrIndex;
                else
                    error('Illegal argument. Cannot remove element');
                end
                obj.doUnsetSectionsInternalHierarchy(element);
                obj.Sections(index) = [];
                delete(element);
            end
        end
        
        function clearSections(obj)
            txn = obj.getModel().beginRevertibleTransaction();
            for i = 1:numel(obj.Sections)
                obj.doUnsetSectionsInternalHierarchy(obj.Sections(i));
            end
            txn.commit;
            delete(obj.Sections);
            obj.Sections = studio.config.api.ConfigElement.empty;
        end
        
    end
    methods (Access = protected)
        function onObjectBeingDestroyedInSections(obj, src, ~)
            if ~isvalid(obj)
                return;
            end
            obj.removeFromSections(src);
        end
    end
    methods (Access = public)
        result = addSection(obj, id);
        removeSection(obj, id);
        result = findAction(obj, name);
    end
    methods
        function S = saveobj(obj)
            error(message('MATLAB:modeling:messages:UnableToSave', 'studio.config.api.Menu'));
        end
    end
    methods(Hidden)
        function S = doSave(obj)
            S = struct();
            % Add the UUID of each encapsulated property to the struct.
            S.InternalUUID = obj.Internal.UUID;
            % Add associated properties to the struct.
            if isempty(obj.Sections)
                S.Sections = studio.config.api.ConfigElement.empty(1,0);
            else
                SectionsStruct = struct();
                for i = 1:numel(obj.Sections)
                    SectionsStruct.(strcat('SectionsElement', num2str(i))) = obj.Sections(i).doSave();
                end
                S.Sections = SectionsStruct;
            end
        end
    end
    methods(Static, Hidden)
        function obj = loadobj(S)
            error(message('MATLAB:modeling:messages:UnableToLoad', 'studio.config.api.Menu'));
        end
        function obj = doLoad(S)
            if ~isfield(S, 'Model')
                warning(message('MATLAB:modeling:messages:LoadInvalidValueForType', 'studio.config.api.Menu'));
            else
                % retrieve the encapsulated element
                S.Internal = S.Model.findElement(S.InternalUUID);
                S = rmfield(S, 'InternalUUID');
                % restore the associated properties
                if isstruct(S.Sections)
                    fields = fieldnames(S.Sections);
                    Sections = [];
                    
                    for i = 1:numel(fields)
                        elementStruct = S.Sections.(fields{i});
                        elementStruct.Model = S.Model;
                        element = studio.config.api.ConfigElement.doLoad(elementStruct);
                        Sections = [Sections element];
                    end
                    S.Sections = Sections;
                end
                % reconstruct the object
                obj = studio.config.api.Menu(S);
            end
        end
    end
end
