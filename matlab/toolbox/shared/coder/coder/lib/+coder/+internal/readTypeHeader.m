function cType = readTypeHeader(fname)
%Given a .coderdata filename, returns the coder.Type contained in the
%TypeHeader.


%   Copyright 2022 The MathWorks, Inc.
fname = char(fname);
fid = fopen(fname);
if fid == -1
    fid = fopen([fname, '.coderdata']);
end
%FIXME: now that this is a user-facing function, we should check that the
%input has the .coderdata extension and is a string. We might also need to
%obscure our use of getArrayFromByteStream (its a secret?)
coder.internal.assert(fid~=-1, 'Coder:toolbox:CoderReadCouldNotOpenTypeHeader', fname);
fileCloser = onCleanup(@()(fclose(fid)));
metaSize = abs(fread(fid, 1, 'double=>double'));
coder.internal.assert(metaSize>0, 'Coder:toolbox:CoderReadWrongHeader');
[v, count] = fscanf(fid, ' MATLAB .coderdata file version %d.%d ', [1,2]);
coder.internal.assert(count==2, 'Coder:toolbox:CoderReadWrongHeader');
coder.internal.assert(v(1)==1, 'Coder:toolbox:CoderReadWrongVersion');
serial = fread(fid, [metaSize,1], 'uint8=>uint8');
try
    cType = getArrayFromByteStream(serial);
catch
    coder.internal.assert(false, 'Coder:toolbox:CoderReadWrongHeader');
end

end