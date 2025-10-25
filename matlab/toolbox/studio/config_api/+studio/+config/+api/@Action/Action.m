% Copyright 2024 The MathWorks, Inc.
% The FQN of the Class is studio.config.api.Action
% DO NOT TOUCH
classdef  Action < studio.config.api.ConfigElement
    methods (Access = private, Hidden)
        function result = getModel(obj)
            result = mf.zero.getModel(obj.Internal);
        end
    end
    methods (Access = public)
        function obj = Action(varargin)
            obj@studio.config.api.ConfigElement(struct('IgnoreSuperCtor', true));
            if nargin == 0
                error(message('MATLAB:modeling:messages:NotDefaultConstructible', 'studio.config.api.Action'));
            else
                fields = varargin{1};
                if ismissing(fields)
                    obj = [];
                elseif ~isstruct(fields)
                    error(message('MATLAB:modeling:messages:IllegalArguments', 'studio.config.api.Action'));
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
                            error(message('MATLAB:modeling:messages:MissingArguments', 'studio.config.api.Action'));
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
    properties (GetAccess = public, SetAccess = public, Dependent)
        Text string
        Description string
        Icon string
        Enabled logical
        Callback string
        When string
    end
    methods (Access = protected, Hidden)
        value = doGetText(obj);
        doSetText(obj, value);
        value = doGetDescription(obj);
        doSetDescription(obj, value);
        value = doGetIcon(obj);
        doSetIcon(obj, value);
        value = doGetEnabled(obj);
        doSetEnabled(obj, value);
        value = doGetCallback(obj);
        doSetCallback(obj, value);
        value = doGetWhen(obj);
        doSetWhen(obj, value);
    end
    methods
        function value = get.Text(obj)
            value = doGetText(obj);
            if ~isstring(value)
                error(message('MATLAB:modeling:messages:InvalidValueForProperty', 'Text'));
            end
        end
        function set.Text(obj, value)
            doSetText(obj, value);
        end
        function value = get.Description(obj)
            value = doGetDescription(obj);
            if ~isstring(value)
                error(message('MATLAB:modeling:messages:InvalidValueForProperty', 'Description'));
            end
        end
        function set.Description(obj, value)
            doSetDescription(obj, value);
        end
        function value = get.Icon(obj)
            value = doGetIcon(obj);
            if ~isstring(value)
                error(message('MATLAB:modeling:messages:InvalidValueForProperty', 'Icon'));
            end
        end
        function set.Icon(obj, value)
            doSetIcon(obj, value);
        end
        function value = get.Enabled(obj)
            value = doGetEnabled(obj);
            if ~islogical(value)
                error(message('MATLAB:modeling:messages:InvalidValueForProperty', 'Enabled'));
            end
        end
        function set.Enabled(obj, value)
            doSetEnabled(obj, value);
        end
        function value = get.Callback(obj)
            value = doGetCallback(obj);
            if ~isstring(value)
                error(message('MATLAB:modeling:messages:InvalidValueForProperty', 'Callback'));
            end
        end
        function set.Callback(obj, value)
            doSetCallback(obj, value);
        end
        function value = get.When(obj)
            value = doGetWhen(obj);
            if ~isstring(value)
                error(message('MATLAB:modeling:messages:InvalidValueForProperty', 'When'));
            end
        end
        function set.When(obj, value)
            doSetWhen(obj, value);
        end
    end
    methods (Access = public, Hidden)
        result = getInternal(obj);
    end
    
    methods (Access = public)
        setLogicalOption(obj, name, option);
        result = getLogicalOption(obj, name);
        setStringOption(obj, name, option);
        result = getStringOption(obj, name);
        setNumericOption(obj, name, option);
        result = getNumericOption(obj, name);
        clearOptions(obj);
    end
    methods
        function S = saveobj(obj)
            error(message('MATLAB:modeling:messages:UnableToSave', 'studio.config.api.Action'));
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
            error(message('MATLAB:modeling:messages:UnableToLoad', 'studio.config.api.Action'));
        end
        function obj = doLoad(S)
            if ~isfield(S, 'Model')
                warning(message('MATLAB:modeling:messages:LoadInvalidValueForType', 'studio.config.api.Action'));
            else
                % retrieve the encapsulated element
                S.Internal = S.Model.findElement(S.InternalUUID);
                S = rmfield(S, 'InternalUUID');
                % reconstruct the object
                obj = studio.config.api.Action(S);
            end
        end
    end
end
