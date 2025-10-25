function [varargout] = getBlockHelpMapNameAndPath(block_type)
%getBlockHelpMapNameAndPath  Returns the mapName and the relative path to the maps file for this block_type

% Copyright 2016-2019 The MathWorks, Inc.

varargout = cell(1, nargout);
[varargout{:}] = robotics.slcore.internal.block.getHelpMapNameAndPath(block_type, ...
    { % There are two blocks in this library
    'nav.slalgs.internal.PurePursuit'               'rstPurePursuitBlock';
    'nav.slalgs.internal.VectorFieldHistogram'      'rstVectorFieldHistogramBlock';
    }, ...
    { % These blocks are shared between RST and NAV (NAV has priority)
    'nav';
    'robotics';
    } ...
    );
