classdef ParameterAlphaData < handle
%PARAMETERALPHADATA -  Data container for internals of the filter tuner.
%   The filter tuner uses a coordinate ascent algorithm that creates a
%   "fake gradient" called alpha for each parameter being optimized. If an
%   optimization step improves the cost, alpha is increased (we are going
%   in the steep direction). If an optimization step worsens the cost, the
%   alpha for that parameter is decreased (we took too big of a step).
%   
%   This data container holds the alphas for all parameters being tuned. A
%   "parameter being tuned" is a combination of a filter noise (a string)
%   and an index. Indices are quickly converted to logical arrays for the
%   purpose of preserving symmetry. For example, if we want to optimize
%   "Noise1" indices 1 and 2 where "Noise1" is a 3-by-3 matrix, it's easier
%   to use logical indices for modifying the parameter. To preserve the
%   symmetry of "Noise1" we also tune index 4 which is the reflection of
%   index 2 across the diagonal. So the logical array used to index Noise1
%   (stored in the property ArrayIndexer) would be : 
%
%   [true true false;
%   true false false;
%   false false false]  
%
%   which is true at index 1 and 2 and the reflection index 4.
%
%   Finally this data container allows the tuner to iterate over all the
%   parameters. The methods:
%      updateCurrentAlpha
%      stepCurrentParam
%      currentParamString
%      current
%   work on the current parameter-alpha-index. The tuner can advance to the
%   next parameter-alpha-index trio for the next iteration with the 
%       next() 
%   method.
%

