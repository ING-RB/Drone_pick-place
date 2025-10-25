function rclabel(this,varargin)
%RCLABEL  Maps ChannelName to axes' row/col labels.

%  Copyright 2013-2016 The MathWorks, Inc.

% Derive labels from I/O names
GridSize = this.AxesGrid.Size;
this.AxesGrid.ColumnLabel = {''};
Names = this.OutputName; % Note: for fd plot, OutputName contains both input and output names
if GridSize(3)>1
   Names = [Names'; repmat({''},[1 length(Names)])];
   Names = Names(:);
end
this.AxesGrid.RowLabel = Names;
