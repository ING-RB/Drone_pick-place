function schema
% @plotarray class: low-level axes container for @axesgroup classes.
%
% REVISIT: make a value class
% 
% Purpose: 
%   * encapsulate nested arrays of HG axes
%   * manage positioning and row/column visibility.

%   Author(s): P. Gahinet
%   Copyright 1986-2004 The MathWorks, Inc. 

% Register class 
pk = findpackage('ctrluis');
c = schema.class(pk,'plotarrayPlotmatrix',findclass(pk,'plotarray'));