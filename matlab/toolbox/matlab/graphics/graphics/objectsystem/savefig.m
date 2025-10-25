function savefig(varargin)
%savefig Save figure and contents to FIG-file

%  Copyright 2011-2024 The MathWorks, Inc.

% Force all graphics update before save
drawnow;

narginchk(0, 3);

% Split the argument list and get default values if required
[h, filename, matFileVersion] = localGetHandleAndFile(varargin{:});

FF = matlab.graphics.internal.figfile.FigFile;
FF.Path = filename;
FF.MatVersion = matFileVersion;

if ~contains(filename,'.fig')
    error(message('MATLAB:savefig:FigFileExpected'));
end

% Setting InSaveFig to 'on' disables a warning that would otherwise be
% thrown when calling save on a Figure.
set(h,'InSaveFig','on');
c = onCleanup(@() set(h,'InSaveFig','off'));

FF.FigFormat =  3 ;
FF.Format3Data = hgsaveObject(h);
FF.RequiredMatlabVersion = 80000;
FF.SaveObjects = true;

% Save data to the file
FF.write();

end

function [h, filename, matFileVersion] = localGetHandleAndFile(varargin)
% Work out whether the user has specified a handle, a filename, or both.

import matlab.graphics.internal.isCharOrString

[hInput, fileInput,saveCompactOnly] = matlab.graphics.internal.figfile.processSaveArguments(varargin{:});

% Throw errors for invalid inputs
if ~hInput.Valid || ~localIsFigureArray(hInput.Value)
    E = MException(message('MATLAB:savefig:InvalidHandle'));
    E.throwAsCaller();
end

if ~fileInput.Valid
    if isCharRowVectorOrString(fileInput.Value) && startsWith(fileInput.Value, "-")
        E = MException(message('MATLAB:savefig:InvalidFilenameHyphen'));
        E.throwAsCaller();        
    else
        E = MException(message('MATLAB:savefig:InvalidFilename'));
        E.throwAsCaller();
    end
end

matFileVersion = '';
if ~saveCompactOnly.Valid
    if isValidMATFileVersion(saveCompactOnly.Value)
        matFileVersion = lower(saveCompactOnly.Value);
    else
        E = MException(message('MATLAB:savefig:InvalidThirdArgument'));
        E.throwAsCaller();
    end
elseif saveCompactOnly.Specified
    warning(message('MATLAB:savefig:Compact'));
end

h = hInput.Value;
filename = fileInput.Value;

end

function ret = localIsFigureArray(hndls)
% Test whether all of the handles in an array are figures
if isempty(hndls)
    % We need to test the class.
    ret = isa(hndls, 'double') || isa(hndls, 'matlab.ui.Figure');
else
    ret = all(isgraphics(hndls, 'figure'), 'all');
end

end

function valid = isValidMATFileVersion(flag)

import matlab.graphics.internal.isCharOrString

valid = isCharRowVectorOrString(flag) && ismember(lower(flag),["-v6","-v7","-v7.3"]);

end

function tf = isCharRowVectorOrString(flag)

import matlab.graphics.internal.isCharOrString
tf = isCharOrString(flag) && size(flag, 1) == 1;

end
