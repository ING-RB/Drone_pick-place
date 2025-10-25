
function [out, errorHandler] = runtimeLoadImpl(fid,structEX, errorHandler)
%MATLAB Code Generation Private Method

%#codegen

%   Copyright 2020-2022 The MathWorks, Inc.
coder.internal.allowEnumInputs;
coder.internal.prefer_const(structEX);
coder.const(structEX);
[sk, errorHandler] = guardedFread(fid, 1, 'double', errorHandler, 1); %is it worth trying to use coder.ReadStatus.CouldNotRead here?
if errorHandler.noErrorsYet
    [v, count] = fscanf(fid, ' MATLAB .coderdata file version %d.%d ', [1,2]);
    errorHandler = errorHandler.assertOrAssignError(count==2, coder.ReadStatus.WrongHeader);
    errorHandler = errorHandler.assertOrAssignError(numel(v) > 0 && v(1)==1, coder.ReadStatus.WrongVersion);
end
if errorHandler.noErrorsYet
    errorHandler = errorHandler.assertOrAssignError(sk(1)>=0, coder.ReadStatus.TypeOnly);
    stat = fseek(fid, sk(1), 'bof');
    errorHandler = errorHandler.assertOrAssignError(stat==0, coder.ReadStatus.WrongHeader);
end
[out, errorHandler] = runtimeLoadRecurse(fid, structEX, errorHandler);


end



function [out, errorHandler] = runtimeLoadRecurse(fid,structEX, errorHandler)
coder.internal.allowEnumInputs;
coder.internal.prefer_const(structEX);
coder.const(structEX);
nargoutchk(2,2); %always update the error handler

