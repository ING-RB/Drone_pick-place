function same = verifyMatFileHasntChanged(oldInfo)
%MATLAB Code Generation Private Function

%   Copyright 2020 The MathWorks, Inc.
if ~isempty(oldInfo)
    %FIXME: datenum updates upon loading a mat file, so this will very
    %often have false warnings
%     newInfo = dir(fullfile(oldInfo.folder, oldInfo.name));
%     same = oldInfo.datenum == newInfo.datenum;
%     if ~same
%         warning('mat file has changed, but data file has not. All data will be loaded from the data file, which will not reflect changes in the source mat file.')
%     end
end
same = true;

end