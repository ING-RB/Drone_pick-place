classdef AcceptsImportOptions < matlab.io.internal.FunctionInterface
    %ACCEPTSIMPORTOPTIONS An interface for functions which accept a IMPORTOPTIONS.
    
    % Copyright 2018 The MathWorks, Inc.
    properties (Required)
        Options matlab.io.ImportOptions = matlab.io.text.DelimitedTextImportOptions;
    end
    
end

