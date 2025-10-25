function verifyForEmptyData(sfxObject, chartName)
    %#codegen
    if ~isempty(coder.target)
        return;
    end
    emptyData = {};
    emptyDataNames ='';
    for counterVar = 1 : length(sfxObject.sfInternalObjConst.Data)
        if isempty(sfxObject.(sfxObject.sfInternalObjConst.Data{counterVar}))
            emptyData{end+1} = sfxObject.sfInternalObjConst.Data{counterVar}; 
            ssId = sfxObject.sfInternalObjConst.DataSSID{counterVar};
            dataName = sfxObject.sfInternalObjConst.Data{counterVar};
            link = ['<a href="matlab:Stateflow.App.Cdr.Utils.openAndHighlightDataInSymbolsWindow(''' chartName ''', ''' num2str(ssId) ''')">'''  dataName '''</a>'];
            emptyDataNames = [emptyDataNames link ', ']; %#ok<AGROW>
        end
    end
    
    % populate warning message
    warnId = 'MATLAB:sfx:EmptyDataAfterInitialization';
    msg = getString(message(warnId, Stateflow.App.Utils.getChartHyperlink(chartName), emptyDataNames(1:end-2)));
    
    % throw warning
    if ~isempty(emptyData) && sfxObject.sfInternalObj.ConfigurationOptions.warningOnUninitializedData
        Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.throwWarning(warnId, msg, chartName);
    end
end