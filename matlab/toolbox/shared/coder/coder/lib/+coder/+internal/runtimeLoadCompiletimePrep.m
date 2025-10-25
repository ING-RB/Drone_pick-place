function [info, fname] = runtimeLoadCompiletimePrep(buildCTX, varargin)
%MATLAB Code Generation Private Function

%   Copyright 2020 The MathWorks, Inc.

    fname = getDatFileName(varargin{1}, buildCTX);
    %validate these varargin?
    dat = load(varargin{:});
    includeTypeInfo = false;
    makeAUsefulFile = true;
    datType = coder.typeof(dat);
    coder.internal.prepForLoad(fname, dat, includeTypeInfo, datType, makeAUsefulFile);
    info = coder.internal.coderTypeToLoadInfo(datType, 'SkipWarnings');


end

function fName = getDatFileName(matFileName, buildCtx)

[~,baseName,~] = fileparts(matFileName);
numCollisions = 0;
filesHere = dir(buildCtx.BuildDir);
for i=1:numel(filesHere)
    if ~isempty(strfind(filesHere(i).name, baseName))
        numCollisions = numCollisions+1;
    end
end
if numCollisions > 0
    fName = sprintf('%s%d.coderdata', baseName, numCollisions);
else
    fName = sprintf('%s.coderdata', baseName);
end

fName = fullfile(buildCtx.BuildDir, fName);
end
