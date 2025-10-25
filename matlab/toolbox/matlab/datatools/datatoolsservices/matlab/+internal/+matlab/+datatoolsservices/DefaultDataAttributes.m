classdef DefaultDataAttributes < internal.matlab.datatoolsservices.DataAttributesInterface
    %DEFAULTDATAATTRIBUTESPROVIDER This class is used to provide the
    % Data Attributes based on inspection of data and size of a variable.
    
    % Copyright 2020 The MathWorks, Inc.
    
    methods
        function obj = DefaultDataAttributes(variableData, variableSize)
            if (nargin < 2)
                if (nargin < 1)
                   error('MATLAB:InvalidData', 'Please provide valid Variable Data');                   
                end
                variableSize = size(variableData);
            end
            % For now, return if this a tall variable.
            if (istall(variableData))
                return;
            end            

            try
                if (issparse(variableData))
                    obj.isSparse = true;
                end
                if isscalar(variableData) || (length(variableSize) == 2 && variableSize(1) == 1 && variableSize(2) == 1)
                    obj.isScalar = true;
                end
                if (ndims(variableData) > 2)
                    obj.isND = true;
                end
            catch
                % Ignore any errors
            end
            isEmpty = isempty(variableData);
            
            if isa(isEmpty, 'logical') && isEmpty
                obj.isEmpty = true;
            end
        end     
    end
end

