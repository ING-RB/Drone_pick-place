function tf = isequaln(ds, obj2, varargin)
%isequaln   isequaln is overridden for FoldersPropertyProvider
%   objects in order to avoid spurious results due to internal
%   changes from hidden properties like RecalculateFolders.

%   Copyright 2019-2021 The MathWorks, Inc.

    isFoldersPropertyProvider = @(x) isa(x, "matlab.io.datastore.FoldersPropertyProvider");

    % Verify that the object classes are correct and the properties are
    % equal
    if ~equal(ds, obj2, isFoldersPropertyProvider)
        tf = false;
        return
    end
    
    % Iterate over the rest of the input objects and check equality.
    for objIdx = 1:length(varargin)
        obj = varargin{objIdx};
        if ~equal(ds, obj, isFoldersPropertyProvider)
            tf = false;
            return
        end
    end

    tf = true;
end

function tf = equal(ds1, ds2, isObj)
    tf = true;

    % Verify that inputs are the correct object
    if ~isObj(ds1) || ~isObj(ds2)
        tf = false;
        return;
    end

    % Obtain access to all properties, including private and protected
    % properties
    warning("off", "MATLAB:structOnObject");
    ds1 = struct(ds1);
    ds2 = struct(ds2);
    warning("on", "MATLAB:structOnObject");

    % Verify the lists of properties are equal
    props1 = fieldnames(ds1);
    props2 = fieldnames(ds2);

    if ~isequaln(props1, props2)
        tf = false;
        return;
    end
    
    % Verify the properties of the two objects are equal
    for propIdx = 1:length(props1)
        propertyName = props1{propIdx};

        % Continue if the property should be excluded from equality
        % comparison
        if contains(ds1.ExcludeFromEqualComparison, propertyName)
            continue;
        end

        % Verify the value of the properties are equal
        if ~isequaln(ds1.(propertyName), ds2.(propertyName))
            tf = false;
            return;
        end
    end
end