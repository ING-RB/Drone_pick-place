function generateStubs(self, pslinkOptions)
% Stubs all lookup functions it can find in the block list in all blocks for
% the subsystem "subsystem". The stub_lookups_with_void option results
% results in a void prototype being given to the new function - increasing
% Verifier performance.
% The return values are the number of lookup tables (nLookups), an array of
% lookup table information (lookup_tables) and the name of the stub file
% written.

% Copyright 2011-2024 The MathWorks, Inc.

allBlocks = dsdd('find',['/Subsystems/',self.cgName,'/ModelView'],'ObjectKind','Block');
if isempty(allBlocks)
    return
end

% Array of structures defining the added LUT
lutInfo = [];

% Set up filenames
cFile = fullfile(pslinkOptions.cfgDir, ['__' self.slModelName '_pststubs_tl.c'] );
hFile = fullfile(pslinkOptions.cfgDir, ['__' self.slModelName '_polyspace.h'] );

fprintf(1, '### %s\n', message('polyspace:gui:pslink:generatingStubs').getString());
% packaging uses native system encoding
[cFid, cErr] = fopen(cFile, 'wt', 'n', self.SourceEncoding);
[hFid, hErr]  = fopen(hFile, 'wt', 'n', self.SourceEncoding);

% if we can't open the file don't add the stubs
if isempty(cErr) && isempty(hErr)
    cleanObj = onCleanup(@()nCleanup(cFid, hFid));
    %alreadyAddedLookup = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    alreadyAddedLookup = containers.Map({'fake'}, {false});
    alreadyAddedLookup.remove('fake');
    
    fprintf(hFid, '#ifndef DEF_POLYSPACE_H\n');
    fprintf(hFid, '#define DEF_POLYSPACE_H\n\n');
    
    % to header file declaring new function
    fprintf(hFid, '#include "tl_types.h"\n');
    fprintf(hFid, '#include "tl_basetypes.h"\n');
    
    % Process all blocks
    for ii = 1:length(allBlocks)
        [isOK, lut] = writeStubFunction(allBlocks(ii), cFid, hFid, ...
            true, alreadyAddedLookup);
        
        % Keep a list of lut information for the stubbed functions
        if isOK
            if isempty(lutInfo)
                lutInfo = lut;
            else
                lutInfo(end+1) = lut; %#ok<AGROW>
            end
        end
    end
    
    fprintf(hFid, '#endif\n\n');
        
    % Always call and add the custom stub list to the lookup tables list
    self.stubList = cell(numel(lutInfo), 1);
    for lookup = 1:numel(lutInfo)
        self.stubList{lookup} = lutInfo(lookup).funcName;
    end
    self.lutInfo = lutInfo;
   
    % Buffer the created files to be added later
    if numel(lutInfo)
        self.stubFile = {hFile, cFile};
    end

else
    if ~isempty(cErr)
        warning('pslink:cannotOpenFile', '%s', message('polyspace:gui:pslink:cannotOpenFile', cFile, cErr).getString());
    end
    if ~isempty(hErr)
        warning('pslink:cannotOpenFile', '%s', message('polyspace:gui:pslink:cannotOpenFile', hFile, hErr).getString());
    end
end

    function nCleanup(cFid, hFid)
        % Nested helper cleanup function called at exit
        fclose(cFid);
        fclose(hFid);
    end

end

%--------------------------------------------------------------------------
function [ok, lut] = writeStubFunction(currBlk, cFid, hFid, stubLookupWithVoid, alreadyAddedLookup)

% Read basic lookup information from the table - into the lut structure
lut = getLookupInfo(currBlk, stubLookupWithVoid);

% Return if no info or shall be a user defined function, don't stub it
if isempty(lut) || isempty(lut.tableName)
    ok = false;
    return
end

% Add only one time the lookup table in the file __pststubs_tl.c
currentLookup = [lut.funcName, '_', lut.tableName];
if alreadyAddedLookup.isKey(currentLookup)
    % The lookup has already been added, return
    ok = false;
    return
end
% Add the lookup to the list
alreadyAddedLookup(currentLookup) = true; %#ok<NASGU>

ok = true;

% Process the lookup tab

%TBD store the #includes already written to file
if ~isempty(lut.dependList)
    for ii = 1:numel(lut.dependList)
        if ~strcmp(lut.dependList(ii).filename, lut.filename)
            % to lut stub file
            fprintf(cFid, '#include "%s"\n', lut.dependList(ii).filename);
        end
    end
end

