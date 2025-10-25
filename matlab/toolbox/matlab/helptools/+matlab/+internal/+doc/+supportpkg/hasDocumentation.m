function h = hasDocumentation(id)
    spkg = matlab.internal.doc.supportpkg.getSupportPackage(id);
    h = ~isempty(spkg) && ~isempty(spkg.landing_page);
end
% Copyright 2024 The MathWorks, Inc.
