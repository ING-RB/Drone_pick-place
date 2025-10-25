classdef ComposedDatastore < matlab.io.Datastore ...
                           & matlab.io.datastore.mixin.Subsettable
%matlab.io.datastore.internal.ComposedDatastore   Simplify datastore composition.
%
%   ComposedDatastore is an abstract class which enables composition of datastores.
%
%   Subclasses must define a scalar property called "UnderlyingDatastore"
%   with protected or public access.
%
%   Once UnderlyingDatastore is defined, ComposedDatastore provides default implementations
%   of the following methods by forwarding to the UnderlyingDatastore:
%
%     Core datastore methods:
%      - hasdata
%      - reset
%      - read
%      - readall
%      - preview
%      - progress
%
%     Partitionable methods:
%      - partition
%      - maxpartitions
%
%     Subsettable methods:
%      - subset
%      - numobservations
%      - shuffle
%
%     Traits methods:
%      - isPartitionable
%      - isShuffleable
%      - isSubsettable
%
%     Object behavior:
%      - copyElement
%
%   The default implementations of all of these methods have the assumption that
%   the UnderlyingDatastore is the only stateful handle object in the datastore.
%
%   If you have other stateful handle objects in the superclass, you may need to
%   override some of these methods.
%
%   What is the benefit of this approach? It means that you don't have to inherit
%   from the UnderlyingDatastore, avoiding state problems with copy/isequaln/save/load
%   which means that each class can be modified independently without affecting the other.
%
%   Example
%   =======
%
%       classdef EvenDatastore < matlab.io.datastore.internal.ComposedDatastore
%       %EvenDatastore   Datastore that returns N even numbers.
%
%           properties
%               N (1, 1) double {mustBeInteger, mustBePositive} = 0;
%           end
%
%           properties (Access = protected)
%               % Required by ComposedDatastore
%               UnderlyingDatastore = arrayDatastore(double.empty(0, 1), OutputType="same");
%           end
%
%           methods
%               function obj = EvenDatastore(N)
%                   obj.N = N;
%                   obj.UnderlyingDatastore = arrayDatastore(2*(1:N)', OutputType="same");
%               end
%
%               % NOTE: For production-ready classes, you probably want to implement
%               %       save-to-struct and load-from-struct manually too.
%           end
%       end
%
%   See also: matlab.io.Datastore, matlab.io.datastore.Partitionable

%   Copyright 2021 The MathWorks, Inc.

    properties (Abstract, Access = protected)
       UnderlyingDatastore (1, 1) {matlab.io.datastore.internal.validators.mustBeDatastore}
    end

    % Set access attributes for relevant methods.
    methods (Access=protected)
        n = maxpartitions(ds);

        dsCopy = copyElement(ds);
    end

    % These methods aren't user-visible yet.
    % Except "progress". TODO: why is progress still hidden?
    methods (Hidden)
        frac = progress(ds);

        n = numobservations(ds);

        result = visitUnderlyingDatastores(ds, visitFcn, combineFcn);
    end
end
