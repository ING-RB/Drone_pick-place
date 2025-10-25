function tf = useOptimizedFunctions(varargin)
% For internal testing use only

% This function is used by code generation based functions to 
% decide whether or not the IPT functions re-authored by the Parallel
% Code Generation team should be used.
%
% TF = useOptimizedFunctions() Returns the previously stored state as a boolean 
% value. The default value is true unless it was reset. This syntax is used
% when codegen target is MATLAB Host.

% TF = useOptimizedFunctions(MODE) Returns the input boolean MODE value and also
%  updates its state. 

%   Copyright 2019 The MathWorks, Inc.

narginchk(0,1);

persistent useOptimizedVersion

if isempty(useOptimizedVersion)
    % Default (use improved version)
    useOptimizedVersion = true;
end

% Update state to new mode value
if ~isempty(varargin)
    validateattributes(varargin{1},{'logical'},{},mfilename);
    useOptimizedVersion = varargin{1};
end

tf = useOptimizedVersion;
