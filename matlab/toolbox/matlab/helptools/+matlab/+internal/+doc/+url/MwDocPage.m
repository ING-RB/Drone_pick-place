classdef MwDocPage < matlab.internal.doc.url.DocContentPage
    methods
        function obj = MwDocPage
            obj.IsValid = true;
            obj.DocLocation = matlab.internal.doc.services.DocLocation.getActiveLocation;
            obj.UseArchive = matlab.internal.doc.url.useArchiveDoc;
        end
    end
end

% Copyright 2020-2021 The MathWorks, Inc.