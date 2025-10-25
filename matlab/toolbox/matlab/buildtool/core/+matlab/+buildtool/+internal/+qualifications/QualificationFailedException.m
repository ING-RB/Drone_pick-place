classdef QualificationFailedException < MException
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023 The MathWorks, Inc.

    methods (Access = protected)
        function me = QualificationFailedException(id, message)
            me = me@MException(id, message);
        end

        function stack = getStack(exception)
            import matlab.buildtool.internal.trimStack
            stack = trimStack(exception.getStack@MException);
        end
    end

end
