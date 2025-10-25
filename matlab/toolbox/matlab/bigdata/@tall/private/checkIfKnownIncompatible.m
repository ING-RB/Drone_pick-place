function checkIfKnownIncompatible(inputs, varargin)
%checkIfKnownIncompatible Check whether a collection of tall inputs are
% known to be incompatible up-front. This will issue the appropriate error
% if found to be incompatible.
%
% Syntax:
%  checkIfKnownIncompatible({tX,tY,..},name1,value1,..)
%
% Two tall arrays are incompatible if:
%  - They have different partitionings
%  - They have different heights
%
% Name-value pairs consist of:
%  - AllowExpansion:    Flag specifying if a broadcast of height one is
%                       exempt from same partition/height rule. Defaults
%                       to true.
%  - RequireSameHeight: Flag whether to apply the same height rule. If
%                       false, this will only check for same partitioning
%                       strategy. Defaults to true.

%   Copyright 2018-2019 The MathWorks, Inc.

[requireSameHeight, allowExpansion] = iParseOptions(varargin{:});

[knownHeight, knownPartitionStrategy] = iParseInput(inputs{1}, allowExpansion);

for ii = 2:numel(inputs)
    [newHeight, newPartitionStrategy] = iParseInput(inputs{ii}, allowExpansion);
    
    % Compare known heights
    if requireSameHeight
        if isnan(knownHeight)
            knownHeight = newHeight;
        elseif ~isnan(newHeight) && (knownHeight ~= newHeight)
            if allowExpansion
                matlab.bigdata.internal.throw(...
                    message('MATLAB:bigdata:array:IncompatibleTallSize')...
                    );
            else
                matlab.bigdata.internal.throw(...
                    message('MATLAB:bigdata:array:IncompatibleTallStrictSize')...
                    );
            end
        end
    end
    
    % Compare partitionings
    if allowExpansion && newPartitionStrategy.IsBroadcast
        % Do nothing
    elseif allowExpansion && knownPartitionStrategy.IsBroadcast
        knownPartitionStrategy = newPartitionStrategy;
    elseif ~isCompatible(knownPartitionStrategy, newPartitionStrategy)
        if knownPartitionStrategy.IsDatastorePartitioning && newPartitionStrategy.IsDatastorePartitioning ...
                && ~isa(knownPartitionStrategy.Datastore, 'matlab.bigdata.internal.MemoryDatastore') ...
                && ~isa(newPartitionStrategy.Datastore, 'matlab.bigdata.internal.MemoryDatastore')
            % Throw IncompatibleTallDatastore for all datastores except for
            % MemoryDatastore.
            matlab.bigdata.internal.throw(...
                message('MATLAB:bigdata:array:IncompatibleTallDatastore') ...
                );
        else
            matlab.bigdata.internal.throw(...
                message('MATLAB:bigdata:array:IncompatibleTallIndexing') ...
                );
        end
    end
end
end

function [height, partitionStrategy] = iParseInput(input, allowExpansion)
% Parse a tall or non-tall input into its known height and partition
% strategy. If height is not known, or input is to be broadcasted, the
% returned height value is NaN.
import matlab.bigdata.internal.executor.BroadcastPartitionStrategy;
import matlab.bigdata.internal.executor.PartitionStrategy;
if istall(input)
    height = getSizeInDim(matlab.bigdata.internal.adaptors.getAdaptor(input), 1);
    paImpl = hGetValueImpl(input);
    partitionStrategy = paImpl.PartitionMetadata.Strategy;
else
    height = size(input, 1);
    partitionStrategy = BroadcastPartitionStrategy();
end

if allowExpansion
    if height == 1
        % NaN represents unknown height. To make the height comparison code
        % simpler, we treat broadcast as equivalent to unknown height. I.E. we
        % ignore both broadcast and things of unknown height when checking if
        % two arrays are known to be different height.
        height = NaN;
    elseif ~isnan(height) && partitionStrategy.IsBroadcast
        % Broadcast partitioning includes:
        %  1. Implicit broadcast (I.E. height one array).
        %  2. Explicit broadcast (I.E. BroadcastArray).
        %  3. Non-broadcasts that just so happen to live in the client.
        % Singleton expansion is only allowed for (1) and (2). To guard
        % early against singleton expansion of (3), we pretend such data is
        % actually across a single partition for the sake of checking
        % compatibility.
        partitionStrategy = PartitionStrategy.create(1);
    end
end
end

function [requireSameHeight, allowExpansion] = iParseOptions(varargin)
% Parse input options AllowExpansion and RequireSameHeight.
parser = inputParser();
parser.addParameter('RequireSameHeight', true);
parser.addParameter('AllowExpansion', true);
parser.parse(varargin{:});
options = parser.Results;
requireSameHeight = options.RequireSameHeight;
allowExpansion = options.AllowExpansion;
end