if ~isstruct(structEX)
    if isa(structEX, 'coder.internal.encodedLoaderType')
        cName = structEX.baseClass;
    else
        cName = structEX.classname;
    end

    [numTypeName, errorHandler] = guardedFread(fid, 1, SIZE_PRECISION, errorHandler, 1);
    readSizeMatchesFile = true;
    if ~coder.target('MATLAB') && ~coder.internal.eml_option_eq('UseMalloc', 'VariableSizeArrays')
        readSizeMatchesFile = ~isempty(numTypeName) && numTypeName(1)==numel(cName);
        numRead = uint32(numel(cName));
    elseif isempty(numTypeName)
        numRead = uint32(0);
    else
        %if we have gotten lost, we don't need to put a bunch of garbage in
        %the error message, so limit how much we read and put only a little
        %garbage.
        numRead = min2(numTypeName(1), uint32(numel(cName)+16));
    end
    [typeName, errorHandler] = guardedFread(fid, numRead, 'char', errorHandler, uint32(numel(cName)+16));
    errorHandler = errorHandler.assertOrAssignError(readSizeMatchesFile && strcmpi(typeName.',cName),...
        coder.ReadStatus.WrongType, typeName.', cName);
end



if isstruct(structEX)
    fields = fieldnames(structEX);
    out = struct();
    coder.unroll()
    for i=1:numel(fields)
        curField = coder.const(structEX.(fields{i}));
        [out.(fields{i}), errorHandler] = runtimeLoadRecurse(fid,curField, errorHandler);
    end
else
    ndims = coder.internal.indexInt(numel(structEX.size));
    [uintNdims, errorHandler] = guardedFread(fid, 1, SIZE_PRECISION, errorHandler, 1);
    fileNdims = uintNdims(1);
    errorHandler = errorHandler.assertOrAssignError(fileNdims <= ndims, coder.ReadStatus.WrongNdims, fileNdims, ndims);
    if ~errorHandler.noErrorsYet()
        %things start to fall apart when we use a bogus ndims
        %in the case where we are off the rails, use a known good-enough
        %ndims to generate the default results
        fileNdims = cast(ndims, SIZE_PRECISION);
    end
    [rawSizeFromFile, errorHandler] = guardedFread(fid, fileNdims, SIZE_PRECISION, errorHandler, ndims);
    sizeFromFile = ones([1,ndims], SIZE_PRECISION);
    sizeFromFile(1:fileNdims) = rawSizeFromFile;
    numelFromFile = sizeToNumel(sizeFromFile);
    for i=1:ndims
        errorHandler = errorHandler.assertOrAssignError((structEX.varDims(i) && sizeFromFile(i) <= structEX.size(i)) ||...
            (~structEX.varDims(i) && sizeFromFile(i) == structEX.size(i)),...
            coder.ReadStatus.UnexpectedValue);
    end
    hasVarDims = coder.const(any(structEX.varDims));
    if hasVarDims
        sz = structEX.size; %we want to make sure that sz has fixed size
        if errorHandler.noErrorsYet
            coder.unroll()
            for i=1:ndims
                sz(i) = sizeFromFile(i);
                assert(sz(i)<= structEX.size(i));%hint
            end
            numTotal = numelFromFile;
        else
            sz(1:ndims) = 0;
            numTotal = 0;
        end
    else
        sz = uint32(structEX.size);
        numTotal = sizeToNumel(sz);
    end
    assert(numTotal <= sizeToNumel(structEX.size)); %<HINT>


    if isa(structEX, 'coder.internal.containerLoaderType')
        if strcmp(structEX.actual, 'cell')
            %these types are stored as a different type than the one we want in the
            %result
            szArray = num2cell(coder.internal.indexInt(sz));
            if hasVarDims
                coder.unroll()
                for i=1:numel(structEX.size)
                    if ~structEX.varDims(i)
                        szArray{i} = coder.internal.indexInt(structEX.size(i));
                    end
                end
            end
            out = coder.nullcopy(cell(szArray{:}));
            coder.unroll(~hasVarDims);
            for j = 1:numTotal
                if structEX.homogeneous
                    [out{j}, errorHandler] = runtimeLoadRecurse(fid, coder.const(structEX.subTypes), errorHandler);
                else
                    fName = coder.internal.idxToStructName(j);
                    [out{j}, errorHandler] = runtimeLoadRecurse(fid, coder.const(structEX.subTypes.(fName)), errorHandler);
                end
            end
            coder.unroll()
            for i=1:numel(structEX.size)
                assert(size(out,i) <= structEX.size(i));%hint
            end
        else
            if numTotal == 0
                [first, errorHandler] = runtimeLoadRecurse(fid, structEX.subTypes, errorHandler);
                tmp = repmat(first, sz);
            else
                [first, errorHandler] = runtimeLoadRecurse(fid, structEX.subTypes, errorHandler);
                szCell = num2cell(coder.internal.indexInt(sz));
                if hasVarDims
                    coder.unroll()
                    for i=1:numel(structEX.size)
                        if ~structEX.varDims(i)
                            szCell{i} = coder.internal.indexInt(structEX.size(i));
                        end
                    end
                end
                tmp = coder.nullcopy(repmat(first, szCell{:}));
                tmp(1) = first;
                for j=2:numTotal
                    [tmp(j), errorHandler] = runtimeLoadRecurse(fid, structEX.subTypes, errorHandler);
                end
            end
            coder.unroll()
            for i=1:numel(structEX.size)
                assert(size(tmp,i) <= structEX.size(i));%hint
            end
            if strcmp(structEX.actual, 'categorical')
                out = coder.internal.structToCategorical(tmp);
            else
                out = tmp;
            end
        end
    elseif isa(structEX, 'coder.internal.sparseLoaderType')
        [i, errorHandler] = runtimeLoadRecurse(fid, coder.const(structEX.iType), errorHandler);
        [j, errorHandler] = runtimeLoadRecurse(fid, coder.const(structEX.jType), errorHandler);
        [v, errorHandler] = runtimeLoadRecurse(fid, coder.const(structEX.vType), errorHandler);
        out = sparse(i,j,v,sz(1), sz(2));
    else
        if isa(structEX, 'coder.internal.encodedLoaderType')
            caster = str2func(structEX.baseClass);
            %fread only supports 2-d matrices, so we read everything as a
            %vector and then reshape
            [tmp, errorHandler] = guardedFread(fid, numTotal, structEX.classname, errorHandler, sizeToNumel(structEX.size));
            if strcmp(structEX.classname, 'char')
                outFlat = caster(char(tmp.'));
            else
                outFlat = caster(tmp);
            end
        else
            %TODO: skip filestar stuff
            [fileHasCmplxPart, errorHandler] = guardedFread(fid, 1, 'uint8', errorHandler, 1);
            if structEX.isComplex
                [outReal, errorHandler] = guardedFread(fid, numTotal, structEX.classname, errorHandler, sizeToNumel(structEX.size));
                if fileHasCmplxPart
                    [outImag, errorHandler] = guardedFread(fid, numTotal, structEX.classname, errorHandler, sizeToNumel(structEX.size));
                else
                    assert(numTotal <= sizeToNumel(structEX.size)); %<HINT>
                    outImag = zeros([numTotal, 1], structEX.classname);
                end
                outFlat = complex(outReal(:),outImag(:)); %flatten with indexing for empties
            else
                errorHandler = errorHandler.assertOrAssignError(fileHasCmplxPart(1)==0,...
                    coder.ReadStatus.UnexpectedComplex);
                [outFlat, errorHandler] = guardedFread(fid, numTotal, structEX.classname, errorHandler, sizeToNumel(structEX.size));
            end
        end
        if ~isstring(outFlat)
            tmpcell = num2cell(coder.internal.indexInt(sz));
            if hasVarDims
                coder.unroll()
                for i=1:numel(structEX.size)
                    if ~structEX.varDims(i)
                        tmpcell{i} = coder.internal.indexInt(structEX.size(i));
                    end
                end
            end
            out = coder.internal.matrixReshapeValExpr(outFlat, tmpcell{:});
            coder.unroll()
            for i=1:numel(structEX.size)
                assert(size(out,i) <= structEX.size(i));%hint
                if ~structEX.varDims(i)
                    assert(size(out,i) == structEX.size(i));%hint
                end
            end
        else
            out = outFlat;
        end
    end
end
end


function out = SIZE_PRECISION
coder.inline('always');
out = 'uint32';
end

function [out, errorHandler] = guardedFread(fid, num, class, errorHandler, upperBounds)
coder.inline('always')
coder.internal.prefer_const(class,upperBounds)
coder.const(upperBounds);
ubVector = [upperBounds,1];
if errorHandler.noErrorsYet
    if coder.target('MATLAB')
        [out, count] = fread(fid, num, [class '=>', class]);
    else
        [out, count] = coder.internal.coderFread(fid, num, [class '=>', class], ZERO, ubVector);
    end
    errorHandler = errorHandler.assertOrAssignError(count==num, coder.ReadStatus.ProblemReading);
    if count~=num
        out = defaultReadResults(class, num, upperBounds);
    end
else
    out = defaultReadResults(class, num, upperBounds);
end
assert(numel(out) <= upperBounds)%<HINT>
end

function out = defaultReadResults(class, num, upperBounds)
coder.internal.prefer_const(class,upperBounds)
coder.const(upperBounds);
assert(num<=upperBounds);%hint
if strcmp(class, 'char')
    out = blanks(num).';
else
    out = zeros([num, 1], class);
end
end

function y = min2(a,b)
coder.inline('always')
if a <= b
    y = a;
else
    y = b;
end
end

function z = ZERO
z = coder.internal.indexInt(0);
end

function nElements = sizeToNumel(sz)

if any(sz==0)
    %numel is always 0 if any size is 0, but prod produces NaN if there is
    %also an Inf
    nElements = 0;
else
    nElements = prod(sz);
end

end
