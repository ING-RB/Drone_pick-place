function setStageCacheSize(cdfId,numBuffers)
%cdflib.setStageCacheSize Specify staging cache buffers for CDF
%   cdflib.setStageCacheSize(cdfId,numBuffers) specifies the number of cache
%   buffers used for the staging scratch file of a CDF identified by cdfId.  
%   Please refer to the CDF User's Guide for a discussion of caching.
%
%   This function corresponds to the CDF library C API routine 
%   CDFsetStageCacheSize.
%
%   Please read the file cdfcopyright.txt for more information.
%
%   See also cdflib.getStageCacheSize.

% Copyright 2009-2022 The MathWorks, Inc.

validateattributes(numBuffers,{'numeric'},{'scalar','>',0},'','NUMBUFFERS');
matlab.internal.imagesci.cdflib('setStageCacheSize',cdfId,numBuffers);
