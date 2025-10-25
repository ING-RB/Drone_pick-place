function [RowNames,ColNames] = getrcname(this)
%GETRCNAME  Provides input and output names for display.

%  Copyright 1986-2004 The MathWorks, Inc.

% Default: read corresponding InputName/OutputName properties
RowNames = this.OutputName;
ColNames = this.InputName;
