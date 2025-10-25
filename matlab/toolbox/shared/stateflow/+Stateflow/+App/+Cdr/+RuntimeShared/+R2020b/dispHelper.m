function dispHelper(this, objectName)
%

%   Copyright 2018-2019 The MathWorks, Inc.

    if ~isscalar(this)
        disp([class(this) ' of size [' num2str(size(this)) '].']);
        return;
    end
    h = string(getString(message('MATLAB:sfx:StateflowChart')));
    if feature('hotlinks')
        h = "<a href=""matlab:sfhelp('sf4ml')"">" + h + "</a>";
    end
    assert(isempty(coder.target), 'disp works only in MATLAB');
    h = h + newline + newline + "   " + getString(message('MATLAB:sfx:ExecutionFunction'));
    if isempty(objectName) || isequal(objectName, 'ans')
        callerVarName = 'obj';
    else
        callerVarName = objectName;
    end
    signatureString = "      step(" + callerVarName + ", Name, Value)";
    h = h + newline +  signatureString +  newline;
    headerString = h.char();
    footerString = '';
    function dispDataInDisplay(this, v, n)
        if ~isempty(v)
            footerString = [footerString blanks(3) n newline];
        end
        for p = 1:length(v)
            dataValue = Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.getStringRepresentationOfData(this.(v{p}));
            footerString = [footerString blanks(6) v{p} blanks(10-length(v{p})) ': '  dataValue newline]; %#ok<AGROW>
        end
    end
    dispDataInDisplay(this, this.StateflowInternalConstData.LocalDataName,getString(message('MATLAB:sfx:LocalData')));
    dispDataInDisplay(this, this.StateflowInternalConstData.ConstantDataName,getString(message('MATLAB:sfx:ConstantData')));
    if ~isempty(this.StateflowInternalConstData.InputEventName)
        footerString = footerString + "   " + getString(message('MATLAB:sfx:InputEventFunctions'));
        for i = 1 : length(this.StateflowInternalConstData.InputEventName)
            eventName = this.StateflowInternalConstData.InputEventName{i};
            footerString = footerString  + newline + "      " + eventName + "(" + callerVarName + ", Name, Value)";
        end
        footerString = footerString + newline;
    end
    activeStates = getActiveStates(this);
    if ~isempty(activeStates)
        activeStates = join([activeStates{:}], ''', ''');
        activeStates = activeStates{1};
        activeStates = [39,activeStates,39];
        footerString = footerString + "   " + getString(message('MATLAB:sfx:ActiveStates')) + " {" + activeStates + "}";
    end
    disp(headerString)
    disp(footerString)
end
