function success = patchdemoxmlfile(helploc)
    %  PATCHDEMOXMLFILE Patch demos.xml file.
    %
    %  PATCHDEMOXMLFILE helploc Patches a demos.xml file in the folder helploc
    %  by replacing character data in the description with non-character data.
    %
    %  PATCHDEMOXMLFILE replaces the characters '&lt;', '&gt;', '&apos;', '&quot;',
    %  and '&amp;' with '<', '>', '''', '"', and '&', respectively.
    %
    %  Examples:
    %  Patch the demos.xml file in the folder D:\Work\mytoolbox\help
    %      patchdemoxmlfile D:\Work\mytoolbox\help

    %   Copyright 2020 The MathWorks, Inc.
    
    if nargout
        success = true;
    end

    filePatcher = matlab.internal.doc.project.demoFilePatcher(helploc);
    patched = filePatcher.patchDemoFile;    
    
    if nargout
        success = patched;
    end
    
    if patched
        disp(getString(message('MATLAB:doc:PatchedDemoXmlFile')));
    end
end