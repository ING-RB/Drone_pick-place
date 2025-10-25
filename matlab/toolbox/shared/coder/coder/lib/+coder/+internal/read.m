function [out, errID] = read(filename, token, typeHeaderFilename)
% Reads from .coderdata file and returns its data
%
% out = coder.read(filename) reads from filename and returns the data. For
% code generation, filename must be a constant
%
% out = coder.read(filename 'TypeHeaderFrom', typeHeaderFilename), requires
% that typeHeaderFilename is the constant name of a .coderdata file. This
% reads the contents of the file specied by filename and returns out which
% matches the type specified in the TypeHeader of typeHeaderFilename. If
% the data in filename is not of the type specified in typeHeaderFilename,
% this may error or return unexpected results.
%
% [out, errID] = coder.read(...) supresses all errors during reading. errID
% is a coder.RunTimeLoadErrorCode object. If any errors are encountered,
% read returns them in errID. If no errors are encountered, errID is
% assigned 1. Use this option to test for targets when run-time errors are
% disabled. This option is a good way to test for targets where runtime
% errors are disabled.
%
% Examples:
% % Read from a .coderdata file with a known name:
% myData = coder.read('myData.coderdata')
%
% % Read a 3x3 matrix from variable 'filename' (which might be specified at runtime)
% coder.write('exampleFile.coderdata', magic(3));
% A = coder.read(filename, 'TypeHeaderFrom', 'exampleFile.coderdata');
%

%#codegen

%   Copyright 2022 The MathWorks, Inc.


coder.internal.prefer_const(filename);
coder.internal.assert((ischar(filename)&&isrow(filename)) || isstring(filename), 'Coder:toolbox:CoderReadFname');
coder.internal.assert(strcmp(coder.internal.getEndianness(), 'LittleEndian'),...
    'Coder:toolbox:CoderReadBigEndian');

if nargin > 1
    s = coder.internal.nvparse({'TypeHeaderFrom'}, token, typeHeaderFilename);
    parsedTF = s.TypeHeaderFrom;
    coder.internal.assert(~isempty(parsedTF) && ...
        (ischar(parsedTF) || isstring(parsedTF)) &&...
        coder.internal.isConst(parsedTF), 'Coder:toolbox:CoderReadTypeHeader');
    sInfo = coder.const(@feval, 'coder.internal.getMetadataFromCoderdata', char(parsedTF));

else
    coder.internal.assert(coder.internal.isConst(filename),'Coder:toolbox:CoderReadNotConst');
    coder.const(filename);
    sInfo = coder.const(@feval, 'coder.internal.getMetadataFromCoderdata', char(filename));
end
fid = fopen(filename); %should this be moved into impl?
if fid == -1
    fid = fopen([char(filename), '.coderdata']);
end
fileCloser = onCleanup(@()(safeFclose(fid)));
errorHandler = coder.internal.RuntimeLoadErrorHandler(nargout~=2);
if numel(filename) < 4
    matCheck = blanks(4);
else
   fnameChar = char(filename);
   matCheck = fnameChar(end-3:end);
end

errorHandler = errorHandler.assertOrAssignError(~strcmp(matCheck, '.mat'), coder.ReadStatus.MATFile, filename);
errorHandler = errorHandler.assertOrAssignError(fid~=-1, coder.ReadStatus.CouldNotOpen, filename);
[out, errorHandler] = coder.internal.runtimeLoadImpl(fid, sInfo, errorHandler);
errID = errorHandler.CurrentError;
end

function safeFclose(fid)
coder.inline('always')
if fid ~=-1
    fclose(fid);
end
end

