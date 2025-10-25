%DataProcessor
% The interface for all data processor classes.
%
% Each Data Processor processes chunks of input from zero or more input
% sources to generate chunks of output.
%
% One Data Processor will be instantiated for each execution partition
% associated with an ExecutionTask. It is the job of the data processor to
% receive all input for this partition/ExecutionTask combination and to
% generate the required output.
%

%   Copyright 2015-2019 The MathWorks, Inc.

classdef (Abstract) DataProcessor < handle & matlab.mixin.Copyable
    properties (Abstract, SetAccess = immutable)
        % The number of output variables to be emitted by this processor.
        % Each call to process(..) is guaranteed to return a
        % NumChunks x NumOutputs cell array of chunks.
        NumOutputs;
    end
    
    properties (Abstract, SetAccess = private)
        % A scalar logical that specifies if this data processor is
        % finished. A finished data processor has no more output or
        % side-effects.
        IsFinished (1,1) logical;
        
        % A vector of logicals that describe which inputs are required
        % before this can perform any further processing. Each logical
        % corresponds with the input of the same index.
        IsMoreInputRequired (1,:) logical;
    end
    
    methods (Abstract)
        %PROCESS Process the next chunk of data.
        %
        % This will be invoked repeatedly until IsFinished is true or the
        % output of this processor is no longer required. This will never
        % be invoked after IsFinished is true.
        %
        % Syntax:
        %  out = process(obj,isLastOfInput,varargin)
        %
        % Inputs:
        %  - isLastOfInputs is a logical scalar indicating whether there
        %  potentially exists any more input after this call to process.
        %  The process method is guaranteed to always be called at least
        %  once with isLastOfInputs set to true.
        %  - varargin is the actual input itself. Each of varargin will be
        %  a chunk from the respective input source.
        %
        % Outputs:
        %  - out is an chunk of output from this data processor. This is
        %  expected to be a NumChunks x NumOutputs cell array of chunks.
        %  If the processor is attached to any-to-any communication, the
        %  first column of data must contain scalar partition indices
        %  indicating which target partition to send the row of chunks.
        out = process(obj, isLastOfInputs, varargin);
    end
    
    methods
        function prog = progress(obj, inputProgress)
            %PROGRESS Return a value between 0 and 1 denoting the progress
            % through the current partition.
            %
            % Syntax:
            %  prog = progress(obj, inputProgress)
            %
            % Inputs:
            %  - inputProgress is a vector of double values between 0 and 1
            %  representing the progress of each predecessor of the
            %  processor.
            %
            % Outputs:
            %  - prog must be a double value between 0 and 1. If the data
            %  processor is finished, prog must be 1.
            
            % Default implementation is to assume the processor has
            % progressed as far as the input with least progress.
            if obj.IsFinished || isempty(inputProgress)
                prog = double(obj.IsFinished);
            else
                prog = min(inputProgress);
            end
        end
    end
end
