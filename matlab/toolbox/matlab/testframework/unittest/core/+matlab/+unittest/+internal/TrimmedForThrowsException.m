classdef TrimmedForThrowsException < matlab.unittest.internal.TrimmedException
    % This class is undocumented.
    
    % Copyright 2015-2019 MathWorks, Inc.
    
    methods
        function trimmed = TrimmedForThrowsException(other)
            trimmed = trimmed@matlab.unittest.internal.TrimmedException(other);
        end
    end
    
    methods(Access=protected)
        function stack = getStack(trimmed)
            % Trim anything under FunctionHandleConstraint or Throws
            
            stack = trimmed.OriginalException.getStack;
            
            frameworkFolder = matlab.unittest.internal.getFrameworkFolder;
            fcnHandleConstraintLocation = fullfile(frameworkFolder, "unittest", "core", "+matlab","+unittest", "+internal", "+constraints", "FunctionHandleConstraint.");
            throwsLocation = fullfile(frameworkFolder, "unittest", "core", "+matlab", "+unittest", "+constraints", "Throws.");
            
            idx = find(startsWith({stack.file}, [fcnHandleConstraintLocation, throwsLocation]), 1, "first");
            
            stack(idx:end) = [];
        end
    end
end