%   Copyright 2021 The MathWorks, Inc.      

    properties
        % Parameters array of strings of noise parameters to tune
        Parameters 
        % Indices linear indices each Parameter to tune. -1 indicates to
        % tune the entire array.
        Indices

        % Alpha  a "fake gradient" step side for coordinate ascent
        Alpha
        
        % CurrentItem linear index of which Parameter we are tuning
        CurrentItem
        % ArrayIndexer - cell array of logical arrays used to index the
        % filter's Parameter(CurrentItem)
        ArrayIndexer
        % NumParameters number of parameters being tuned. This is the
        % length of the Parameters, Indices, Alpha, and ArrayIndexer
        % properties.
        NumParameters
    end


    methods
        function initialize(obj, tunableParameters, filterparams)
            % Initialize the data container. Populate all properties except Alpha
            tph = fusion.internal.tuner.TunableParameterHandler;
            [p, i, n] = tph.expand(tunableParameters);
            obj.Parameters = p;
            obj.Indices = i;
            obj.CurrentItem = 1;
            obj.NumParameters = n;
            initializeParameterIndexers(obj, filterparams)
            uniquify(obj);
        end
        
        function initializeAlpha(obj, ainit)
            % Initialize Alphas for each parameter being tuned
            obj.Alpha = repmat(ainit, 1, obj.NumParameters);
        end

        function [fpPos, fpNeg] = stepCurrentParam(obj, filterparams)
            % Replicate the input filterparams structure into two copies, one with the current
            % parameter being tuned increased by alpha, and one with the same parameter decreased by
            % alpha.
            fpPos = filterparams;
            fpNeg = filterparams;
            [p,~,a] = current(obj);
            currParam = filterparams.(p);
            cpPos = currParam;
            cpNeg = currParam;

            idx = obj.ArrayIndexer{obj.CurrentItem};
            cpPos(idx) = cpPos(idx) .* (1 + a);
            tmpneg = cpNeg(idx) .* (1 - a);
            if any(tmpneg <= 0)
                tmpneg = cpNeg(idx); % Don't decrease below zero
            end
            cpNeg(idx) = tmpneg;

            fpPos.(p) = cpPos;
            fpNeg.(p) = cpNeg;

        end
        function updateCurrentAlpha(obj, stepSize)
            % Update alpha for the current parameter based on stepSize.
            idx = obj.CurrentItem;
            ap = obj.Alpha(idx);
            ap = ap * stepSize;
            obj.Alpha(idx) = ap;
        end
        function next(obj)
            % Advance to the next parameter to tune
            if (obj.CurrentItem == obj.NumParameters)
                obj.CurrentItem = 1;
            else
                obj.CurrentItem = obj.CurrentItem  +1;
            end
        end

        function s = paramStrings(obj)
            % Return an array of strings for all parameters being tuned.
            % Parameters indices maybe returned as foo(3), for example.
            s = strings(obj.NumParameters,1);
            for ii=1:numel(s)
                s(ii) = printableParam(obj, ii); 
            end
        end

        function s = currentParamString(obj)
            % Return a string for the current parameter being tuned, including index.
            s = printableParam(obj, obj.CurrentItem);
        end

        function lg = makeAlphaLog(obj)
            % Create a log entry for the tuner of the current alphas.
            lg = struct;
            for ii=1:obj.NumParameters
                param = obj.Parameters(ii);
                if ~isfield(lg, param)
                    lg.(param) = obj.ArrayIndexer{ii} .* obj.Alpha(ii);            
                else
                    fld = lg.(param);
                    fld = fld + obj.ArrayIndexer{ii} .* obj.Alpha(ii);            
                    lg.(param) = fld;
                end
            end
        end

    end % methods
    
    methods (Access = protected) 
        function [p, i, a] = current(obj)
            % Extract the current parameter, index and alpha being used for tuning.
            idx = obj.CurrentItem;
            p = obj.Parameters(idx);
            i = obj.Indices(idx);
            a = obj.Alpha(idx);
        end

        function initializeParameterIndexers(obj, filterparams)
            % Build a cell array of logical array indexers. Each element of
            % the cell array is a logical array which can index into the
            % a property of filterparams corresponding to the matched index
            % in the Parameters property.
            % 
            % For example if 
            % filterparams = struct('foo', [1 2 3], ...
            %   'bar', magic(3), 'ba',1);
            %  And Parameters is 
            %  ["foo", "foo", "bar", "ba"]
            %  And  indices is 
            %  {1, 2, -1, -1}
            %  Then ArrayIndexer is
            %  { [true false false], ...
            %    [false true false], ...
            %    true(3), ...
            %    true}

            obj.ArrayIndexer = cell(1, obj.NumParameters);
            % Walk over parameters and indices
            for ii = 1:obj.NumParameters
                currp = obj.Parameters(ii); % index into a string array
                curridx = obj.Indices(ii); % index to tune 
                fp = filterparams.(currp); % filtparams value for currp
               
                % Handle curridx == -1 which means "whole array"
                if curridx == -1
                    idx = 1:numel(fp);
                else
                    idx = curridx; 
                end

                % Build logical array indexer
                logicalArrayIndexer = false(size(fp));
                if isscalar(fp) 
                    % Tune the whole array 
                    logicalArrayIndexer(:) = true;
                elseif isvector(fp)
                    % Just tune the indices in idx.
                    logicalArrayIndexer(idx) = true;
                else % matrix
                    % Keep symmetric
                    % find matching symmetric indices
                    logicalArrayIndexer(idx) = true;
                    logicalArrayIndexer = logicalArrayIndexer | logicalArrayIndexer.' ; % make symmetric
                end
                obj.ArrayIndexer{ii} = logicalArrayIndexer;
            end
        end
        
        function uniquify(obj)
            % Avoid the case of someone specifying both upper and lower
            % triangular indices and then having the prop tuned twice as
            % often. 
            
            % Call before initializeAlpha
            currIdx = 1;
            N = numel(obj.Parameters);
            toDelete = false(1,N);
            
            while(currIdx < N )
                currParam = obj.Parameters(currIdx);
                currIndexer = obj.ArrayIndexer{currIdx};
                for ii=(currIdx+1):N
                    % If equal, mark for deletion
                    d = isequal(currParam, obj.Parameters(ii)) && ...
                        isequal(currIndexer, obj.ArrayIndexer{ii});
                    toDelete(ii) = toDelete(ii) | d;  % preserve trues
                end
                currIdx = currIdx + 1;
            end
            
            % Delete redundant entries
            obj.Parameters(toDelete) = [];
            obj.Indices(toDelete) = [];
            obj.ArrayIndexer(toDelete) = [];
            obj.NumParameters = numel(obj.Parameters);
        end

        function s = printableParam(obj, n)
            % Return the nth parameter as a printable string
            idx = obj.Indices(n);
            param = obj.Parameters(n);
            if idx == -1
                s = string(param);
            else
                s = string(param) + "(" + string(idx) + ")";
            end
        end
     
    end
end % classdef
