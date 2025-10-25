classdef (Sealed, Hidden) MatKVReadBuffer < handle
%MATKVREADBUFFER A key-value buffer for by loading an entire MAT-file.
%
% See also - matlab.io.datastore.KeyValueDatastore

%   Copyright 2014-2018 The MathWorks, Inc.
    properties (SetAccess = private)
        Source;
        Key;
        Value;
        SchemaVersion;
    end

    properties (Access=public, Hidden, Constant)
        % To identify that MAT-files are created by 15a or later for loading the whole file.
        MAT_FILE_SCHEMA_VERSION = 1.0;
    end

    methods
        function bfr = MatKVReadBuffer(split)
            import matlab.io.datastore.internal.MatKVReadBuffer
            import matlab.io.datastore.internal.filesys.vfsfun
            
            bfr.Source = split.Filename;
            warning('off','MATLAB:load:variableNotFound');
            if matlab.io.datastore.internal.isIRI(split.Filename)
                S = vfsfun(@(f) load(f, 'Key', 'Value', 'SchemaVersion'), split);
            else
                S = load(split.Filename, 'Key', 'Value', 'SchemaVersion');
            end
            warning('on','MATLAB:load:variableNotFound');
            bfr.Key = S.Key;
            bfr.Value = S.Value;
            bfr.SchemaVersion = S.SchemaVersion;
            if S.SchemaVersion ~= MatKVReadBuffer.MAT_FILE_SCHEMA_VERSION
                error(message('MATLAB:datastoreio:keyvaluedatastore:unsupportedFiles', split.Filename));
            end
        end
    end
end
