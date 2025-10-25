function fillDataRangeInfo(self)

%

% Copyright 2011-2020 The MathWorks, Inc.
%

filteredIdx = [0, 0];
if self.paramFullRange
    filteredIdx(1) = 3;
end
if self.outputFullRange
    filteredIdx(2) = 2;
end

srcField = {'Inports', 'Outports', 'Parameters'};
dstField = {'input', 'output', 'param'};

for ii = 1:numel(srcField)
    if ismember(ii, filteredIdx)
        self.drsInfo.(dstField{ii}) = struct([]);
        continue
    end
    % And then call functions
    data = self.codeInfo.(srcField{ii});
    for jj = 1:numel(data)
        nFillData(data(jj).hVar, dstField{ii});
    end
end

% Fill the output struct with the functions
fcnField = {'init', 'step'};
for ii = 1:numel(fcnField)
    fcns = self.codeInfo.(fcnField{ii});
    for jj = 1:numel(fcns)
        nFillFunction(fcns(jj));
    end
end

% Historic customers are using prefs while others are using session flag
if (evalin('base','exist(''PolyspaceCustomBehaviour'')')==true && evalin('base','PolyspaceCustomBehaviour')==true) ...
        || (ispref('PolySpace', 'PolySpaceCustomBehaviour') && getpref('PolySpace', 'PolySpaceCustomBehaviour')==1)
    self.drsInfo = customDataRangeInfo(self.cgName, self.drsInfo);
