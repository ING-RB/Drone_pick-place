function hfig = movieview(varargin)
%MOVIEVIEW Show MATLAB movie with replay button
% MOVIEVIEW has been removed. Use IMPLAY instead.

% Copyright 1984-2023 The MathWorks, Inc.

me = MException(message("MATLAB:movieview:DeprecationMessage"));
me = me.addCorrection(matlab.lang.correction.ReplaceIdentifierCorrection('movieview','implay'));
throw(me);