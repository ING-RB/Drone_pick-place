function lInfo = coderTypeToLoadInfo(type, warn)
%MATLAB Code Generation Private Function

%   Copyright 2021-2022 The MathWorks, Inc.

if isa(type, 'coder.Constant')
    if strcmpi(warn, 'IssueWarnings')
        %only warn when we write the file that has the offending value, not
        %every time we compile using this type header.
        warning(message('Coder:toolbox:CoderWriteDiscardingConstant'));
    end
    type = coder.typeof(type.Value);
end

if isa(type, 'matlab.coder.type.CategoricalType')
    type = type.getCoderType;
end

if isa(type, 'coder.PrimitiveType')
    coder.internal.assert(~strcmp(type.ClassName, 'half'), 'Coder:toolbox:CoderReadBadTypeHeader', type.ClassName);
    if type.Sparse
        lInfo = coder.internal.sparseLoaderType(...
            type.SizeVector,...
            type.ClassName,...
            type.Complex,...
            type.VariableDims);
    elseif strcmp(type.ClassName, 'logical')
        lInfo = coder.internal.encodedLoaderType(...
            type.SizeVector,...
            'uint8',...
            'logical',...
            type.VariableDims);
    else
        lInfo = coder.internal.loaderType(...
            type.SizeVector,...
            type.ClassName,...
            type.Complex,...
            type.VariableDims);
    end
elseif isa(type, 'coder.StructType')
    if  strcmpi(warn, 'IssueWarnings') && ~isNormalStruct(type)
        warning(message('Coder:toolbox:CoderWriteDiscardingStructInfo'));
    end
    lInfo = convertStructType(type, 'struct', warn);
elseif isa(type, 'coder.CellType')
    if type.isHomogeneous
        if isempty(type.Cells)
            lInfo = coder.internal.containerLoaderType(type.SizeVector, coder.internal.coderTypeToLoadInfo(coder.typeof([]), warn), 'cell', true, type.VariableDims, 'cell');
        else
            type = type.makeHomogeneous;
            lInfo = coder.internal.containerLoaderType(type.SizeVector, coder.internal.coderTypeToLoadInfo(type.Cells{1}, warn), 'cell', true, type.VariableDims, 'cell');
        end
    else
        subTypes = struct();
        typeCells = type.Cells;
        for i = 1:prod(type.SizeVector)
            name = coder.internal.idxToStructName(i);
            subTypes.(name) = coder.internal.coderTypeToLoadInfo(typeCells{i}, warn);
        end
        lInfo = coder.internal.containerLoaderType(type.SizeVector, subTypes, 'cell', false, type.VariableDims, 'cell');
    end
elseif isa(type, 'coder.ClassType') && strcmp(type.ClassName, 'categorical')
    %categorical is written to the file as a struct, so we should treat it
    %like one

    %make the coder type for the data actually in the file
    actual = coder.typeof(coder.internal.categoricalToStruct(categorical(1)));
    valueType = type.Properties.codes;
    actual.Fields.values = coder.typeof(uint32(1), valueType.SizeVector, valueType.VariableDims);
    actual.Fields.categories = type.Properties.categoryNames;

    % make the type using the same code we use for structs
    lInfo = convertStructType(actual, 'categorical', warn);
elseif isa(type, 'coder.ClassType') && strcmp(type.ClassName, 'string')
    lInfo = coder.internal.encodedLoaderType(...
        type.Properties.Value.SizeVector,...
        'char',...
        'string',...
        type.Properties.Value.VariableDims);
elseif isa(type, 'coder.EnumType')
    mc = meta.class.fromName(type.ClassName);
    superClasses = {mc.SuperclassList.Name};
    baseClass = superClasses{find( contains(superClasses, 'int'), 1)}; %FIXME: make this more robust to failure
    lInfo = coder.internal.encodedLoaderType(...
        type.SizeVector,...
        baseClass,...
        type.ClassName,...
        type.VariableDims);
else
    %this is either a corrupted file or a bug; we should be catching
    %invalid types at write-time
    coder.internal.assert(false, 'Coder:toolbox:CoderReadBadTypeHeader', class(type));
end

end


function lInfo = convertStructType(type, typeName, warn)
    fields = fieldnames(type.Fields);
    c = cell(1, 2*numel(fields));
    for i = 1:numel(fields)
        fname = fields{i};
        c{i*2 - 1} = fname;
        c{i*2} = coder.internal.coderTypeToLoadInfo(type.Fields.(fname), warn);
    end
    subType = struct(c{:});
    lInfo = coder.internal.containerLoaderType(type.SizeVector, subType, typeName, true, type.VariableDims, 'struct');
end

function normal = isNormalStruct(structType)
normal = isempty(structType.TypeName) &&...
    isempty(structType.HeaderFile) &&...
    ~structType.Extern && ...
    structType.Alignment == -1;
end