% Generate the argument list string
paramList = sprintf('(const %s * map', lut.tableType);
if ~isempty(lut.inVar)
    for ii=1:length(lut.inVar)
        paramList = sprintf('%s, %s %s', paramList, lut.inVar(ii).type, lut.inVar(ii).name);
    end
    paramList = sprintf('%s)', paramList);
end

fprintf(cFid, '\n');
fprintf(cFid, 'extern %s pst_random_%s_%s(void);\n', lut.outVarType, lut.funcName, lut.tableName);
fprintf(cFid, '\n');
if stubLookupWithVoid
    fprintf(hFid, 'extern %s %s_%s(void);\n',        lut.outVarType, lut.funcName, lut.tableName);
    fprintf(cFid, '%s %s_%s(void) {\n',              lut.outVarType, lut.funcName, lut.tableName);
else
    fprintf(hFid, 'extern %s %s_%s%s;\n',            lut.outVarType, lut.funcName, lut.tableName, paramList);
    fprintf(cFid, '%s %s_%s%s {\n',                  lut.outVarType, lut.funcName, lut.tableName, paramList);
end

fprintf(cFid, '    %s temp;\n',                       lut.outVarType);
fprintf(cFid, '    temp = pst_random_%s_%s();\n',     lut.funcName, lut.tableName);
fprintf(cFid, '\n');

if ~strcmp(lut.min, 'min') && ~strcmp(lut.max, 'max')
    fprintf(cFid, '    if((temp < %g) || (temp > %g)) {\n', lut.min, lut.max);
    fprintf(cFid, '        temp = %g;\n',                   lut.min);
    fprintf(cFid, '    }\n');
    
elseif (strcmp(lut.min, 'min') && ~strcmp(lut.max, 'max'))
    fprintf(cFid, '    if(temp > %g) {\n',                lut.max);
    fprintf(cFid, '        temp = %g;\n',                 lut.max);
    fprintf(cFid, '    }\n');
    
elseif (~strcmp(lut.min, 'min') && strcmp(lut.max, 'max'))
    fprintf(cFid, '    if(temp < %g) {\n',                lut.min);
    fprintf(cFid, '        temp = %g;\n',                 lut.min);
    fprintf(cFid, '    }\n');
end

fprintf(cFid, '\n');
fprintf(cFid, '    return(temp);\n');
fprintf(cFid, '}\n\n');

fprintf(1, '%s\n', message('polyspace:gui:pslink:stubbedFct',...
    lut.funcName, lut.tableName, lut.lkType, lut.min, lut.max).getString());

end

%--------------------------------------------------------------------------
function lut = getLookupInfo(currBlk, stubLookupWithVoid)

