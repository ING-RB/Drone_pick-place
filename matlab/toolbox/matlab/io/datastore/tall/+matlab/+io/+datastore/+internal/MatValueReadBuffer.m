classdef (Sealed, Hidden) MatValueReadBuffer < handle
%MatValueReadBuffer A value buffer by loading an entire MAT-file.
%
% See also - matlab.io.datastore.TallDatastore

%   Copyright 2016-2018 The MathWorks, Inc.
    properties (SetAccess = private)
        Source;
        Value;
        SchemaVersion;
    end

    properties (Access=public, Hidden, Constant)
        % To identify that MAT-files are created by 16b or later for loading the whole file.
        MAT_FILE_SCHEMA_VERSION = 2.0;
    end

    methods
        function bfr = MatValueReadBuffer(split)
            % Constructor for the read buffer
            % Loads the MAT-file and checks for the Supported SchemaVersion.
            import matlab.io.datastore.internal.MatValueReadBuffer
            import matlab.io.datastore.internal.filesys.vfsfun
            
            bfr.Source = split.Filename;
            warning('off','MATLAB:load:variableNotFound');
            if matlab.io.datastore.internal.isIRI(split.Filename)
                S = vfsfun(@(f) load(f, 'Value', 'SchemaVersion'), split);
            else
                S = load(split.Filename, 'Value', 'SchemaVersion');
            end
            warning('on','MATLAB:load:variableNotFound');
            bfr.Value = S.Value;

            bfr.SchemaVersion = S.SchemaVersion;
            if S.SchemaVersion ~= MatValueReadBuffer.MAT_FILE_SCHEMA_VERSION
                error(message('MATLAB:datastoreio:talldatastore:unsupportedFiles', split.Filename));
            end
        end
    end
end
