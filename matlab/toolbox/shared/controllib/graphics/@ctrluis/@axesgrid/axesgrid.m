function h = axesgrid(gridsize,hndl,varargin)
% Returns instance of @axesgrid class
%
%   H = AXESGRID([M N],AXHANDLE) creates a M-by-N grid of subplots using the
%   axes handles supplied in AXHANDLE.  The subplot properties are inherited
%   from the first axes in AXHANDLE.  Additional axes are created if necessary.
%   
%   H = AXESGRID([M N MSUB NSUB],AXHANDLE) creates a M-by-N grid where each 
%   grid cell itself contains a MSUB-by-NSUB array of subplots (nested subplots).
%
%   H = AXESGRID([M N ..],FIGHANDLE) parents all the grid axes to the figure 
%   with handle FIGHANDLE.

%   Author: P. Gahinet
%   Copyright 1986-2008 The MathWorks, Inc.

% Create @axes instance and initialize
h = ctrluis.axesgrid;
constructionHelper(h,gridsize,hndl,varargin{:})
