function out = getLinkPriority(libName)
%  GETLINKPRIORITY(LIBNAME) returns the linkPriority for the specified 
% library. Use this function to set the linkPriority of 3P libraries such 
% as TBB and IPP in buildInfo.addLinkObjects(). When linkPriority is
% unspecified, it defaults to 1000.

% Copyright 2015-2021 The MathWorks, Inc.

switch lower(libName)
    case 'tbb'
        out = 800;
    otherwise
        error(message('imageio:getLinkPriority:unknownLibrary',libName));
end
