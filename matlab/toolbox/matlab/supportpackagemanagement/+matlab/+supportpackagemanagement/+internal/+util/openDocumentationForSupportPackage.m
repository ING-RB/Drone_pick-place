function openDocumentationForSupportPackage(identifier)
    % matlab.supportpackagemanagement.internal.util.openDocumentataionForSupportPackage
    % - An internal function that returns opens documentation for a Support Package given
    % its identifier (baseCode)
    %
    % This function is called by Add-Ons in product layer to respond to the
    % 'Open documentation' request from the Add-On Manager and Explorer
    
    % Copyright 2022 The MathWorks, Inc.
    
    sproot = matlabshared.supportpkg.getSupportPackageRoot;
    matlabshared.supportpkg.internal.ssi.openExamplesForBaseCodes(cellstr(identifier), sproot);    
    end
    
    