end

    function nFillFunction(fcn)
        % Nested helper function for filling the drsInfo.fcn structure
        
        if isempty(fcn.var)
            % No arg then return!
            return
        end
        
        if isempty(self.drsInfo.fcn)
            self.drsInfo.fcn = pslink.verifier.Coder.createFcnRangeInfoStruct();
        else
            self.drsInfo.fcn(end+1) = pslink.verifier.Coder.createFcnRangeInfoStruct();
        end
        self.drsInfo.fcn(end).name = dsdd('GetAttribute', fcn.fcn, 'name');
        for kk = 1:numel(fcn.var)
            nFillArgument(fcn.var{kk}, kk);
        end
        
        % Remove the entry if no relevant argument
        if isempty(self.drsInfo.fcn(end).arg)
            self.drsInfo.fcn(end) = [];
        end
    end

    function nFillArgument(hArg, pos)
        % Nested helper function for filling the
        % drsInfo.fcn.(arg) structure
        
        category = 'arg';
        formalArg = dsdd('GetAll', hArg);
        effectiveArg = formalArg.Variable;
        
        % Create and fill the argument description
        argInfo = pslink.verifier.Coder.createDataRangeInfoStruct();
        argInfo.pos = pos;
        argInfo.expr = dsdd('GetAttribute', effectiveArg, 'name');
        argInfo.mode = 'init';
        argInfo.emit = false;
        
        varInfo = pslink.verifier.tl.Coder.getVariableInfo(effectiveArg);
        
        argType = dsdd('GetKind', effectiveArg);
        switch lower(argType)

            case 'pointer'
                argInfo.isPtr = true;
                % Check for structure
                if dsdd('GetAttribute', hArg, 'numOfChildren') > 0
                    argInfo.isStruct = true;
                    argInfo.field = nExtractFieldInfo(hArg, '');
                    argInfo.emit = true;
                end
                
            case 'struct'
                if dsdd('GetAttribute', hArg, 'numOfChildren') > 0
                    argInfo.isStruct = true;
                    argInfo.field = nExtractFieldInfo(hArg, '');
                    argInfo.emit = true;
                end
                
            case {'union', 'enum', 'undefined'}

            otherwise
                if varInfo.isScalar
                    [lsb, offset] = pslink.verifier.tl.Coder.getScalingInfo(effectiveArg);
                    [argInfo.min, argInfo.max] = nGetMinMax(effectiveArg, lsb, offset, argType);
                    argInfo.emit = true;
                end
                if varInfo.isArray
                    argInfo.isArray = true;
                    % Get the data for scalar field in constraint file
                    [lsb, offset] = pslink.verifier.tl.Coder.getScalingInfo(effectiveArg);
                    [argInfo.min, argInfo.max] = nGetMinMax(effectiveArg, lsb, offset, argType);
                    argInfo.emit = true;
                end
        end
        
        % Append the argument description
        if isempty(self.drsInfo.fcn(end).(category))
            self.drsInfo.fcn(end).(category) = argInfo;
        else
            self.drsInfo.fcn(end).(category)(end+1) = argInfo;
        end
        
    end

    function nFillData(hObj, category)
        % Fill the structure for any variable and its
        % Get the variable characteristics
        varInfo = pslink.verifier.tl.Coder.getVariableInfo(hObj);
        
        % Get the variable base type
        type = pslink.verifier.tl.Coder.getType(hObj);
        
        % Get the attribute name and check its not a lookup function
        % output variable
        name = dsdd('GetAttribute', hObj, 'name');
        lutIdx = [];
        lookupOutput = false;
        for kk = 1:numel(self.lutInfo)
            lookupOutput = strcmp(self.lutInfo(kk).outVarName, name);
            if lookupOutput
                lutIdx = kk;
                break
            end
        end
        
        % DRS information is not generated for macros or local variables
        % and not supported types - enums, bitfields, ...
        % Also no need to apply to lookup tables output variables
        if varInfo.isGlobal && ~varInfo.isMacro && ... varInfo.isScalar && ... Comment the scalar condition for now as I want to handle arrays
                ~varInfo.isStatic && pslink.verifier.tl.Coder.isSupportedType(type)

            [lsb, offset] = pslink.verifier.tl.Coder.getScalingInfo(hObj);

            minVal = [];
            maxVal = [];
            if (~self.inputFullRange && strcmpi(category, 'input')) || (~self.paramFullRange && strcmpi(category, 'param'))
                if ~lookupOutput
                    [minVal, maxVal] = nGetMinMax(hObj, lsb, offset, type);
                else
                    minVal = self.lutInfo(lutIdx).min;
                    maxVal = self.lutInfo(lutIdx).max;
                end
            end
            
            % Create DRS configuration structure
            dataInfo = pslink.verifier.Coder.createDataRangeInfoStruct();
            
            % For lookup table and volatile (and const volatile), use permanent.
            % Const must use init (more precise than permanent, even if both
            % are semantically correct).
            if varInfo.isVolatile || lookupOutput
                mode = 'permanent';
            else
                mode = 'init';
                if strcmpi(category, 'output')
                    if ~self.outputFullRange
                        mode = 'globalassert';
                    else
                        dataInfo.emit = false;
                    end
                end
            end
            
            % Generate DRS configuration for variable
            dataInfo.expr = name;            
            dataInfo.mode = mode;
            % Add structures on global variables
            if strcmpi(type, 'Struct')
                dataInfo.isStruct = true;
                dataInfo.field = nExtractFieldInfo(hObj, '');
            else
                dataInfo.min = minVal;
                dataInfo.max = maxVal;
                dataInfo.lsb = lsb;
                dataInfo.offset = offset;
                dataInfo.isArray = varInfo.isArray;
            end
            
            if isempty(self.drsInfo.(category))
                self.drsInfo.(category) = dataInfo;
            else
                self.drsInfo.(category)(end+1) = dataInfo;
            end
        end
    end

    function [minVal, maxVal] = nGetMinMax(hObj, lsb, offset, type)
        % Returns the lsb and offset for a variable
        
        % For Bool type initialize to 1 or 0 plus offset (no scaling at...)
        if strcmpi(type, 'bool')
            minVal = pslink.verifier.tl.Coder.doubleToScaledValue(0, lsb, offset, type);
            maxVal = pslink.verifier.tl.Coder.doubleToScaledValue(1, lsb, offset, type);
        else
            minVal = dsdd('GetMin', hObj);
            % Check the number of elements because min and max can be arrays of
            % values
            if numel(minVal) > 0
                minVal = minVal(1);
            end
            if ~isempty(minVal)
                minVal = pslink.verifier.tl.Coder.doubleToScaledValue(minVal, lsb, offset, type);
            end
            
            maxVal = dsdd('GetMax', hObj);
            if numel(maxVal) > 0
                maxVal = maxVal(1);
            end
            if ~isempty(maxVal)
                maxVal = pslink.verifier.tl.Coder.doubleToScaledValue(maxVal, lsb, offset, type);
            end
        end
    end

    function fieldInfo = nExtractFieldInfo(hArg, parentName)
        
        fieldInfo = cell(0, 2);
        hChild = dsdd('GetChildren', hArg);
        if dsdd('GetAttribute', hChild, 'numOfChildren') > 0
            hLeaves = dsdd('Getchildren', hChild);
            
            for kk = 1:numel(hLeaves)
                
                leafName = dsdd('GetAttribute', hLeaves(kk), 'name');
                if ~isempty(parentName)
                    fullName = [parentName, '.', leafName];
                else
                    fullName = leafName;
                end
                
                if dsdd('GetAttribute', hLeaves, 'numOfChildren') > 0
                    % Recurse to the leaf
                    infoCell = nExtractFieldInfo(hLeaves(kk), fullName);
                else
                    
                    hType = dsdd('GetType', hLeaves(kk));
                    leafType = dsdd('GetBaseType', hType);
                    argInfo.width = dsdd('GetWidth', hType);
                    
                    % get Min and Max Values
                    [lsb, offset] = pslink.verifier.tl.Coder.getScalingInfo(hLeaves(kk));
                    [minVal, maxVal] = nGetMinMax(hLeaves(kk), lsb, offset, leafType);
                    minMax = {minVal, maxVal};
                    
                    infoCell = {fullName, minMax};
                end
                fieldInfo = [fieldInfo; infoCell]; %#ok<AGROW>
            end
        end
    end
end
% LocalWords:  DRS UInt Bitfield
