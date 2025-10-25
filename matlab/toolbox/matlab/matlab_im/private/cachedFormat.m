function return_fmt = cachedFormat(varargin)
%CACHEDFORMAT - access and modify image format cached by last imread call
%   FORMAT = CACHEDFORMAT returns the currently cached image format
%   represented by a structure. The fields in this structure are:
%
%        ext         - A cell array of file extensions for this format
%        isa         - Function to determine if a file "IS A" certain type
%        info        - Function to read information about a file
%        read        - Function to read image data from a file
%        write       - Function to write MATLAB data to a file
%        alpha       - 1 if the format has an alpha channel, 0 otherwise
%        description - A text description of the file format
%
%   The values for the isa, info, read, and write fields must be functions
%   which are on the MATLAB search path or function handles.
%
%   FORMAT = CACHEDFORMAT(FMT) sets the cached format to FMT and returns
%   the current value of cached format. FMT must either be a structure
%   containing information about an image format as defined above or an
%   empty array. Use CACHEDFORMAT([]) to reset the cached format.
%
%   See also IMREAD, IMFORMATS.
%
%   Copyright 2019 The MathWorks, Inc.



persistent cached_fmt;
mlock

narginchk(0,1);

% if one argument, either setting (struct) or resetting (empty array)
if nargin==1 
    assert(isstruct(varargin{1}) || isempty(varargin{1}))
    cached_fmt = varargin{1};
end

% always return the current value of the cached format
return_fmt=cached_fmt;

end




