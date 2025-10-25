% Copyright 2024 The MathWorks, Inc.
% The FQN of the Class is studio.config.api.ConfigElement
% DO NOT TOUCH
classdef  ConfigElement < mf.zero.matlab.HeterogeneousHandleClass
    methods (Access = private, Hidden)
        function result = getModel(obj)
            result = mf.zero.getModel(obj.Internal);
        end
    end
    methods (Access = public)
        function obj = ConfigElement(varargin)
            if nargin == 0
                error(message('MATLAB:modeling:messages:NotDefaultConstructible', 'studio.config.api.ConfigElement'));
            else
                fields = varargin{1};
                if ismissing(fields)
                    obj = [];
                elseif ~isstruct(fields)
                    error(message('MATLAB:modeling:messages:IllegalArguments', 'studio.config.api.ConfigElement'));
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
                            error(message('MATLAB:modeling:messages:MissingArguments', 'studio.config.api.ConfigElement'));
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
            if isvalid(obj.Internal)
                obj.Internal.destroy;
            end
        end
    end
    properties (GetAccess = public, SetAccess = protected, Hidden)
        Internal studio.config.ConfigElement
    end
    
    properties (GetAccess = public, SetAccess = public, Dependent)
        Name string
    end
    methods (Access = protected, Hidden)
        value = doGetName(obj);
        doSetName(obj, value);
    end
    methods
        function value = get.Name(obj)
            value = doGetName(obj);
            if ~isstring(value)
                error(message('MATLAB:modeling:messages:InvalidValueForProperty', 'Name'));
            end
        end
        function set.Name(obj, value)
            doSetName(obj, value);
        end
    end
    methods (Access = public)
        result = serializeInternal(obj);
        result = findAction(obj, name);
    end
    methods
        function S = saveobj(obj)
            error(message('MATLAB:modeling:messages:UnableToSave', 'studio.config.api.ConfigElement'));
        end
    end
    methods(Hidden)
        function S = doSave(obj)
            S = struct();
            % Add the UUID of each encapsulated property to the struct.
            S.InternalUUID = obj.Internal.UUID;
        end
    end
    methods(Static, Hidden)
        function obj = loadobj(S)
            error(message('MATLAB:modeling:messages:UnableToLoad', 'studio.config.api.ConfigElement'));
        end
        function obj = doLoad(S)
            if ~isfield(S, 'Model')
                warning(message('MATLAB:modeling:messages:LoadInvalidValueForType', 'studio.config.api.ConfigElement'));
            else
                % retrieve the encapsulated element
                S.Internal = S.Model.findElement(S.InternalUUID);
                S = rmfield(S, 'InternalUUID');
                % reconstruct the object
                obj = studio.config.api.ConfigElement(S);
            end
        end
    end
end
