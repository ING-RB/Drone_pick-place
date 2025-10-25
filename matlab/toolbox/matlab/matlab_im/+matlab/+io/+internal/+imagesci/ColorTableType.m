classdef ColorTableType < uint8
%COLORTABLETYPE enumerates and lets the user choose between local,
%   global or default color tables

%   Copyright 2017-2020 The Mathworks, Inc

    enumeration
        Global (1), Local (2), Default (3)
    end
end