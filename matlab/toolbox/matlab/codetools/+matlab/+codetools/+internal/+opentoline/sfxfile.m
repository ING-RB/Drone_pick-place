function sfxfile(fileName, lineNumber, ~, ~)%
    %
    
    % Copyright 2017-2019 The MathWorks, Inc.
    
    % Plug-in for the opentoline function for MATLAB sfx files.
    
    try
        open(fileName);
        %get the corresponding label index in the Chart Editor and highlight it
        [~, fn, ~]=fileparts(fileName);
        sfxFileReader = Simulink.loadsave.SLXPackageReader(fileName);
        debugInfo = sfxFileReader.readPartToVariable('/code/debugInfoForSFXRuntime');
        if ~debugInfo.UserLineToSSID.isKey(lineNumber)
            return;
        end
        ssid = debugInfo.UserLineToSSID(lineNumber);
        objType = debugInfo.UserLineToSFFunctionType(lineNumber);
        methodType = debugInfo.UserLineToMethodTypeId(lineNumber);
        lineNo = debugInfo.UserLineToMLFcnLineNo(lineNumber);
        startI = debugInfo.UserLineToStartI(lineNumber);
        endI = debugInfo.UserLineToEndI(lineNumber);
        
        if isempty(ssid)
            return;
        end
        if methodType == 19
            Stateflow.App.Cdr.Utils.openAndHighlightDataInSymbolsWindow(fn, num2str(ssid));
            return;
        end
        sfprivate('open_using_ssid', [fn ':1:' int2str(ssid)]);
        staticRuntimeH = Stateflow.App.Cdr.Runtime.InstanceIndRuntime.instance;
        idFromSSID = staticRuntimeH.calculate_ids_ssid_mappings(fn);
        
        objH  = sf('IdToHandle',idFromSSID(ssid(1)));
        staticRuntimeH.deleteAllDebugHighlights();

        if isa(objH, 'Stateflow.EMFunction')
            objH.view;
            if feature('openMLFBInSimulink')
                hEditor = slmle.api.getActiveEditor;
            else
                hEditor = matlab.desktop.editor.getActive;
            end
            hEditor.goToLine(lineNo(1))
        else
            objH.view;            
            Stateflow.internal.Debugger.addDebuggerHighlightWithColor(objH.id, startI(1), endI(1), 0.99, 0, 0);
        end
        staticRuntimeH.currentInDebugObjectInfo = objH;
    catch ME        
        %don't throw errors except for MATLAB only install
        if isequal(ME.identifier,'MATLAB:sfx:SFLicenseMissingForSFX') 
            throw(ME);
        end
    end

end
