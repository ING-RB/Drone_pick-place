classdef TestReportDocumentService < matlab.unittest.internal.services.Service
    
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