classdef TestClassAttributes
    % This class is undocumented and may change in a future release.
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (Constant)
        ClassAttributes (1,:) string = getClassAttributes;
        MethodAttributes (1,:) string = getMethodAttributes;
        PropertyAttributes (1,:) string = getPropertyAttributes;
    end
end

function attributes = getClassAttributes
attributes = setdiff(properties("matlab.unittest.meta.class"), properties("meta.class"));
end

function attributes = getMethodAttributes
attributes = setdiff(properties("matlab.unittest.meta.method"), properties("meta.method"));
end

function attributes = getPropertyAttributes
attributes = setdiff(properties("matlab.unittest.meta.property"), properties("meta.property"));
end

% LocalWords:  unittest
