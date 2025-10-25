function schema
% Defines properties for @axesgrid class (rectangular grid of axes)

%   Copyright 2015-2015 The MathWorks, Inc. 

% Register class 
pk = findpackage('ctrluis');
c = schema.class(pk,'axesgridPlotmatrix',findclass(pk,'axesgrid'));

% Events
schema.event(c,'FigureSizeChanged');  % notifies that axes grid has been resized