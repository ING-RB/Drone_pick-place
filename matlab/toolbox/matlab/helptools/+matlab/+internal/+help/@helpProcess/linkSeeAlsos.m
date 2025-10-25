function linkSeeAlsos(hp, helpSections, pathName, fcnName, inClass)
    if ~isempty(helpSections.SeeAlso)
        % Parse the "See Also" portion of help output to isolate function names.
        seealsoStr = helpSections.SeeAlso.helpStr;

        seealsoStr = hp.hotlinkList(seealsoStr, pathName, fcnName, false, inClass);
        
        helpSections.SeeAlso.helpStr = seealsoStr;
    end
end

%   Copyright 2024 The MathWorks, Inc.