try
    % TBD remove from return fields that are not used - generate real
    % struct
    lut.blkName    = '';
    lut.blkPath    = '';
    lut.lkType     = '';
    lut.lkMethod   = '';
    lut.lkNbDims   = '';
    lut.funcName   = '';              % returned & used
    lut.filename   = '';              % returned & used
    lut.min        = '';              % returned & used
    lut.max        = '';              % returned & used
    lut.tableType  = '';              % returned & used
    lut.tableName  = '';              % returned & used
    lut.outVarName = '';              % returned & used
    lut.outVarType = '';              % returned & used ?
    lut.dependList(1).filename = '';  % returned & used
    lut.inVar(1).name          = '';  % returned & used
    lut.inVar(1).type          = '';  % returned & used
            
    lut.lkType  = dsdd('Get', currBlk, 'BlockType');
    lut.blkName = dsdd('GetAttribute', currBlk, 'name');
    % get the 'path' property to avoid problems with subsystems
    lut.blkPath = dsdd('GetAttribute', currBlk, 'path');
       
    % funcName = <file>/<func_name>
    % lkMethod = InterpolationExtrapolation | InterpolationUseEndValues | UseInputNearest | UseInputAbove | UseInputBelow
    if (strcmp(lut.lkType, 'TL_Lookup1D'))
        lkData        = dsdd('find', lut.blkPath, 'name', 'Lookup1D');
        lkTable       = dsdd('find', lut.blkPath, 'name', 'Map');
        if isempty(lkTable)
            lkTable  = dsdd('find', lut.blkPath, 'name', 'LOOKUP1D_STRUCT');
        end
        lkFunc        = dsdd('Get',  lkData, 'Lookup1DFcn');
        lut.lkMethod = dsdd('Get',  lkData, 'LookupMethod');
        lut.lkNbDims = '1';
        
    elseif (strcmp(lut.lkType, 'TL_Lookup2D'))
        lkData        = dsdd('find', lut.blkPath, 'name', 'Lookup2D');
        lkTable       = dsdd('find', lut.blkPath, 'name', 'Map');
        if isempty(lkTable)
            lkTable = dsdd('find', lut.blkPath, 'name', 'LOOKUP2D_STRUCT');
        end
        lkFunc        = dsdd('Get',  lkData,  'Lookup2DFcn');
        lut.lkMethod = dsdd('Get',  lkData,  'LookupMethod');
        lut.lkNbDims = '2';
        
    elseif (strcmp(lut.lkType, 'TL_IndexSearch'))
        lkData        = dsdd('find', lut.blkPath, 'name', 'IndexSearch');
        lkTable       = dsdd('find', lut.blkPath, 'name', 'Map');
        if isempty(lkTable)
            lkTable = dsdd('find', lut.blkPath, 'name', 'INDEXSEARCH_STRUCT');
        end
        lkFunc        = dsdd('Get',  lkData,  'SearchFcn');
        lut.lkMethod = 'None';
        lut.lkNbDims = '1';
        
    elseif (strcmp(lut.lkType, 'TL_Interpolation'))
        lkData        = dsdd('find', lut.blkPath, 'name', 'Interpolation');
        lkTable       = dsdd('find', lut.blkPath, 'name', 'Map');
        if isempty(lkTable)
            lkTable = dsdd('find', lut.blkPath, 'name', 'INTERPOLATION_STRUCT');
        end
        lkFunc        = dsdd('Get',  lkData,  'InterpolationFcn');
        lut.lkNbDims = dsdd('Get',  lkData,  'nDims');
        lut.lkNbDims = num2str(lut.lkNbDims);
        lkInterpolation = dsdd('Get', lkData, 'Interpolation');
        if (lkInterpolation)
            lut.lkMethod = 'Interpolation';
        end
        lkExtrapolation = dsdd('Get', lkData, 'Extrapolation');
        if (lkExtrapolation)
            lut.lkMethod = [lut.lkMethod, 'Extrapolation'];
        end
    elseif (strcmp(lut.lkType, 'TL_LookupNDDirect'))
        % \DirectLookup -> WARNING : can't find function for direct nd block
        lut = [];
        return
    else
        lut = [];
        return
    end
    
    if ~isempty(lkFunc)
        if ischar(lkFunc)
            % lkFunc = <filename>/<functionName>
            [unused, theFunctionName] = strtok(lkFunc, '/'); %#ok<ASGLU>
            lut.funcName = strrep(theFunctionName, '/', '');
        else
            % lkFunc is the reference to the function
            lut.funcName = dsdd('GetAttribute', lkFunc, 'name');
        end
    else
        % no stub if the function name is empty
        lut = [];
        return
    end
    
    % Find file dependencies
    % The parent node of the func is the filename - look at its dependencies
    theFile       = dsdd('GetAttribute', lkFunc, 'hDDParent');
    dependObjs    = dsdd('find', theFile, 'objectKind', 'FileInfo', 'RegExp', 'Dependency.*');
    
    % Get the filename where lookup function is generated
    theModule     = dsdd('GetModuleInfo', theFile);
    theFileObj    = dsdd('GetAttribute', theModule, 'hDDFirstChild');
    lut.filename = dsdd('GetFileName', theFileObj);
    
    % Build the list of dependency filenames
    if ~isempty(dependObjs)
        dependCount = 1;
        for ii=1 : length(dependObjs)
            dependName = dsdd('GetFileName', dependObjs(ii));
            %Don't include the source file itself as a dependency
            if ~strcmp(dependName, lut.filename)
                lut.dependList(dependCount).filename = dependName;
                dependCount = dependCount + 1;
            end
        end
    end
    
    % get output variable name and range
    if (strcmp(lut.lkType, 'TL_Interpolation')) % 2.0.3A Why this test?
        theOutput = dsdd('find', lut.blkPath, 'name', 'FNC_VALUES');
    else
        theOutput = dsdd('find', lut.blkPath, 'name', 'output');
    end
    
    % Depending on the TL versions, outVarRef may not be available on DSDD
    % on the same way...
    outVarRef = dsdd('Get', theOutput, 'VariableRef');
    if isempty(outVarRef)
        theOutput = dsdd('find', lut.blkPath, 'name', 'FNC_VALUES');
        outVarRef = dsdd('Get', theOutput, 'VariableRef');
    end
    if isempty(outVarRef)
        theOutput = dsdd('find', lut.blkPath, 'objectKind', 'BlockVariable');
        for ii=1 : length(theOutput)
            outVarRef = dsdd('Get', theOutput(ii), 'VariableRef');
            outVarKeywords = dsdd('Get', outVarRef, 'Keywords');
            if any(strcmp('FNC_VALUES', outVarKeywords))
                break
            end
        end
    end
    if isempty(outVarRef)
        lut = [];
        return
    end
    
    lut.outVarName = dsdd('GetAttribute', outVarRef, 'name');
    lut.outVarType = pslink.verifier.tl.Coder.getType(outVarRef);
    [lsb, offset] = pslink.verifier.tl.Coder.getScalingInfo(outVarRef);
    
    % Find the return values
    % Start with the lookup table
    tableVarRef    = dsdd('Get', lkTable, 'VariableRef');
    tableType      = dsdd('Get', tableVarRef, 'Type');
    lut.tableType = dsdd('GetAttribute', tableType, 'Name'); % think this is tableTYPE
    lut.tableName = dsdd('GetAttribute', tableVarRef, 'Name');
    
    % Find the min max return value from the lookup function
    % At the moment only for non extrapolation functions
    if (isempty(strfind(lut.lkMethod, 'Extrapolation')))
        lutMin = dsdd('Get', outVarRef, 'Min');
        lutMax = dsdd('Get', outVarRef, 'Max');
        if ~isempty(lutMin) && ~isempty(lutMax)
            lut.min = pslink.verifier.tl.Coder.doubleToScaledValue(lutMin, lsb, offset, lut.outVarType);
            lut.max = pslink.verifier.tl.Coder.doubleToScaledValue(lutMax, lsb, offset, lut.outVarType);
        else
            funcValues     = dsdd('find', lut.blkPath, 'name', 'FNC_VALUES');
            returnTableRef = dsdd('Get', funcValues, 'VariableRef');
            lutValues     = dsdd('GetValue', returnTableRef);
            if ~isempty(lutValues)
                [lutMin,lutMax] = getMinMaxFromTable(lutValues);
                lut.min = pslink.verifier.tl.Coder.doubleToScaledValue(lutMin, lsb, offset, lut.outVarType);
                lut.max = pslink.verifier.tl.Coder.doubleToScaledValue(lutMax, lsb, offset, lut.outVarType);
            else
                lut.min = 'min';
                lut.max = 'max';
            end
        end
    else % Extrapolation is used hence full range
        lut.min = 'min';
        lut.max = 'max';
    end
    
    % Get the input variable names and types
    theInputParameters = '';
    
    % Now rest of the parameters
    if ~strcmp(lut.lkType, 'TL_Interpolation')
        theInputParameters = dsdd('find', lut.blkPath, 'objectKind', 'BlockVariable', 'RegExp', 'S.*');
    end
    
    if ~isempty(theInputParameters)
        inputCount = 1;
        for ii=1:length(theInputParameters)
            theVar    = dsdd('Get', theInputParameters(ii), 'VariableRef');
            %TBD - Check type first could be a constant and not a
            %variable
            if ~isempty(theVar)
                lut.inVar(inputCount).name = dsdd('GetAttribute', theVar, 'name');
                lut.inVar(inputCount).type = GetType(theVar);
                inputCount = inputCount + 1;
            else
                % If a constant is input (why with a table) we could be
                % in this branch and there's not enough info in the DD
                % to proceed
                if stubLookupWithVoid ~= 1
                    % we can't get the parameter list type for all
                    % parameters so we can't stub this function
                    lut = [];
                    return
                end
                % paramName = dsdd('GetAttribute', theInputParameters(i), 'name');
                % paramType = GetType(theInputParameters(i));
                % paramWidth = dsdd('GetWidth',theInputParameters(i));
            end
        end
    end
    
catch Me %#ok<NASGU>
    warning('pslink:LUTGenerationError', message('polyspace:gui:pslink:LUTGenerationError', lut.blkName).getString());
    lut = [];
end

end

%--------------------------------------------------------------------------
function [lutMin, lutMax] = getMinMaxFromTable(lutValues)

nbdims = ndims(lutValues);

if nbdims == 1
    lutMin = min(lutValues);
    lutMax = max (lutValues);
elseif nbdims == 2
    lutMin = min(min(lutValues));
    lutMax = max(max (lutValues));
else  % No support for 3 dimensions or higher
    lutMin = 'min';
    lutMax = 'max';
end

end
% LocalWords:  pststubs tl polyspace pslink basetypes lut pst Fct func lk DFcn
% LocalWords:  INDEXSEARCH nd FNC IG dsdd
