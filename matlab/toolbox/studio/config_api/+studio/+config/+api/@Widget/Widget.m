% Copyright 2024 The MathWorks, Inc.
% The FQN of the Class is studio.config.api.Widget
% DO NOT TOUCH
classdef  Widget < studio.config.api.ConfigElement
    methods (Access = private, Hidden)
        function result = getModel(obj)
            result = mf.zero.getModel(obj.Internal);
        end
    end
    methods (Access = public)
        function obj = Widget(varargin)
            obj@studio.config.api.ConfigElement(struct('IgnoreSuperCtor', true));
            if nargin == 0
                error(message('MATLAB:modeling:messages:NotDefaultConstructible', 'studio.config.api.Widget'));
            else
                fields = varargin{1};
                if ismissing(fields)
                    obj = [];
                elseif ~isstruct(fields)
                    error(message('MATLAB:modeling:messages:IllegalArguments', 'studio.config.api.Widget'));
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
                            error(message('MATLAB:modeling:messages:MissingArguments', 'studio.config.api.Widget'));
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
        Visible logical
        When string
    end
    methods (Access = protected, Hidden)
        value = doGetVisible(obj);
        doSetVisible(obj, value);
        value = doGetWhen(obj);
        doSetWhen(obj, value);
    end
    methods
        function value = get.Visible(obj)
            value = doGetVisible(obj);
            if ~islogical(value)
                error(message('MATLAB:modeling:messages:InvalidValueForProperty', 'Visible'));
            end
        end
        function set.Visible(obj, value)
            doSetVisible(obj, value);
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
    methods
        function S = saveobj(obj)
            error(message('MATLAB:modeling:messages:UnableToSave', 'studio.config.api.Widget'));
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
            error(message('MATLAB:modeling:messages:UnableToLoad', 'studio.config.api.Widget'));
        end
        function obj = doLoad(S)
            if ~isfield(S, 'Model')
                warning(message('MATLAB:modeling:messages:LoadInvalidValueForType', 'studio.config.api.Widget'));
            else
                % retrieve the encapsulated element
                S.Internal = S.Model.findElement(S.InternalUUID);
                S = rmfield(S, 'InternalUUID');
                % reconstruct the object
                obj = studio.config.api.Widget(S);
            end
        end
    end
end
