classdef DefaultDataAttributesProvider < internal.matlab.datatoolsservices.DataAttributesInterface
    %DEFAULTDATAATTRIBUTESPROVIDER This class is used to provide the
    % Data Attributes based on inspection of data and size of a variable.

    % Copyright 2019 The MathWorks, Inc.
    % NOTE: The getDataAttributes method will solely be responsible for
    % providing enough information to startup the right kind of
    % DataModel/ViewModel for a datatype.
    methods
        function DataAttributes = getDataAttributes(this, variableData, variableSize)
            DataAttributes = this.getAttrAsStruct();                        
            % If custom obj is of type DataAttributesInterface, copy over
            % additional Data Attributes.
            if (isa(variableData, 'internal.matlab.datatoolsservices.DataAttributesInterface'))
                attributes = variableData.getDataAttributes();
                fields = fieldnames(attributes);
                for i=1:numel(fields)
                    DataAttributes.(fields{i}) = attributes.(fields{i});
                end
            end
        end
    end
    
    methods(Static)
        function obj = getInstance(varargin)
            mlock; % Keep persistent variables until MATLAB exits
            persistent dataAttributesProviderInstance;
            if isempty(dataAttributesProviderInstance)
                dataAttributesProviderInstance = internal.matlab.datatoolsservices.DefaultDataAttributesProvider();
            end
            obj = dataAttributesProviderInstance;
        end
    end

    methods (Access=private)
        function this = DefaultDataAttributesProvider()
            this@internal.matlab.datatoolsservices.DataAttributesInterface();
        end
    end
end

