function setData(this, NewData, Name)
% SETDATA Update data object in the data source container.

%  Copyright 2015 The MathWorks, Inc.

IOData = this.IOData;
if nargin>2
   IOData.Name = Name;
elseif ~isempty(NewData.Name)
   IOData.Name = NewData.Name;
end
IOData.Data = NewData;
