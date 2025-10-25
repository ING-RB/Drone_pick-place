classdef Label< slproject.LabelDefinition
%Label  A Label attached to a file
%    The label property provides information about a label that has
%    been attached to a file in the current project. You can query the
%    properties of the label, and change the data associated with the
%    label.

 
%   Copyright 2012-2021 The MathWorks, Inc.

    methods
    end
    properties
        %The data attached to the file label. It is of type obj.DataType.
        Data;

        %The type of the data stored in this file label.
        DataType;

        %The file that this label is attached to.
        File;

    end
end
