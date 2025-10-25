%FunctionHandle
% A class that represents a function handle that exposes information about
% the function handle to the Lazy Evaluation Framework.
% Copyright 2015-2022 The MathWorks, Inc.

%{
classdef FunctionHandle
    properties (SetAccess = immutable)
        % The underlying function handle (or object supporting "feval").
        Handle;
        
        % A copy of the function stack trace captured at the point of
        % FunctionHandle construction. This is to allow the right error to
        % be thrown by gather.
        ErrorStack
        
        % The maximum number of slices this function handle should be passed
        % in any one call.
        MaxNumSlices
    end
    
    methods
        % The main constructor.
        %  functionHandle must be either a MATLAB function handle or a
        %   serializable and copyable custom class obeying the feval
        %   contract.
        %  name-value pairs are equivalent to setting the properties of this
        %  class in addition to one more:
        %
        %    CaptureErrorStack: Determines if ErrorStack should be set to
        %                       the caller stack frame up-to internal
        %                       frames
        obj = FunctionHandle(functionHandle,varargin);
        
        % This will call feval on the held function handle, passing varargin
        % as input.
        varargout = feval(obj, varargin)
        
        % Copy the FunctionHandle object but replacing the underlying
        % underlying handle with the given function handle.
        newObj = copyWithNewHandle(obj, fh)
        
        % Helper function that throws the provided error as if it were
        % thrown from the function handle.
        throwAsFunction(obj, err)
    end
end
%}
