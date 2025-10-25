function updateSource(this,newModel,newFocus)
%

%   Copyright 2016-2020 The MathWorks, Inc.

this.Model = newModel;
this.Focus = newFocus;
send(this,'SourceChanged')
end
