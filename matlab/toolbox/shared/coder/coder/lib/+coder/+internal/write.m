function write(datFileName, dataToSave, optionalArgs) 
%CODER.WRITE Creates .coderdata file that can be read with coder.read.
% This function is NOT supported for code generation.
%
% CODER.WRITE(filename, data) writes data (and the type of data) into filename.
% filename can include a path if desired.
%
% CODER.WRITE(filename, data, ___) allows the specification of name-value pairs
% (described below)
%
% If you plan to read multiple .coderdata files with different sizes (but
% the same datatypes), you can provide a coder.Type which matches all the
% expected data, and will be stored in the header of this file.
% 
% Required Arguments:
% filename - the name of the .coderdata file you want to write
% dataToSave - the data which you want to store in the .coderdata file.
%              This is what will be returned by coder.read
%
% Optional Name-Value Pairs
% 'TypeHeader' - provide a coder.Type which matches all of the data that
%                you expect to read. By default, this uses
%                coder.typeof(dataToSave). If you want to recover this type
%                after you have written a file, use coder.readTypeHeader.
% 'TypeHeaderOnly' - Control if data and the type header or only the type
%                    header should be written to the .coderdata file. By
%                    default this is flase (it will write the data you
%                    provide)
% 'Verbose' - if true (default), prints a notification that a file was
%             written. Otherwise, this message is omitted.
%
%EXAMPLES:
%
% coder.write('myFile', {[1,2,3], 'abc'}) %creates myFile.coderdata
% myData = coder.read('myFile') % myData will be {[1,2,3], 'abc'}
%
% coder.write('myFileVarsized', 'example text', 'TypeHeader', coder.typeof(' ', [1,Inf]));
% coder.write('shorterText', 'ex txt');
% coder.write('longerText', 'this is example text');
% filename = 'shorterText'; %this need not be constant
% coder.read(filename, 'TypeHeaderFrom', 'myFileVarsized.coderdata')
%
% See also: CODER.READ, CODER.READTYPEHEADER

%   Copyright 2020-2022 The MathWorks, Inc.


arguments
    datFileName (1,:) char
    dataToSave
    optionalArgs.TypeHeader (1,1) {coder.internal.mustBeTypeish}
    optionalArgs.TypeHeaderOnly (1,1) logical = false
    optionalArgs.Verbose (1,1) logical = true
end

[~, name, ext] = fileparts(datFileName);
coder.internal.assert(strcmp(ext, '.coderdata') || strlength(ext)==0, ...
    'Coder:toolbox:CoderWriteExtension');
coder.internal.assert(~isempty(name), 'Coder:toolbox:CoderWriteNoName');
if strlength(ext) == 0
    datFileName = strcat(datFileName, '.coderdata');
end
if isfield(optionalArgs, "TypeHeader")
    if ~optionalArgs.TypeHeaderOnly
        %would be nice to get very spcific on the differences, but the
        %infrastructure doesn't exist and displaying it might be
        %complicated.
        coder.internal.assert(contains(optionalArgs.TypeHeader, dataToSave), 'Coder:toolbox:CoderWriteWrongHeader');
    end
else
    optionalArgs.TypeHeader = coder.typeof(dataToSave);
end
encodeType = true;
coder.internal.prepForLoad(datFileName, dataToSave, encodeType, optionalArgs.TypeHeader, ~optionalArgs.TypeHeaderOnly);
if optionalArgs.Verbose
    m = message('Coder:toolbox:CoderWriteNotify', datFileName);
    disp(m.string);
end

end
