function addtip(this,tipfcn)
%ADDTIP  Adds a line tip to g-objects in dataview.
 
%  Author(s): John Glass
%  Copyright 1986-2013 The MathWorks, Inc.

if nargin==1
   % Default tip function (calls MAKETIP first on data source, then on view)
   tipfcn = @LocalTipFcn;
end

wf = findcarrier(this);  % @waveform carrier
View = this.View;
Data = this.Data;
for ct = 1:length(View)
   info = struct(...
      'Data',Data(ct),...
      'View',View(ct),...
      'Carrier',wf,...
      'Tip',[],...
      'TipOptions',{{}},...
      'Row',[],...
      'Col',[],...
      'ArrayIndex',ct);
   View(ct).addtip(tipfcn,info);
end


% ----------------------------------------------------------------------------%
% Purpose: Build tip text for dataview's
% ----------------------------------------------------------------------------%
function TipText = LocalTipFcn(DataTip,CursorInfo,info)
TipText = '';
% First try evaluating the data source's MAKETIP method
DataSrc = info.Carrier.DataSrc;
if ~isempty(DataSrc)
    try
        TipText = maketip(DataSrc,DataTip,info,CursorInfo);
    catch
        try
            TipText = maketip(DataSrc,DataTip,info);
        end
    end
end
% Otherwise use built-in tip for View object
if isempty(TipText)
    try
        TipText = maketip(info.View,DataTip,info,CursorInfo);
    catch
        try
            TipText = maketip(info.View,DataTip,info);
        end
    end
end
