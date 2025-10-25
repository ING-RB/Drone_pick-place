function z = getData(this, r)
% Copy I/O data from source to plot "Data".

%  Copyright 2013-2024 The MathWorks, Inc.

if nargin==1
   r = false;
end

if islogical(r)
   z = getData(this.IOData,r); % iddata
   return
end

FromPreview = this.UsePreview;
d = r.Data;
Context = r.Context;
if isempty(Context) 
   ExpNo = 1;
else
   ExpNo = Context.ExpNo;
end
   
yu = getSignalData(this.IOData, [], FromPreview, ExpNo );
if this.IOSize(2)>0
   d.InputData = yu(this.IOSize(1)+1:end);
end
if this.IOSize(1)>0
   d.OutputData = yu(1:this.IOSize(1));
end
d.Focus = getTimeRange(d);
