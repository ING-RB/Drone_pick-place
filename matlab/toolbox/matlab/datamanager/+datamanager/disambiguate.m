function disambiguate(objs,okAction)

% Utility method for brushing/linked plots. May change in a future release.

% Copyright 2007-2019 The MathWorks, Inc.

hFig = ancestor(objs(1),'figure');
dlg = getappdata(hFig,'brushing_disambiguateDlg');
if ~isempty(dlg) && isvalid(dlg)
    figure(dlg);
    return;
end
brushedData = get(objs,'BrushData');
totalBrushedPoints = zeros(length(objs),1);
for i=1:length(objs)
    totalBrushedPoints(i) = sum(brushedData{i});
end
objType = get(objs,'Type');
objTag = get(objs,'Tag');
tableData = table(totalBrushedPoints,objType,objTag,...
    'VariableNames',{getString(message('MATLAB:datamanager:disambiguate:NumberOfBrushedPoints')); 'Type'; 'Tag'});
% Build and show Disambiguation dialog to resolve ambiguity
datamanager.disambiguationDialog(hFig,objs,tableData,okAction{1},false);