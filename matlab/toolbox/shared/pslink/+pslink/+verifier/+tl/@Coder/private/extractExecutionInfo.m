function execMap = extractExecutionInfo(self)

%

% Copyright 2012-2020 The MathWorks, Inc.
%

% Create a map SampleTime->{fcn,var}
execMap = containers.Map({1}, {{}});
execMap.remove(1);

dataMap = containers.Map({double(1)}, {false});
dataMap.remove(1);

% Init structure for variables
srcField = {'Inports', 'Outports', 'Parameters'};
for ii = 1:numel(srcField)
    self.codeInfo.(srcField{ii}) = struct([]);
end

%% Get Global Variables
hInterfVars = dsdd('find', ['/Subsystems/', self.cgName], 'ObjectKind', 'InterfaceVariable');
for ii = 1:length(hInterfVars)
    variableKind = dsdd('GetKind', hInterfVars(ii));
    
    switch variableKind
        case 'GLOBAL_INPUT'
            filledVar = nGetArgId(hInterfVars(ii));
            if nIsValidVariable(filledVar) && ~dataMap.isKey(filledVar)
                nFillCategories(hInterfVars(ii), 'Inports');
                dataMap(filledVar) = true;
                nAddVariableToMap(filledVar, -1);
            end
            
        case 'GLOBAL_OUTPUT'
            filledVar = nGetArgId(hInterfVars(ii));
            if nIsValidVariable(filledVar) && ~dataMap.isKey(filledVar)
                nFillCategories(hInterfVars(ii), 'Outports');
                dataMap(filledVar) = true;
            end
            
        otherwise
            % GetFunctionKind possible values (case sensitive):
            % GLOBAL_INPUT
            % GLOBAL_OUTPUT
            % RETURN_VALUE
            % ACTUAL_RETURN_VALUE
            % FORMAL_ARGIN
            % FORMAL_ARGOUT
            % ACTUAL_ARGIN_VALUE
            % ACTUAL_ARGIN_REFERENCE
            % ACTUAL_ARGIN_CONSTANT
            % ACTUAL_ARGIN_EXPRESSION
            % ACTUAL_ARGOUT_REFERENCE
            % FORMAL_ARG
            
            if pssharedprivate('isPslinkAvailable') && pslinkprivate('pslinkattic', 'getBinMode', 'debug')
                otherVariables = dsdd('GetAttribute', hInterfVars(ii), 'name');
                fprintf(1, 'Got %s as %s\n', otherVariables, variableKind);
            end
    end
end

% No specific calibration then return
if ~self.paramFullRange
    % Locating Parameters & LUT variables
    hVars = dsdd('find', ['/Subsystems/', self.cgName], 'ObjectKind', 'Variable');
    for ii = 1:length(hVars)
        % Filter out and add variable to list of  parameters
        if ~dataMap.isKey(hVars(ii)) && nIsValidVariable(hVars(ii), true)
            % Fill the CodeInfo
            if isempty(self.codeInfo.Parameters)
                self.codeInfo.Parameters = createVariableInfoStruct();
            else
                self.codeInfo.Parameters(end+1) = createVariableInfoStruct();
            end
            self.codeInfo.Parameters(end).hVar = hVars(ii);
            % Map the Parameters
            nAddVariableToMap(hVars(ii), -inf);
            dataMap(hVars(ii)) = true;
        end
    end
end

%% Map functions
hFcts = dsdd('find',['/Subsystems/', self.cgName], 'ObjectKind', 'Function');
fctField = {'init', 'step', 'term'};

for ii = 1:numel(fctField)
    self.codeInfo.(fctField{ii}) = struct([]);
end

% Filter out subfunctions
subFcts =  dsdd('find',['/Subsystems/', self.cgName], 'ObjectKind', 'Subfunction');
subFunctions = [];
for ii = 1:length(subFcts)
    subFunctions{ii} = dsdd('GetAttribute', subFcts(ii), 'name');
end

for ii=1:length(hFcts)
    functionKind = dsdd('GetFunctionKind', hFcts(ii));
    fcnClsId = dsdd('GetFunctionClass', hFcts(ii));
    if ~isempty(fcnClsId)
        fcnCls = dsdd('GetAll', fcnClsId);
        if isfield(fcnCls, 'Storage') && strcmpi(fcnCls.Storage, 'static')
            continue
        end
        if isfield(fcnCls, 'Macro') && fcnCls.Macro
            continue
        end
        if isfield(fcnCls, 'CompilerInline') && fcnCls.CompilerInline
            continue
        end
        if dsdd('GetInlinedCode',hFcts(ii))
            continue
        end
    end
    switch functionKind
        case {'InitFcn','RestartFcn'}
            % Filter out subfunctions
            currentFunction = dsdd('GetAttribute', hFcts(ii), 'name');
            if any(strcmpi(currentFunction,subFunctions(:)))
                continue
            end
            if isempty(self.codeInfo.init)
                self.codeInfo.init = pslink.verifier.Coder.createFcnInfoStruct();
            else
                self.codeInfo.init(end+1) = pslink.verifier.Coder.createFcnInfoStruct();
            end
            self.codeInfo.init(end).fcn = hFcts(ii);
            self.codeInfo.init(end).var = nGetFormalArgs(hFcts(ii));
            self.codeInfo.init(end).sTime = -inf;
            
        case 'StepFcn'
            % Filter out subfunctions
            currentFunction = dsdd('GetAttribute', hFcts(ii), 'name');
            if any(strcmpi(currentFunction,subFunctions(:)))
                continue
            end
            if isempty(self.codeInfo.step)
                self.codeInfo.step = pslink.verifier.Coder.createFcnInfoStruct();
            else
                self.codeInfo.step(end+1) = pslink.verifier.Coder.createFcnInfoStruct();
            end
            self.codeInfo.step(end).fcn = hFcts(ii);
            self.codeInfo.step(end).var = nGetFormalArgs(hFcts(ii));
            self.codeInfo.step(end).sTime = dsdd('GetSampleTime', hFcts(ii));
            
        case 'TermFcn'
            if isempty(self.codeInfo.term)
                self.codeInfo.term = pslink.verifier.Coder.createFcnInfoStruct();
            else
                self.codeInfo.term(end+1) = pslink.verifier.Coder.createFcnInfoStruct();
            end
            self.codeInfo.term(end).fcn = hFcts(ii);
            self.codeInfo.term(end).sTime = [];
            
        otherwise
            % GetFunctionKind possible values (case sensitive):
            % StepFcn
            % InitFcn
            % TermFcn
            % AuxFcn
            % RestartFcn
            % EntryFcn
            % ExitFcn
            % StartupFcn
            % MainRestartFcn
            % MainInitFcn
            % MainTermFcn
            
            if pssharedprivate('isPslinkAvailable') && pslinkprivate('pslinkattic', 'getBinMode', 'debug')
                otherFunctions = dsdd('GetAttribute', hFcts(ii), 'name');
                fprintf(1, 'Got %s as %s\n', otherFunctions, functionKind);
            end
    end
    
