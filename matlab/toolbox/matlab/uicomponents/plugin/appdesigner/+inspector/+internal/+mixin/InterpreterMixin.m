classdef InterpreterMixin < handle
    % INTERPRETERMIXIN - mixin class for the Interpreter property of
    % Label

    % Copyright 2020 The MathWorks, Inc.

    properties(SetObservable = true)
        Interpreter inspector.internal.datatype.Interpreter
    end

    methods
		function set.Interpreter(obj, inspectorValue)
			obj.OriginalObjects.Interpreter = char(inspectorValue);
		end

		function value = get.Interpreter(obj)
			value = inspector.internal.datatype.Interpreter.(obj.OriginalObjects.Interpreter);
		end
	end
end