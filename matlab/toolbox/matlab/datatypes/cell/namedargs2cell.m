%NAMEDARGS2CELL Convert scalar structure array containing name value pairs to cell array.
%   C = NAMEDARGS2CELL(S) converts the 1-by-1 structure S with P number of fields
%   into a 1-by-2P cell array C with interleaved names and values.
%
%   Example:
%     clear s, s.category = 'tree'; s.height = 37.4; s.name = 'birch';
%     c = namedargs2cell(s);
%
%   See also CELL2STRUCT, FIELDNAMES.

%   Built-in function.

%   Copyright 2018-2021 The MathWorks, Inc.
