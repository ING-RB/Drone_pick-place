function [RowNames,ColNames] = getrcname(this)
%GETRCNAME  Provides input and output names for display.

%  Copyright 1986-2004 The MathWorks, Inc.
RowNames = this.ChannelName;
ColNames = {};
