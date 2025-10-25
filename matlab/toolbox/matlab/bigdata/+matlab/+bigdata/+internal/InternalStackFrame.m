%InternalStackFrame
% Helper RAII class that marks the current stack frame as internal-only.
% This means it will not be included in the stack thrown by tall/gather.

%   Copyright 2016-2022 The MathWorks, Inc.

%{
classdef InternalStackFrame < handle
    
    methods
        % Construct a internal frame marker for the current function.
        %
        % This optionally accepts an override to the user stack frame. This
        % is to allow the tall/invoke methods to insert the name of the
        % method as a stack frame.
        obj = InternalStackFrame(userStack)
    end
    
    methods (Static)
        % Static method that returns true if and only if InternalStackFrame
        % objects exist.
        tf = hasInternalStackFrames()
        
        % Static method that returns the user-visible part of the stack.
        stack = userStack()
    end  
end
%}
