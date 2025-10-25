function  classname = superiorfloat(varargin)  %#ok<STOUT>
%SUPERIORFLOAT return 'double' or 'single' based on the superior input.
%
%   SUPERIORFLOAT(...) returns 'double' if superior input has class double,
%   char, or logical.
%
%   SUPERIORFLOAT(...) returns 'single' if superior input has class single.
%
%   SUPERIORFLOAT errors, otherwise.
  
%   Copyright 1984-2022 The MathWorks, Inc.

throw(MException(message('MATLAB:datatypes:superiorfloat')));
