function openExample(exampleId, supportingFile)
%

%   Copyright 2018-2024 The MathWorks, Inc.

    arguments
        exampleId (1,:) char
        supportingFile (1,:) char = '';
    end
   
    opts = {};
    if ~isempty(supportingFile)
        opts = {'supportingFile', supportingFile};
    end
        
    try 
        openExample(exampleId, opts{:});
    catch e
        throw(e);
    end
end
