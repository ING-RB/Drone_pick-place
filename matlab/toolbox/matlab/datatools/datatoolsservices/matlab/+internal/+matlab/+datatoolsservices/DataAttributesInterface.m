classdef DataAttributesInterface < handle & dynamicprops
    %DATAATTRIBUTESINTERFACE1 Abstract class that outlines some default
    % data attributes
    
    % Copyright 2019-2020 The MathWorks, Inc.

    properties
        isScalar = false;
        isSparse = false;
        isND = false;
        isEmpty = false;
    end

    methods
        function attributes = getAttrAsStruct(this)
            warningState = warning('query', ...
                'MATLAB:structOnObject');
            warning('off','MATLAB:structOnObject');
            attributes = struct(this);
            warning(warningState.state, 'MATLAB:structOnObject');
        end
    end

    methods         
        DataAttributes = getDataAttributes(this, varargin);
    end
end
