classdef NumericArrayDataModel < internal.matlab.variableeditor.ArrayDataModel
    %NUMERICARRAYDATAMODEL 
    %   Numeric Array Data Model

    % Copyright 2013-2023 The MathWorks, Inc.

    % Type
    properties (Constant)
        NumericTypes = { 'double', 'uint8', 'uint16', 'uint32', 'uint64', ...
            'int8', 'int16', 'int32', 'int64', 'single', 'half'};
    end
    
    properties (SetObservable=false, SetAccess='private', GetAccess='public', Dependent=false, Hidden=false)
        % Type Property
        Type = 'NumericArray';
        
        % Class Type Property
        ClassType = internal.matlab.variableeditor.NumericArrayDataModel.NumericTypes;
    end %properties

    properties(Hidden)
        DataI;
        SliceI (1,:) string = [":", ":"];
    end

    properties (Dependent=true)
        Slice
    end
    methods
        function s = get.Slice(this)
            nd = ndims(this.DataI);
            if length(this.SliceI) ~= nd
                this.SliceI = [":", ":", repmat("1", 1, nd-2)];
            end
            s = this.SliceI;
        end

        function set.Slice(this, s)
            arguments
                this
                s (1,:) string
            end
            nd = ndims(this.DataI);
            oldSlice = this.SliceI;
            if length(s) ~= nd
                s = [s, repmat("1", 1, nd-length(s))];
            end

            % Make sure there are exactly 2 
            fullSliceLocations = find(s == ":");
            numSliceLocations = find(s ~= ":");
            if length(fullSliceLocations) == 2
                s(fullSliceLocations(3:end)) = "1";
            else
                error(message('MATLAB:codetools:variableeditor:NDArrayErrorMustHave2Colons'));
            end
            maxSizes = size(this.DataI);
            maxSizes = maxSizes(numSliceLocations);
            numSlices = double(s(numSliceLocations));
            for i=1:length(numSlices)
                numSlices(i) = min(max(1,numSlices(i)), maxSizes(i));
            end

            s(numSliceLocations) = numSlices;
            prevData = this.Data;
            this.SliceI = s;
            eventData = internal.matlab.variableeditor.NumericDataChangeEventData;
            eventData.StartRow = 1;
            eventData.EndRow = size(prevData,1);
            eventData.StartColumn = 1;
            eventData.EndColumn = size(prevData,2);
            eventData.SizeChanged = true;
            eventData.Slice = s;
            eventData.UserAction = 'SliceChange';
            this.notify('DataChange', eventData);
        end
    end

    % Data
    properties (SetObservable=true, SetAccess='public', GetAccess='public', Dependent=true, Hidden=false)
        % Data Property
        Data
    end %properties
    methods
        function storedValue = get.Data(this)
            nd = ndims(this.DataI);
            if nd == 2
                storedValue = this.DataI;
            else
                % When not indexing the first two dimensions you'll
                % get a mxnx1 and need squeeze to get rid of the x1
                % dimenion
                cmd = sprintf("squeeze(this.DataI(" + strjoin(this.Slice,",") + "))");
                storedValue = eval(cmd);
            end
        end
        
        % Sets the data
        % Data must be a two dimensional numeric array
        function set.Data(this, newValue)
            if ~isnumeric(newValue)
                error(message('MATLAB:codetools:variableeditor:NotAnMxNNumericArray'));
            end
            reallyDoCopy = ~isequal(this.Data, newValue);
            if reallyDoCopy
                this.DataI = newValue;
            end
        end
    end

    methods(Access='protected')
        % Returns the left hand side of an assigntment operation
        function lhs=getLHS(this,idx)
            nd = ndims(this.DataI);
            if nd == 2
                lhs = sprintf('(%s)',idx);
            else
                separateIdxs = strsplit(idx,",");
                slice = this.Slice;
                replaceIdxs = find(slice == ":");
                slice(replaceIdxs(1)) = separateIdxs(1);
                slice(replaceIdxs(2)) = separateIdxs(2);
                lhs = sprintf('(%s)',strjoin(slice, ","));
            end
        end
    end
end

