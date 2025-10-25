classdef (Abstract) Delegate < matlab.mixin.Scalar
%

%   Copyright 2024 The MathWorks, Inc.

    properties(Access = private)
        NumOutputsFromInvoke = -1
    end

    methods(Access = protected)

        function varargout = parenReference(obj, indexOp)
            argsCell = indexOp(1).Indices;
            if isscalar(indexOp)
                [varargout{1:nargout}] = parenReferenceSingle(obj, argsCell);
            else
                [varargout{1:nargout}] = parenReferenceChain(obj, indexOp, argsCell);
            end
        end

        function obj = parenAssign(obj, indexOp, varargin)
            if isscalar(indexOp)
                % User trying to assign to temp.
                % del() = "abc";
                id = "MATLAB:index:assignmentToTemporary";
                MException(id, message(id, class(obj))).throwAsCaller();
            else
                % Following indices might be a property and support
                % assignment.
                % del().Property = "abc"
                argsCell = indexOp(1).Indices;
                result = obj.Invoke(argsCell{:});
                [result.(indexOp(2:end))] = varargin{:};
            end
        end

        function obj = parenDelete(obj, indexOp)
            % parenDelete is the equivalent of parenAssign with null
            obj = parenAssign(obj, indexOp, []);
        end
    
        function n = parenListLength(~, ~, ~)
            % All .NET indexers will return exactly one output
            n = 1;
        end
    
    end

end

function varargout = parenReferenceSingle(obj, argsCell)
    % parenReference impl for non-chained indexing
    if obj.NumOutputsFromInvoke == -1
        ml = metaclass(obj).MethodList;
        ml = ml(strcmp({ml.Name}, "Invoke"));
        obj.NumOutputsFromInvoke = numel(ml.OutputNames);
    end

    if obj.NumOutputsFromInvoke == 0
        obj.Invoke(argsCell{:});
    elseif obj.NumOutputsFromInvoke == 1
        varargout{1} = obj.Invoke(argsCell{:});
    else
        [varargout{1:nargout}] = obj.Invoke(argsCell{:});
    end
end

function varargout = parenReferenceChain(obj, indexOp, argsCell)
    % parenReference impl for chained indexing
    temp = obj.Invoke(argsCell{:});
    if nargout == 1
        varargout{1} = temp.(indexOp(2:end));
    elseif nargout == 0
        temp.(indexOp(2:end));
        if exist("ans", "var")
            % Assign ans if one was returned
            varargout{1} = ans; %#ok
        end
    else
        [varargout{1:nargout}] = temp.(indexOp(2:end));
    end
end
