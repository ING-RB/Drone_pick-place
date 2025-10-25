function [RowNames,ColNames] = getrcname(this)
%GETRCNAME  Provides input and output names for display.

%  Copyright 2013 The MathWorks, Inc.

% Default: read corresponding InputName/OutputName properties
RowNames = [this.OutputName; this.InputName];
ColNames = {''};
