function write(obj, file)
%write  Write data to a figure file
%
%  write(obj, file) writes the current data in the FigFile object to the
%  specified file.
%  
%  write(obj) uses the filename that is currently set in the object's Path
%  property.

%  Copyright 2011-2022 The MathWorks, Inc.

if nargin>1
    obj.Path = file;
end

if obj.RequiredMatlabVersion<0
    error(message('MATLAB:graphics:internal:figfile:FigFile:UnsetRequiredMatlabVersion'));
end

switch(obj.FigFormat)
    case -1
        error(message('MATLAB:graphics:internal:figfile:FigFile:UnsetFigFormat'));
    case 2
        SaveVars = localGetV2Data(obj);
    case 3
        SaveVars = localGetV3Data(obj);
    otherwise
        error(message('MATLAB:graphics:internal:figfile:FigFile:InvalidFigFormat'));
end

SaveVars.meta_data = getMetaDataStruct;

save(obj.Path, obj.MatVersion, '-struct', 'SaveVars');

end

function SaveVars = localGetV2Data(obj)

SaveVars.(sprintf('hgS_%06d', obj.RequiredMatlabVersion)) = obj.Format2Data;
if obj.SaveObjects
    go = matlab.graphics.internal.figfile.GraphicsObjects;
    go.Format3Data = handle(obj.Format3Data);
    SaveVars.(sprintf('hgM_%06d', obj.RequiredMatlabVersion)).GraphicsObjects = go;
end

end

function SaveVars = localGetV3Data(obj)
% Save both V2 and V3 data

SaveVars.(sprintf('hgS_%06d', obj.RequiredMatlabVersion)) = obj.Format2Data;
go = matlab.graphics.internal.figfile.GraphicsObjects;
go.Format3Data = handle(obj.Format3Data);
SaveVars.(sprintf('hgM_%06d', obj.RequiredMatlabVersion)).GraphicsObjects = go;

end

function s = getMetaDataStruct()

m = matlabRelease;
matlab_release = struct(...
    'Release', m.Release, ...
    'Stage', m.Stage, ...
    'Update', m.Update, ...
    'Date', m.Date);
uuid = matlab.lang.internal.uuid;
s = struct('matlab_release', matlab_release, 'uuid', uuid);

end
