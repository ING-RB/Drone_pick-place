classdef DatastoreTraits < handle ...
                         & matlab.io.datastore.internal.ComposedDatastoreConvenienceConstructors
%DatastoreTraits   Provides implementations of common traits methods for the
%   two datastore base classes

%   Copyright 2019-2022 The MathWorks, Inc.

    methods
        function tf = isPartitionable(ds)
        %isPartitionable   returns true if this datastore is partitionable
            tf = isa(ds, "matlab.io.datastore.Partitionable") ...
              || isa(ds, "matlab.io.datastore.SplittableDatastore"); % For V1 datastores
        end

        function tf = isShuffleable(ds)
        %isShuffleable   returns true if this datastore is shuffleable
            tf = isa(ds, "matlab.io.datastore.Shuffleable");
        end

        function tf = isSubsettable(ds)
        %isSubsettable   returns true if this datastore is subsettable
            tf = isa(ds, "matlab.io.datastore.mixin.Subsettable") ...
              || isa(ds, "matlab.io.datastore.Subsettable");
        end
    end

    methods (Hidden)
        function tf = isRandomizedReadable(ds)
        %isRandomizedReadable   returns true if this datastore is known
        %   to randomize data after reset
            tf = isa(ds, "matlab.io.datastore.internal.RandomizedReadable");
        end

        function tf = anyUnderlyingDatastores(ds, conditionFcn)
        %anyUnderlyingDatastores   returns true if this datastore OR any underlying datastore
        %   satisfies conditionFcn.
        %
        %   This is useful for validating TransformedDatastore and CombinedDatastore
        %   trees. For example:
        %
        %       imds = imageDatastore("peppers.png");
        %       ttds = tabularTextDatastore("outages.csv");
        %       tds1 = imds.transform(@(x) x);
        %       tds2 = ttds.transform(@(x) x);
        %       cds = combine(tds2, tds1);
        %
        %       hasIMDSFcn = @(ds) isa(ds, "matlab.io.datastore.ImageDatastore");
        %
        %       anyUnderlyingDatastores(imds, hasIMDSFcn) % true
        %       anyUnderlyingDatastores(ttds, hasIMDSFcn) % false
        %       anyUnderlyingDatastores(tds1, hasIMDSFcn) % true
        %       anyUnderlyingDatastores(tds2, hasIMDSFcn) % false
        %       anyUnderlyingDatastores(cds,  hasIMDSFcn) % true
        %
        %   This function shouldn't need to be overloaded, just overload
        %   visitUnderlyingDatastores instead.
        %
        %   See also: matlab.io.Datastore.visitUnderlyingDatastores

            % Performs validation and visits all underlying datastores.
            tf = ds.visitUnderlyingDatastores(conditionFcn, @(x, y) any([x y]));
        end

        function tf = allUnderlyingDatastores(ds, conditionFcn)
        %allUnderlyingDatastores   returns true if this datastore AND all underlying datastores
        %   satisfy conditionFcn.
        %
        %   This is useful for validating TransformedDatastore and CombinedDatastore
        %   trees. For example:
        %
        %       imds = imageDatastore("peppers.png");
        %       ttds = tabularTextDatastore("outages.csv");
        %       tds1 = imds.transform(@(x) x);
        %       tds2 = ttds.transform(@(x) x);
        %       cds = combine(tds2, tds1);
        %
        %       isTransformOfIMDSFcn = @(ds) isa(ds, "matlab.io.datastore.ImageDatastore") ...
        %                                 || isa(ds, "matlab.io.datastore.TransformedDatastore") ...
        %                                 || isa(ds, "matlab.io.datastore.CombinedDatastore");
        %
        %       allUnderlyingDatastores(imds, isTransformOfIMDSFcn) % true
        %       allUnderlyingDatastores(ttds, isTransformOfIMDSFcn) % false
        %       allUnderlyingDatastores(tds1, isTransformOfIMDSFcn) % true
        %       allUnderlyingDatastores(tds2, isTransformOfIMDSFcn) % false
        %       allUnderlyingDatastores(cds,  isTransformOfIMDSFcn) % false
        %
        %   This function shouldn't need to be overloaded, just overload
        %   visitUnderlyingDatastores instead.
        %
        %   See also: matlab.io.Datastore.visitUnderlyingDatastores

            % Performs validation and visits all underlying datastores.
            tf = ds.visitUnderlyingDatastores(conditionFcn, @(x, y) all([x y]));
        end

        function result = visitUnderlyingDatastores(ds, visitFcn, combineFcn)
        %visitUnderlyingDatastores   applies a function handle to all underlying
        %   datastores in the tree, and combines the results using combineFcn.
        %
        %   This is useful for visiting trees of TransformedDatastore and CombinedDatastore.
        %   For example:
        %
        %       imds = imageDatastore("peppers.png");
        %       ttds = tabularTextDatastore("outages.csv");
        %       tds1 = imds.transform(@(x) x);
        %       tds2 = ttds.transform(@(x) x);
        %       cds = combine(tds2, tds1);
        %
        %   numDatastoresInTree = visitUnderlyingDatastores(imds, @numel, @plus); % 1
        %   numDatastoresInTree = visitUnderlyingDatastores(ttds, @numel, @plus); % 1
        %   numDatastoresInTree = visitUnderlyingDatastores(tds1, @numel, @plus); % 2
        %   numDatastoresInTree = visitUnderlyingDatastores(tds2, @numel, @plus); % 2
        %   numDatastoresInTree = visitUnderlyingDatastores(cds,  @numel, @plus); % 5
        %
        %   If you have written your own meta-datastore (a datastore that wraps around
        %   other datastores), you probably needed to overload other functions in
        %   this file. Consider overloading this function too.
        %
        %   If your datastore doesn't nest multiple other datastores in it, the default
        %   implementation provided here should suffice for you.
        %
        %   See also: matlab.io.datastore.TransformedDatastore.visitUnderlyingDatastores

            arguments
                ds;
                visitFcn(1, 1) function_handle;
                combineFcn(1, 1) function_handle;
            end

            % Basic funarg validation:
            % - Visitor needs to allow at least one input and one output.
            % - Combiner needs to allow at least two inputs and one output.
            % - varargin/varargout (nargin/nargout <= -1) should be supported.
            isInvalid = nargin(visitFcn) == 0 ...
                     || nargout(visitFcn) == 0 ...
                     || nargin(combineFcn) == 0 ...
                     || nargin(combineFcn) == 1 ...
                     || nargout(combineFcn) == 0;
            if isInvalid
                error(message("MATLAB:datastoreio:datastore:invalidVisitFcn"));
            end

            % Visit only this datastore.
            result = visitFcn(ds);
        end

        function uds = getUnderlyingDatastore(ds, classname)
        %getUnderlyingDatastore   returns the first underlying datastore
        %   that matches CLASSNAME using a depth-first search on the
        %   underlying datastore tree.
        %
        %       % Fetch the ImageDatastore out of a transform/combine stack
        %       imds = imageDatastore("peppers.png");
        %       tds1 = imds.transform(@(x) x);
        %       result1 = tds1.getUnderlyingDatastore("matlab.io.datastore.ImageDatastore")
        %
        %       % If the datastore wasn't found, [] is returned instead.
        %       ttds = tabularTextDatastore("outages.csv");
        %       tds2 = ttds.transform(@(x) x);
        %       result2 = tds2.getUnderlyingDatastore("matlab.io.datastore.ImageDatastore")
        %
        %   See also: matlab.io.datastore.TransformedDatastore.visitUnderlyingDatastores

            arguments
                ds  (1, 1) {matlab.io.datastore.internal.validators.mustBeDatastore}
                classname (1, 1) string {mustBeNonmissing, mustBeNonzeroLengthText}
            end

            function result = visitFcn(ds, class)
                if isa(ds, class)
                    result = ds;
                else
                    result = [];
                end
            end

            function result = combineFcn(result1, result2, class)
                if isa(result1, class)
                    result = result1;
                elseif isa(result2, class)
                    result = result2;
                else
                    result = [];
                end
            end

            uds = ds.visitUnderlyingDatastores(@(x) visitFcn(x, classname), ...
                                               @(x, y) combineFcn(x, y, classname));
        end
    end
end
