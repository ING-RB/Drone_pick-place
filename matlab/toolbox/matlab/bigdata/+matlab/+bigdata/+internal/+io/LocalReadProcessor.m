%LocalReadProcessor
% Helper class that wraps a datastore-like reader from temporary storage
% as a Data Processor.
%
% This makes the assumption that the reader will always contain at least
% one chunk.
%

%   Copyright 2015-2022 The MathWorks, Inc.

classdef LocalReadProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired = false(0,1);
    end
    
    properties (GetAccess = private, SetAccess = immutable)
        % The underlying reader implementation.
        Reader;
    end
    
    methods
        % The main constructor.
        function obj = LocalReadProcessor(reader, numVariables)
            obj.NumOutputs = numVariables;
            obj.Reader = reader;
        end
    end
    
    % Methods overridden in the DataProcessor interface.
    methods
        function data = process(obj, ~)
            import matlab.bigdata.internal.UnknownEmptyArray
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            
            % No chunks to read indicates no partitions sent anything to
            % this partition. We allow this because of tall/vertcat, the
            % communication can be ignored for certain output partitions.
            if ~hasdata(obj.Reader)
                data = repmat({UnknownEmptyArray.build()}, 1, obj.NumOutputs);
                obj.IsFinished = true;
                return;
            end
            
            try
                data = read(obj.Reader);
            catch err
                matlab.bigdata.internal.io.throwTempStorageError(err);
            end
            obj.IsFinished = ~hasdata(obj.Reader);
        end
    end
end
