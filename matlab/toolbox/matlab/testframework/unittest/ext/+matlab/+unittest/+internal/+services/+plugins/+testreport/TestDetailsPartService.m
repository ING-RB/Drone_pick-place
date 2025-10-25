classdef TestDetailsPartService < matlab.unittest.internal.services.Service
    % This class is undocumented and may change in a future release.
    
    % Copyright 2018 The MathWorks, Inc.
    
    methods (Abstract)
        parts = provideParts(service, liaison)
    end
    
    methods (Sealed)
        function fulfill(services, liaison)
            parts = arrayfun(@(s)makeRow(s.provideParts(liaison)), services, 'UniformOutput', false);
            liaison.Parts = [liaison.Parts, parts{:}];
        end
    end
end

function row = makeRow(anyMatrix)
row = reshape(anyMatrix, 1, []);
end