function [pa,ad] = construct(varargin)
%CONSTRUCT  Create a partitioned array and adaptor from the inputs
%
%   [PA,AD] = CONSTRUCT(DS) creates a partitioned array PA and adaptor AD
%   given a datastore input DS. If the input datastore is tabular then the
%   adaptor will be a table adaptor, otherwise it will be an array adaptor.
%
%   [PA,AD] = CONSTRUCT(X) creates a partitioned array PA and adaptor AD
%   from an in-memory array X.
%
%   [PA,AD] = CONSTRUCT(TX) creates a partitioned array PA and adaptor AD
%   from an existing tall array TX.
%
%   [PA,AD] = CONSTRUCT(PA,AD) creates a partitioned array PA and adaptor AD
%   from an existing partitioned array and adaptor pair.

%   Copyright 2016-2023 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
stack = createInvokeStack();
markerFrame = matlab.bigdata.internal.InternalStackFrame(stack); %#ok<NASGU>

try
    narginchk(0,2);
    
    % tall() returns a 0x0 tall double array
    if nargin==0
        [pa,ad] = iCreateFromLocal([]);
        return
    end
    
    % For two inputs, they must be a partitioned array, adaptor pair
    if nargin>1
        pa = varargin{1};
        ad = varargin{2};
        
        if ~isa(pa, 'matlab.bigdata.internal.PartitionedArray') ...
                || ~isa(ad, 'matlab.bigdata.internal.adaptors.AbstractAdaptor')
            % This will always issue the too many input arguments error. We
            % issue this error here because two input arguments is not a
            % public syntax.
            narginchk(0,1);
        end
        return;
    end
    
    % For the single input case we need to distinguish between:
    % 1. a datastore (tabular or otherwise)
    % 2. an existing tall array
    % 3. some in-memory data
    in = varargin{1};
    if matlab.io.datastore.internal.shim.isDatastore(in)
        if isRandomizedReadable(in)
            % Error if the datastore can perform non-deterministic reads.
            error(message('MATLAB:bigdata:array:UnsupportedDatastoreForTall'));
        end
        
        if matlab.io.datastore.internal.shim.isV2ApiDatastore(in)
            % Wrap custom datastores in a decorator that will insert the
            % right checks for the datastore contract.
            in = matlab.io.datastore.internal.FrameworkDatastore(in);
        end
        
        % Create from datastore. Tabular datastores and TallDatastore need a
        % special adaptor as they both can return strong types.
        % Other datastores are assume to return cell arrays.
        pa = matlab.bigdata.internal.lazyeval.LazyPartitionedArray.createFromDatastore(in);
        
        if matlab.io.datastore.internal.shim.isUniformRead(in)
            previewData = iGetDatastorePreview(in);
            if istable(previewData) && ~isequal(previewData.Properties.RowNames, {})
                previewData.Properties.RowNames = {};
                warning(message('MATLAB:bigdata:array:IgnoringRowNames'));
            end
            if istimetable(previewData) && ~isequal(previewData.Properties.Events, [])
                previewData.Properties.Events = [];
                warning(message('MATLAB:bigdata:array:IgnoringEvents'));
            end
            ad = matlab.bigdata.internal.adaptors.getAdaptorFromPreview(previewData);
            if ismember(ad.Class, ["categorical" "table" "timetable"]) ...
                    && ~matlab.bigdata.internal.util.DatastoreWithIdenticalCategoriesList.isGuaranteedIdenticalCategories(in)
                % Reset the categories of any categorical adaptor obtained
                % from a preview with an incomplete set of categories.
                ad = resetCategories(ad);
                % We must call applyIdentCats right now to avoid emitting an inconsistent
                % categorical array.
                [pa, ad] = matlab.bigdata.internal.util.applyIdentCats(pa, ad);
            end
        else
            ad = matlab.bigdata.internal.adaptors.GenericAdaptor();
        end
        
    elseif istall(in)
        % Copy from an existing tall array
        ad = in.Adaptor;
        pa = in.ValueImpl;
        
    elseif isa(in, 'matlab.bigdata.internal.PartitionedArray')
        % We got a partitioned array with no adaptor. Use the generic one.
        pa = in;
        ad = matlab.bigdata.internal.adaptors.GenericAdaptor();
        
    else
        % Treat as in-memory data.
        [pa,ad] = iCreateFromLocal(in);
        
    end
catch E
    matlab.bigdata.internal.throw(E);
end
end % construct

function [pa,ad] = iCreateFromLocal(data)

% We cannot support RowNames for tall tables, so remove them.
if istable(data)
    if ~isequal(data.Properties.RowNames, {})
        data.Properties.RowNames = {};
        warning(message('MATLAB:bigdata:array:IgnoringRowNames'));
    end
elseif istimetable(data)
    if ~isequal(data.Properties.Events, [])
        data.Properties.Events = [];
        warning(message('MATLAB:bigdata:array:IgnoringEvents'));
    end
end

% Canonical 'missing' version.
if isa(data, 'missing')
    data = double(data);
end

% Create a partitioned array and adaptor for some in-memory data
ad = matlab.bigdata.internal.adaptors.getAdaptor(data);
ad = setKnownSize(ad, size(data));

% Create the underlying PartitionedArray object. In certain cases, this
% will use an internal datastore to get the desired blocking and
% partitioning behavior.
tallSettings = matlab.bigdata.internal.TallSettings.get();
if tallSettings.EnableInMemoryBlock && (size(data, 1) > 1)
    ds = matlab.bigdata.internal.MemoryDatastore(data);
    totalSizeInBytes = matlab.bigdata.internal.util.getSizeInBytes(data);
    maxBlockHeight = ceil(tallSettings.InMemoryBlockSizeInBytes / totalSizeInBytes * size(data, 1));
    ds.ReadSize = maxBlockHeight;
    ds.MaxPartitions = tallSettings.InMemoryBlockMaxPartitions;
    pa = matlab.bigdata.internal.lazyeval.LazyPartitionedArray.createFromDatastore(ds);
else
    pa = matlab.bigdata.internal.lazyeval.LazyPartitionedArray.createFromConstant(data);
end
end % iCreateFromLocal

% Get the preview of a datastore.
function data = iGetDatastorePreview(ds)
try
    data = preview(ds);
catch err
    matlab.bigdata.internal.throw(err, 'IncludeCalleeStack', true);
end
end
