function update(this, varargin)
% Sync GUI with object state.

% Copyright 2013 The MathWorks, Inc.

set(this.Handles.InputListbox,'String',this.InputName,...
   'Value', find(this.InputSelected));
set(this.Handles.OutputListbox,'String',this.OutputName,...
   'Value', find(this.OutputSelected));
