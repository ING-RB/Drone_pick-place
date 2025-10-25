function isMCOS = isMCOSClass(obj, optional)
% isMCOSClass returns true if the input object if the input object is a
% MATLAB class using the classdef syntax. It returns false for UDD and OOPS
% objects

%   Copyright 2023 The MathWorks, Inc.

arguments(Input)
    obj
    % Optional parameters
    % Issue an error if the input object is not a MATLAB class
    optional.IssueError (1,1) logical = false
end
arguments(Output)
    isMCOS (1,1) logical
end

mc = metaclass(obj);
isMCOS = false;

if isobject(obj) && ~isempty(mc)
    % Need to check the output of METACLASS to make sure input object is
    % not an OOPS class since ISOBJECT returns true for OOPS classes
    isMCOS = true;
end

if optional.IssueError && ~isMCOS
    error(message('MATLAB:objectPropertyDisplay:InputMustBeObject'));
end

end