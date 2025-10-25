% Copyright 2024 The MathWorks, Inc.
% The FQN of the Class is studio.config.api.MenuItem
% DO NOT TOUCH
classdef  MenuItem < studio.config.api.ItemWithAction
    methods (Access = private, Hidden)
        function result = getModel(obj)
            result = mf.zero.getModel(obj.Internal);
        end
    end
    methods (Access = public)
        function obj = MenuItem(varargin)
            obj@studio.config.api.ItemWithAction(struct('IgnoreSuperCtor', true));
            if nargin == 0
                error(message('MATLAB:modeling:messages:NotDefaultConstructible', 'studio.config.api.MenuItem'));
            else
                fields = varargin{1};
                if ismissing(fields)
                    obj = [];
                elseif ~isstruct(fields)
                    error(message('MATLAB:modeling:messages:IllegalArguments', 'studio.config.api.MenuItem'));
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
                            error(message('MATLAB:modeling:messages:MissingArguments', 'studio.config.api.MenuItem'));
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
            cascadeDeleteContainments@studio.config.api.ItemWithAction(obj);
        end
    end
    methods
        function S = saveobj(obj)
            error(message('MATLAB:modeling:messages:UnableToSave', 'studio.config.api.MenuItem'));
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
            error(message('MATLAB:modeling:messages:UnableToLoad', 'studio.config.api.MenuItem'));
        end
        function obj = doLoad(S)
            if ~isfield(S, 'Model')
                warning(message('MATLAB:modeling:messages:LoadInvalidValueForType', 'studio.config.api.MenuItem'));
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
                obj = studio.config.api.MenuItem(S);
            end
        end
    end
end
