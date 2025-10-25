function rclabel(this,varargin)
%RCLABEL  Maps ChannelName to axes' row/col labels.
 
%  Copyright 2013 The MathWorks, Inc.

% Derive labels from I/O names
this.AxesGrid.ColumnLabel = {''};
this.AxesGrid.RowLabel = [this.OutputName; this.InputName];