end

%% Fill the execMap
for ii = 1:numel(self.codeInfo.init)
    nAddFunctionToMap(self.codeInfo.init(ii), true);
end
for ii = 1:numel(self.codeInfo.step)
    nAddFunctionToMap(self.codeInfo.step(ii), false);
end

%% Nested helper functions ------------------------------------------------
    function Args = nGetFormalArgs(hFcts)
        % Get functions arguments
        Args = [];
        hArgs = dsdd('GetFormalArguments', hFcts);
        fctArgs = dsdd('GetAll', hArgs);
        if ~isempty(fctArgs)
            fctArgFields = fieldnames(fctArgs);
            for jj=1:length(fctArgFields)
                hVar = fctArgs.(fctArgFields{jj});
                Args = [Args, {hVar}];%#ok<AGROW>
            end
        end
    end

%--------------------------------------------------------------------------
    function nFillCategories(hObj, category)
        % Jump from the Interface Variable to the Variable
        interfVar = dsdd('GetAll', hObj);
        hVar = interfVar.Variable;
        if isempty(self.codeInfo.(category))
            self.codeInfo.(category) = createVariableInfoStruct();
        else
            self.codeInfo.(category)(end+1) = createVariableInfoStruct();
        end
        self.codeInfo.(category)(end).hVar = hVar;
    end

%--------------------------------------------------------------------------
    function hVar = nGetArgId(hObj)
        interfVar = dsdd('GetAll', hObj);
        hVar = interfVar.Variable;
        if ~isinteger(hVar)
            hVar = dsdd('GetAttribute', interfVar.Variable, 'hDDObject');
        end
    end

%--------------------------------------------------------------------------
    function nAddFunctionToMap(fcn, isInit)
        if isempty(fcn.sTime)
            if isInit
                stKey = -inf;
            else
                stKey = -1;
            end
        else
            stKey = fcn.sTime;
            if isempty(stKey)
                return
            end
        end
        if ~execMap.isKey(stKey)
            execMap(stKey) = {{},{}};
        end
        mVal = execMap(stKey);
        mVal{1} = [mVal{1}, {nGetFctName(fcn.fcn)}];
        for ll=1:length(fcn.var)
            mVal{2} = unique([mVal{2}, {nGetFctArgName(fcn.var{ll})}]);
        end
        execMap(stKey) = mVal;
    end

%--------------------------------------------------------------------------
    function nAddVariableToMap(hVar, sampleTime)
        if ~execMap.isKey(sampleTime)
            execMap(sampleTime) = {{},{}};
        end
        val = execMap(sampleTime);
        val{2} = unique([val{2}, {dsdd('GetAttribute', hVar, 'name')}]);
        execMap(sampleTime) = val;
    end

%--------------------------------------------------------------------------
    function fctName = nGetFctName(hFct)
        fctName = dsdd('GetAttribute', hFct, 'name');
    end

%--------------------------------------------------------------------------
    function ArgName = nGetFctArgName(hVar)
        myVar = dsdd('GetAll', hVar);
        ArgName = dsdd('GetAttribute', myVar.Variable, 'name');
    end

%--------------------------------------------------------------------------
    function isValidVar = nIsValidVariable(hObj, isParam)
        if nargin < 2
            isParam = false;
        end
        isValidVar = false;
        % Get the class of the variable and the macro flag
        objClass = dsdd('GetClass', hObj);
        if ~isempty(objClass)
            varInfo = pslink.verifier.tl.Coder.getVariableInfo(hObj);

            if varInfo.isMacro || varInfo.isStatic || ~varInfo.isGlobal % ... || ~varInfo.isScalar || ~varInfo.isArray 
                return
            end

            % Enable DRS on calibration parameters
            setConstraintsOnParam = (evalin('base','exist(''psConstraintsOnParam'')')==true ... 
                && evalin('base','psConstraintsOnParam')==true);
            if isParam && ~strcmpi(varInfo.info, 'readwrite') && setConstraintsOnParam
                return
            end

            type = pslink.verifier.tl.Coder.getType(hObj);
            isValidVar = pslink.verifier.tl.Coder.isSupportedType(type);
        end
    end
%--------------------------------------------------------------------------
    function varInfo = createVariableInfoStruct()
        varInfo = struct(...
            'hVar', []...
            );
    end
end
% LocalWords:
