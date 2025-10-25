function [exampleId, isMainFile] = identifyExample(arg) 
%

%   Copyright 2020-2024 The MathWorks, Inc.

    isMainFile = true; 
    exampleId = arg; 
    match = regexp(arg,'^(\w+)/(\w+)$','tokens','once');
    if isempty(match) 
        examples = matlab.internal.examples.findExamples(arg);
        if ~isempty(examples) 
            exampleId = examples(1).exampleId;
            match = regexp(exampleId,'^(\w+)/(\w+)$','tokens','once');
            isMainFile = false;
        end
    end
    
    if isempty(match) || endsWith(exampleId, "/"+arg)
        error(message("MATLAB:examples:InvalidSupportingFile",arg))
    end
end
