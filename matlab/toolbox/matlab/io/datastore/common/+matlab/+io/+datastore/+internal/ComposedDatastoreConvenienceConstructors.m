classdef (Abstract) ComposedDatastoreConvenienceConstructors < handle
%ComposedDatastoreConvenienceConstructors   Provides the experimental "repeat",
%   "nest", and "overrideSchema" methods to subclasses.

%   Copyright 2021-2022 The MathWorks, Inc.

    methods (Hidden)
        function rptds = repeat(varargin)
            import matlab.io.datastore.internal.RepeatedDatastore

            rptds = RepeatedDatastore(varargin{:});
        end

        function blkds = blockedRepeat(varargin)
            import matlab.io.datastore.internal.BlockedRepeatedDatastore

            blkds = BlockedRepeatedDatastore(varargin{:});
        end

        function nds = nest(varargin)
            import matlab.io.datastore.internal.NestedDatastore

            nds = NestedDatastore(varargin{:});
        end

        function schds = overrideSchema(varargin)
            import matlab.io.datastore.internal.SchemaDatastore

            schds = SchemaDatastore(varargin{:});
        end

        function pgds = paginate(varargin)
            import matlab.io.datastore.internal.PaginatedDatastore

            pgds = PaginatedDatastore(varargin{:});
        end

        function saerd = skipAheadEmptyRead(varargin)
            import matlab.io.datastore.internal.SkipAheadEmptyReadDatastore

            saerd = SkipAheadEmptyReadDatastore(varargin{:});
        end
    end
end
