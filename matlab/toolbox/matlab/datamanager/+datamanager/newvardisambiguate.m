function newvardisambiguate(objs,okAction,~)

% This static method builds and controls the dialog which resolves
% ambiguity caused by attempting to create a variable from multiple brushed
% graphic objects.

% Copyright 2007-2019 The MathWorks, Inc.

% If there is just one brushed object - immediately show export dialog.
% There is no need to show disambiguation dialog to resolve ambiguity
if numel(objs) == 1
    brushedData = feval(okAction,objs(1));
    export2wsdlg({getString(message('MATLAB:datamanager:brushobj:EnterVariableName'))}, ...
        {'brushedData'}, ...
        {brushedData}, ...
        getString(message('MATLAB:datamanager:brushobj:ExportToWorkspace')));
else
    hFig = ancestor(objs(1),'figure');
    dlg = getappdata(hFig,'brushing_disambiguateDlg');
    if ~isempty(dlg) && isvalid(dlg)
        figure(dlg);
        return;
    end
    totalBrushedPoints = zeros(length(objs),1);
    for i=1:length(objs)
        bdata = (get(objs(i),'BrushData')>0);
        totalBrushedPoints(i) = sum(bdata(:));
    end
    objType = get(objs,'Type');
    objTag = get(objs,'Tag');
    tableData = table(totalBrushedPoints,objType,objTag,...
        'VariableNames',{getString(message('MATLAB:datamanager:disambiguate:NumberOfBrushedPoints')); 'Type'; 'Tag'});
    % Build and show Disambiguation dialog to resolve ambiguity
    datamanager.disambiguationDialog(hFig,objs,tableData,okAction,true);
end