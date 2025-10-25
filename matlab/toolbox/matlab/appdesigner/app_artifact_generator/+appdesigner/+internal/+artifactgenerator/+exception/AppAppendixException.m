classdef AppAppendixException < MException
    %APPAPPENDIXEXCEPTION

%   Copyright 2024 The MathWorks, Inc.

    properties (Access = private, Hidden)
        StackFrame
    end

    methods
        function obj = AppAppendixException(filepath)
            obj@MException(message('MATLAB:appdesigner:appdesigner:AppAppendixException'));

            [~, ctorName, ~] = fileparts(filepath);

            obj.StackFrame = struct('file', char(filepath), 'name', char(ctorName), 'line', double(0));
        end
    end

    methods (Access = protected)
        function stack = getStack(obj)
            stack = obj.StackFrame;
        end
    end
end
