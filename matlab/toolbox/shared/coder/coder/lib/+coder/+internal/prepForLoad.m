function prepForLoad(fname, asStruct, encodeType, dataType, writeData)
%MATLAB Code Generation Private Function


%   Copyright 2020-2024 The MathWorks, Inc.


fid = fopen(fname, 'w');
fileCloser = onCleanup(@()(fclose(fid)));
writeHeader(fid, encodeType, dataType, writeData);
if writeData
    writeDat(fid, asStruct);
end

end

function writeHeader(fid, encodeType, T, writeData)
versionInfo = ' MATLAB .coderdata file version 1.0 ';
sizeOfDouble = 8;
baseSkip =  numel(versionInfo) + sizeOfDouble;
if encodeType
    [~] = coder.internal.coderTypeToLoadInfo(T, 'IssueWarnings'); %any errors or warnings that will be produced when whe inspect the type to read should instead be produced now
    serial = getByteStreamFromArray(T);
    skip = numel(serial) + baseSkip; %would be nice if this wasnt a double, but fseek takes doubles
    if ~writeData
        skip  = -skip;
    end
    fwrite(fid, skip, 'double');
    fprintf(fid, '%s', versionInfo);
    fwrite(fid, serial, 'uint8');
else
    if ~writeData
        baseSkip  = -baseSkip;
    end
    fwrite(fid, baseSkip, 'double');
    fprintf(fid, '%s', versionInfo);
end
end

function writeDat(fid, s)

if iscategorical(s)
    %categoricals are invisible - they should just look like structs
    %the theory is that this kind of header information only exists for
    %each frame of recursion in runtimeLoadImpl and there is only one frame
    %for the categorical and the struct that represent it.
    writeDat(fid, coder.internal.categoricalToStruct(s));
    return;
end

fwrite(fid,uint32(numel(class(s))), 'uint32');
fwrite(fid, class(s), 'char');%could include more here, or compress?
if ~isstring(s)
    fwrite(fid, numel(size(s)), 'uint32');
    fwrite(fid, size(s), 'uint32');
else
    %not good for string arrays, but lots of things will need to change
    %when we start supporting that (?)
    fwrite(fid, numel(size(char(s))), 'uint32');
    fwrite(fid, [1, size(char(s),2)], 'uint32');%fudge "" to be 1x0
end

if isstring(s) || ischar(s)
    c = char(s);
    badVals = unique(c(double(c) > 127));
    if ~isempty(badVals)
        error(message('Coder:toolbox:CoderWriteNonASCII', badVals, s));
    end
end

if isstruct(s)
    for i=1:numel(s)
        for f = fieldnames(s).'
            writeDat(fid, s(i).(f{1}));
        end
    end
elseif iscell(s)
    for i=1:numel(s)
        writeDat(fid, s{i});
    end
elseif issparse(s)
    [i,j,v] = find(s);
    %things would be a little faster in codegen if we used csc, but we
    %would need to caculate it here and undo that calculation if we were
    %reading from the file in MATLAB
    writeDat(fid, reshape(i, [], 1)); %want empties to be the right shape
    writeDat(fid, reshape(j, [], 1));
    writeDat(fid, reshape(v, [], 1));
elseif isenum(s) || islogical(s) || isstring(s)
    baseClass = getBaseClass(s);
    caster = str2func(baseClass);
    casted = caster(s);
    fwrite(fid, casted, baseClass);
else
    coder.internal.errorIf(isobject(s), 'Coder:toolbox:CoderWriteObject');
    if isreal(s)
        fwrite(fid, uint8(0), 'uint8'); %real flag
        fwrite(fid, s, class(s));
    else
        fwrite(fid, uint8(1), 'uint8'); %cmplx flag
        fwrite(fid,real(s),class(s));
        fwrite(fid,imag(s),class(s));
    end

end
end

function base = getBaseClass(eg)
if islogical(eg)
    base = 'uint8';
elseif isstring(eg)
    base = 'char';
else %enum
    base = coder.internal.getEnumBaseType(class(eg));
    if isempty(base)
        error(message('Coder:toolbox:CoderWriteEnum', class(eg)));
    end
end
end
