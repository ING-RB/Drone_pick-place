%AbstractAdaptor Adaptor base class.
%   Each tall array instance holds a PartitionedArray and an Adaptor.  The
%   Adaptor is responsible for holding metadata relating to the PartitionedArray
%   that is known at the client. The Adaptor also is responsible for
%   implementing methods that depend on that metadata.
%
%   In practice, this means that the all Adaptor classes hold at least the
%   following information about the PartitionedArray:
%    - Class - the underlying class of the data, or '' if not known
%    - NDims - NDIMS for the underlying array, or NaN if not known
%    - Size  - when NDIMS is non-NaN, a 1xNDims vector of size information,
%              where any element might be NaN if it is not known.
%
%   The primary responsibility of the Adaptor class is to implement the various
%   forms of indexing supported by tall arrays. The tall array methods SUBSREF
%   and SUBSASGN perform simple analysis to determine which form of indexing is
%   being performed, and then invoke one of the subsref* or subsasgn* methods on
%   the Adaptor, passing the corresponding PartitionedArray to operate on.

% Copyright 2016-2023 The MathWorks, Inc.
classdef (Abstract) AbstractAdaptor
    
    properties (SetAccess = 'immutable')
        % Modifying class post-construction is a bad idea since this might allow an
        % adaptor to be used for an inappropriate type.
        Class = '';
    end
    properties (SetAccess = private)
        % Size only valid if NDims is non-NaN
        NDims = NaN;
    end
    properties (Dependent)
        Size
        TallSizeId
    end
    
    properties (SetAccess = 'private')
        % TallSize is a handle to an object that can be shared by many Adaptors and thus
        % allows sizes to be injected.
        TallSize;
        % SmallSizes is a standard numeric array.
        SmallSizes = [];
    end
    
    properties (SetAccess = protected)
        % Should arrays using this adaptor compute metadata? Defaults to 'false', but
        % can be overridden.
        ComputeMetadata = false;
    end
    
    methods
        function sz = get.Size(obj)
            if isnan(obj.NDims)
                sz = [];
            else
                sz = [obj.TallSize.Size, obj.SmallSizes];
            end
        end
        function tid = get.TallSizeId(obj)
            tid = obj.TallSize.Id;
        end
    end
    
    
    methods (Abstract)
        %getProperties return a cellstr of property names
        names = getProperties(obj)
        
        %displayImpl Implementation of DISPLAY.
        % displayInfo is matlab.bigdata.internal.display.DisplayInfo.
        displayImpl(obj, displayInfo, pa)
        
        %Various subsref implementations.
        subsrefParens(obj, pa, szPa, S)
        subsasgnParens(obj, pa, szPa, S, b)
        subsasgnParensDeleting(obj, pa, szPa, S)
        subsrefBraces(obj, pa, szPa, S)
        subsasgnBraces(obj, pa, szPa, S, b)
    end
    
    methods (Abstract, Access = protected)
        m = buildMetadataImpl(obj);
    end
    
    methods
        function m = buildMetadata(obj)
            if obj.ComputeMetadata
                m = buildMetadataImpl(obj);
            else
                m = [];
            end
        end
        function varargout = subsrefDot(obj, pa, szPa, S) %#ok<INUSD,STOUT>
            error(message('MATLAB:structRefFromNonStruct'));
        end
        function obj = subsasgnDotDeleting(obj, pa, szPa, S) %#ok<INUSD>
            error(message('MATLAB:structAssToNonStruct'));
        end
        function obj = subsasgnDot(obj, pa, szPa, S, b) %#ok<INUSD>
            error(message('MATLAB:structAssToNonStruct'));
        end
        
        % For various reductions - convert strings into "missing" flags and "precision"
        % flags. Each return must be a cell array to enable forwarding of flags.
        function [nanFlagCell, precisionFlagCell] = interpretReductionFlags(obj, FCN_NAME, ~) %#ok<STOUT>
            error(message('MATLAB:bigdata:array:FcnNotSupportedForType', FCN_NAME, obj.Class));
        end
    end
    
    methods
        
        function obj = AbstractAdaptor(clz, tsz)
            obj.Class = clz;
            if nargin < 2
                obj.TallSize = matlab.bigdata.internal.adaptors.TallSize.buildDefault();
            else
                obj.TallSize = matlab.bigdata.internal.adaptors.TallSize.buildKnownSize(tsz);
            end
        end
        
        function sample = buildSample(obj, defaultType, sz, preferSquareEmpty)
            %buildSample Builds a sample of data that matches the known
            % information stored in the adaptor in everything except the
            % tall size.
            %
            % SAMPLE = buildSample(OBJ,DEFAULTTYPE) builds a sample of the
            % data of height 1. If type is not known, the sample will have
            % type DEFAULTTYPE.
            %
            % SAMPLE = buildSample(OBJ,DEFAULTTYPE,SZ) builds a sample of the
            % data with size matching SZ as closely as possible without
            % breaking the constraint that the sample matches all known
            % information in the adaptor, apart from the height.
            %
            % SAMPLE = buildSample(OBJ,DEFAULTTYPE,SZ,USESQUARE) with
            % USESQUARE true builds an appropriate sample, except when
            % small size is not fully known. In that case, a square empty
            % of the appropriate type is returned instead.
            narginchk(2, 4);
            assert(matlab.internal.datatypes.isScalarText(defaultType), ...
                'Assertion failed: buildSample expects DEFAULTTYPE to be a scalar string or character row vector.');
            if nargin < 3
                sz = [1, 1];
            else
                assert(isrow(sz) && isnumeric(sz), ...
                    'Assertion failed: buildSample expects SZ to be a numeric row.');
                % We ensure the size vector has at least 2 elements to
                % allow the various buildSampleImpl implementations to
                % assume this fact.
                sz(1, end + 1 : 2) = 1;
            end
            
            if nargin < 4
                preferSquareEmpty = false;
            end
            if preferSquareEmpty && ~isSmallSizeKnown(obj)
                sz = [sz(1), 0];
            elseif ~isnan(obj.NDims)
                actualSizes = [NaN, obj.SmallSizes];
                % We explicitly expand the size vector as expansion via
                % subsasgn will fill with zeros, where instead we want
                % ones.
                sz(1, end + 1 : numel(actualSizes)) = 1;
                sz(~isnan(actualSizes)) = actualSizes(~isnan(actualSizes));
            end
            
            sample = obj.buildSampleImpl(defaultType, sz, preferSquareEmpty);
        end
        
        function empty = buildUnknownEmpty(obj)
            %buildUnknownEmpty Build an empty array that matches all known
            % information contained in the adaptor.
            %
            % EMPTY = buildUnknownEmpty(ADAPTOR) constructs an empty with
            % as much information from the adaptor as possible.
            % TODO(g2051985): rename this method to state that it returns a
            % 0x0 sample with the information that is known in the adaptor.
            % This sample can be vertically concatenable with the rest of
            % data in the tall array.
            empty = buildSample(resetTallSize(obj), 'double', 0, true);
        end
        
        function dim = getDefaultReductionDimIfKnown(obj)
            %getDefaultReductionDimIfKnown returns first non-singleton dimension
            % if this is known.
            % DIM = getDefaultReductionDimIfKnown(OBJ) the default reduction dimension in
            % DIM if known. If the dimension is not known, DIM is [].
            
            dim = [];
            
            if obj.TallSize.IsDefinitelyNonUnity
                % If the tall size is definitely non-unity, reduce in dim 1 *unless* the overall
                % size might be 0x0.
                if obj.TallSize.IsDefinitelyNonZero || obj.NDims>2
                    % Not 0x0
                    dim = 1;
                else
                    % Tall size might be zero
                    if isempty(obj.SmallSizes) || isequal(obj.SmallSizes, 0) || isequaln(obj.SmallSizes, nan)
                        % Small size is 0 or unknown. Overall size might be 0x0.
                    else
                        % Overall size cannot possibly be 0x0
                        dim = 1;
                    end
                end
            elseif ~isnan(obj.NDims)
                % If we get here, the tall size is either 1 or NaN.
                szVec = obj.Size;
                
                assert(isnan(szVec(1)) || szVec(1) == 1, ...
                    'Assertion failed: Tall size is not 1 or NaN when IsDefinitelyNonUnity is false.');
                
                if isnan(szVec(1))
                    % Tall size completely unknown. The only case we can handle is if all trailing
                    % dimensions are unity
                    if all(szVec(2:end) == 1)
                        dim = 1;
                    end
                else
                    % Tall size is 1. Look through remaining dimensions for non-unity. If we hit a
                    % NaN, we can't proceed.
                    
                    % Attempt to deal with the special-case of scalar
                    if isequal(szVec, [1 1])
                        dim = 1;
                    else
                        for idx = 2:numel(szVec)
                            if isnan(szVec(idx))
                                % Can't proceed
                                break
                            elseif szVec(idx) ~= 1
                                % Found non-unity dimension
                                dim = idx;
                                break
                            end
                        end
                    end
                end
            end
        end
        
        function tf = isTypeKnown(~)
            %isTypeKnown Return TRUE if and only if this adaptor has known
            % type.
            
            % Default for all adaptors except Generic is true.
            tf = true;
        end
        
        function tf = isNestedTypeKnown(obj)
            %isTypeKnown Return TRUE if and only if this adaptor and all
            % of its children have known type. Children include table
            % variables.
            tf = isTypeKnown(obj);
        end
        
        function obj = resetNestedGenericType(obj)
            %resetNestedGenericType Reset the type of any GenericAdaptor
            % found among this adaptor or any children of this adaptor.
            
            % Default is to no-op. All strong types hold their type.
        end
        
        function isNonZero = isTallSizeGuaranteedNonZero(obj)
            % Returns TRUE if the tall size is definitely >0.
            isNonZero = obj.TallSize.IsDefinitelyNonZero;
        end
        
        function isNonUnity = isTallSizeGuaranteedNonUnity(obj)
            % Returns TRUE if the tall size is definitely not 1 (ie. 0 or >1).
            isNonUnity = obj.TallSize.IsDefinitelyNonUnity;
        end
        
        function setTallSizeGtOneInPlace(obj)
            % setTallSizeGtOneInPlace - call if you know for sure that the tall size is >1,
            % but you aren't sure exactly what it is.
            setSizeIsGtOne(obj.TallSize);
        end
        
        function tf = isSizeKnown(obj, optIdx)
            %isSizeKnown Call this to find out if the size of the tall is known
            %isSizeKnown(idx) checks whether one specific size entry is known
            if nargin>1
                tf = ~isnan(obj.getSizeInDim(optIdx));
            else
                tf = ~isnan(obj.NDims) && ~any(isnan(obj.Size));
            end
        end
        
        function tf = isSmallSizeKnown(obj)
            %isSmallSizeKnown Call this to find out if all sizes other than the
            %tall size are known.
            tf = ~isnan(obj.NDims) && ~any(isnan(obj.SmallSizes));
        end
        
        function tf = isNestedSmallSizeKnown(obj)
            % Return true if both this adaptor and all its children have
            % known small size. Children include table variables.
            tf = isSmallSizeKnown(obj);
        end
        
        function tf = isKnownEmpty(obj)
            % Return true if the array is provably an empty array (any
            % known dimension is zero). False if not empty or unknown.
            tf = (isfinite(obj.NDims) && any(obj.Size == 0));
        end
        
        function tf = isKnownNotEmpty(obj)
            % Return true if the array is provably not an empty array (any
            % known dimension is zero). False if empty or unknown.
            tf = obj.isTallSizeGuaranteedNonZero() ...
                && (isfinite(obj.NDims) && all(isfinite(obj.SmallSizes)) && all(obj.Size ~= 0));
        end
        
        function tf = isKnownScalar(obj)
            % Return true if the array is provably a scalar. False if not
            % scalar or unknown.
            tf = (isfinite(obj.NDims) && all(obj.Size == 1));
        end
        
        function tf = isKnownNotScalar(obj)
            % Return true if the array is provably not scalar. False if
            % scalar or unknown.
            tf = isTallSizeGuaranteedNonUnity(obj) ...
                || obj.NDims > 2 ...
                || any(obj.Size ~= 1 & ~isnan(obj.Size));
        end
        
        function tf = isKnownVector(obj)
            % Return true if the array is provably a vector (only one
            % dimension is not unity). Returns false if not a vector or
            % unknown.
            tf = isfinite(obj.NDims) ...
                && (nnz(obj.Size(1 : 2) ~= 1) <= 1) ...
                && all(obj.Size(3 : end) == 1);
        end
        
        function tf = isKnownNotVector(obj)
            % Return true if the array is provably not a vector (only one
            % dimension is not unity). Returns false if a vector or
            % unknown.
            isSizeKnownNotOne = ~isnan(obj.Size) & (obj.Size ~= 1);
            tf = isfinite(obj.NDims) ...
                && (obj.NDims > 2 || any(isSizeKnownNotOne(3 : end)) || nnz(isSizeKnownNotOne) > 1);
        end
        
        function tf = isKnownColumn(obj)
            % Return true if the array is provably a column vector. Returns
            % false if not a column vector or unknown.
            tf = isfinite(obj.NDims) ...
                && all(obj.SmallSizes == 1);
        end
        
        function tf = isKnownNotColumn(obj)
            % Return true if the array is provably not a column vector.
            % Returns false if a column vector or unknown.
            isSmallSizeKnownNotOne = ~isnan(obj.SmallSizes) & (obj.SmallSizes ~= 1);
            tf = isfinite(obj.NDims) ...
                && (obj.NDims > 2 || any(isSmallSizeKnownNotOne));
        end
        
        function tf = isKnownRow(obj)
            % Return true if the array is provably a row vector. Returns
            % false if not a row vector or unknown.
            tf = isfinite(obj.NDims) ...
                && all(obj.Size([1, 3 : end]) == 1);
        end
        
        function tf = isKnownNotRow(obj)
            % Return true if the array is provably not a row vector.
            % Returns false if a row vector or unknown.
            isSizeKnownNotOne = ~isnan(obj.Size) & (obj.Size ~= 1);
            tf = isTallSizeGuaranteedNonUnity(obj) ...
                || (isfinite(obj.NDims) ...
                && (obj.NDims > 2 || any(isSizeKnownNotOne([1, 3 : end]))));
        end
        
        function tf = isKnownMatrix(obj)
            % Return true if the array is provably a matrix. Returns
            % false if not a matrix or unknown.
            tf = isfinite(obj.NDims) ...
                && all(obj.SmallSizes(2 : end) == 1);
        end
        
        function tf = isKnownNotMatrix(obj)
            % Return true if the array is provably not a matrix.
            % Returns false if a matrix or unknown.
            isSmallSizeKnownNotOne = ~isnan(obj.SmallSizes) & (obj.SmallSizes ~= 1);
            tf = isfinite(obj.NDims) ...
                && (obj.NDims > 2 || any(isSmallSizeKnownNotOne(2 : end)));
        end
        
        function tf = isKnownDifferentTallSize(objA, objB)
            % Return true if the two arrays can be proven to have a
            % different size in tall dims.
            szA = objA.getSizeInDim(1);
            szB = objB.getSizeInDim(1);
            tf = ~isnan(szA) && ~isnan(szB) && (szA ~= szB);
        end
        
        function tf = isKnownDifferentSmallSize(objA, objB)
            % Return true if the two arrays can be proven to have a
            % different size in small dims.
            szA = objA.SmallSizes;
            szB = objB.SmallSizes;
            tf = ~~isnan(objA.NDims) && ~~isnan(objB.NDims) ...
                && any(~isnan(szA) & ~isnan(szB) & (szA ~= szB));
        end
        
        function sz = getSizeInDim(obj, dim)
            % Return the size of the array in the specified dimension
            % Will be nan for unknown dimensions.
            if dim==1
                % Tall size is special as we may know it even if all other
                % dims are unknown (i.e. size vector is empty).
                sz = obj.TallSize.Size;
                return;
            end
            
            if dim <= length(obj.Size)
                % Part of the size vector
                sz = obj.Size(dim);
            else
                % Trailing dimension. If we know the number of
                % dimensions then this is definitely 1. Otherwise
                % unknown.
                if isnan(obj.NDims)
                    sz = nan;
                else
                    sz = 1;
                end
            end
        end
        
        function smallSizes = getReshapedSmallSizes(obj, numSmallDims)
            %getReshapedSmallSizes Get the small sizes after the automatic
            %reshape that occurs if you index with only numSmallDims small
            %subscripts.
            if isnan(obj.NDims)
                smallSizes = nan(1, numSmallDims);
                return;
            end
            
            smallSizes = obj.SmallSizes;
            if numel(smallSizes) < numSmallDims
                smallSizes(1, end + 1 : numSmallDims) = 1;
            else
                if any(smallSizes(numSmallDims : end) == 0)
                    % If any dim has size 0, this will propagate to
                    % lastDimSize even if another dim is not known.
                    lastDimSize = 0;
                else
                    lastDimSize = prod(smallSizes(numSmallDims : end));
                end
                smallSizes(numSmallDims) = lastDimSize;
                smallSizes(numSmallDims + 1 : end) = [];
            end
        end
        
        function obj = setSizeInDim(obj, dim, sz)
            % Set the size of the array in the specified dimension.
            % Note that this will create a new tall size rather than updating
            % the tall size of existing arrays.
            assert(nargout == 1, ...
                'Assertion failed: Adaptor set methods must have an output.');
            if dim==1
                obj.TallSize = matlab.bigdata.internal.adaptors.TallSize.buildKnownSize(sz);
                
            elseif ~isnan(obj.NDims)
                % Only set a small size if ndims is known. We may relax this
                % constraint later. We may need to extend the size vector.
                dim = dim - 1;
                if dim <= length(obj.SmallSizes)
                    % Update an existing dimension
                    obj.SmallSizes(dim) = sz;
                elseif ~isequal(sz, 1)
                    % Trailing non-unity dimension. Pad with ones as required.
                    n = dim - length(obj.SmallSizes);
                    obj.SmallSizes = [obj.SmallSizes, ones(1,n)];
                    obj.SmallSizes(dim) = sz;
                end
                % Make sure the dimensions are still consistent
                obj = packDims(obj);
                
            end
        end
        
        function obj = setKnownSize(obj, szVec)
            %setKnownSize Call this when you know the size of the tall
            
            szVec = iFixSizeVector(szVec);
            nd = numel(szVec);
            assert(isnan(obj.NDims) || obj.NDims == nd, ...
                'Assertion failed: Attempted to set known size with ndims %i, when ndims expected to be %i.', ...
                nd, obj.NDims);
            obj.NDims = numel(szVec);
            if isnan(szVec(1))
                obj.TallSize = matlab.bigdata.internal.adaptors.TallSize.buildDefault();
            else
                obj.TallSize.Size = szVec(1);
            end
            obj.SmallSizes = szVec(2:end);
            % Make sure the dimensions are still consistent
            obj = packDims(obj);
        end
        
        function obj = setSmallSizes(obj, smallSizes)
            %setSmallSizes Call this when the tall size is unchanged, and now you know the
            %small sizes
            
            % Note iFixSizeVector wants to work on a full size vector, so we prepend a dummy
            % NaN, and then strip it out again.
            if ~isnan(obj.NDims)
                assert(obj.NDims == 1 + numel(smallSizes),  ...
                    'Assertion failed: Attempted to set small size with ndims %i, when ndims expected to be %i.', numel(smallSizes) + 1, obj.NDims);
                assert(all(obj.SmallSizes(~isnan(obj.SmallSizes)) == smallSizes(~isnan(obj.SmallSizes))), ...
                    'Assertion failed: Attempted to set small size different to already known value.');
            end
            tmp = iFixSizeVector([NaN smallSizes]);
            obj.SmallSizes = tmp(2:end);
            obj.NDims = numel(obj.SmallSizes) + 1;
        end
        
        function obj = resetSizeInformation(obj)
            %resetSizeInformation Call this when an operation has been performed that means
            %that all size information is lost
            obj.NDims      = NaN;
            obj.TallSize   = matlab.bigdata.internal.adaptors.TallSize.buildDefault();
            obj.SmallSizes = [];
        end
        
        function obj = resetTallSize(obj)
            %resetTallSize Call this when an operation has been performed that changes the
            %tall size to an unknown value, but leaves other dimensions alone. This
            %will also disconnect the tall size of this adaptor from any other
            %linked adaptors.
            obj.TallSize = matlab.bigdata.internal.adaptors.TallSize.buildDefault();
        end
        
        function obj = setTallSize(obj, m)
            %setTallSize Call this when an operation results in a tall array with a known
            %tall size. The known size must be non-NaN. This will also update the
            %tall sizes of other linked tall arrays.
            assert(isscalar(m) && isnumeric(m) && m == floor(real(m)) && ~isnan(m), ...
                'Assertion failed: Tall size must be a scalar non-negative integer.');
            obj.TallSize.Size = m;
        end
        
        function obj = resetSmallSizes(obj, szVec)
            %resetSmallSizes Call this when an operation has been performed that
            %changes the small sizes but leaves the tall dimension alone (i.e.
            %slicefun)
            %
            % ad = resetSmallSizes(ad) indicates unknown small sizes (ndims = nan)
            % ad = resetSmallSizes(ad,szVec) sets the small sizes to szVec
            % (ndims = numel(szVec)+1)
            %
            % This method includes a call to 'packDims' to strip any extra trailing
            % 1s in szVec.
            if nargin<2
                obj.NDims = NaN;
                obj.SmallSizes = [];
            else
                obj.NDims = numel(szVec)+1;
                obj.SmallSizes = szVec;
                obj = packDims(obj);
            end
        end
        
        function obj = resetNestedSmallSizes(obj)
            %resetNestedSmallSizes Reset the small size of both this
            % adaptor and any children. Children include table variables.
            obj = resetSmallSizes(obj);
        end
        
        function obj = copyTallSize(obj, copyFrom)
            % Call this when two arrays are guaranteed to have the same tall size. This
            % updates obj to use the same handle for 'TallSize'.
            obj.TallSize = copyFrom.TallSize;
        end
        
        function obj = copySizeInformation(obj, copyFrom)
            %copySizeInformation Call this to copy size information from one adaptor to
            %another.
            
            if isnan(copyFrom.NDims)
                % If copyFrom doesn't have small dimensions, reset everything
                obj = resetSizeInformation(obj);
            else
                obj.NDims      = copyFrom.NDims;
                obj.SmallSizes = copyFrom.SmallSizes;
            end
            
            % Always sync the tall sizes.
            obj = copyTallSize(obj, copyFrom);
        end
        
        function obj = copyCompatibleInformation(obj, copyFrom)
            % Copy compatible information from one adaptor to another.
            % A piece of information is compatible with a target adaptor if
            % that information could be valid for the underlying data.
            %
            % For example:
            %  * Known width 3 is compatible with an adaptor of unknown width
            %  * Unknown width is compatible with an adaptor of known width 3
            % But:
            %  * Known width 3 is not compatible with an adaptor of known width 5
            %  * Known type string is not compatible with non-strong adaptors
            %
            % This is necessary for validateSyntax when creating its
            % underlying samples. We need a way to align two adaptors if
            % they could actually represent the same data, without aligning
            % two adaptors that are known to be incompatible.
            
            % Type is compatible if both adaptors have the same type, or
            % one adaptor has unknown type and the other is of a known
            % non-strong type. If type is compatible, we force obj to have
            % the same type (and known/unknown attribute) as copyFrom.
            import matlab.bigdata.internal.adaptors.getStrongTypes
            if (obj.Class == "" && ~ismember(copyFrom.Class, getStrongTypes)) ...
                    || (copyFrom.Class == "" && ~ismember(obj.Class, getStrongTypes))
                obj = copySizeInformation(resetSizeInformation(copyFrom), obj);
            end
            
            % Size is compatible if both adaptors have the same size, or
            % one adaptor does not know its size. If size is compatible,
            % we force obj to have the same size (and known/unknown
            % attribute) as copyFrom. If only part of size is compatible,
            % this is applied only to that part of size.
            if isnan(obj.NDims) || isnan(copyFrom.NDims)
                obj = copyTallSize(copySizeInformation(obj, copyFrom), obj);
            else
                sz = obj.SmallSizes;
                mask = isnan(sz);
                mask = mask(1:numel(copyFrom.SmallSizes)) | isnan(copyFrom.SmallSizes);
                sz(mask) = copyFrom.SmallSizes(mask);
                obj = setSmallSizes(resetSmallSizes(obj), sz);
            end
        end
        
        function obj = reduceSizeInDimBy(obj, dim, N)
            % reduceSizeInDimBy Call this when an operation results in a
            % reducing the size in a given dimension.  This will preserve the
            % size information in all other dimensions.
            if dim == 1
                % Reduce the size in the tall dimension
                inputTallSize = obj.getSizeInDim(1);
                
                % We know the tall size is reduced so always sever the link between
                % input and output adaptors.  Small sizes (if known) are preserved.
                obj = resetTallSize(obj);
                
                if ~isnan(inputTallSize)
                    % TallSize known - reduce it by N
                    obj = setTallSize(obj, max(0, inputTallSize - N));
                end
            else
                % Reduce the size in the given small dimension
                inputSmallSizes = obj.SmallSizes;
                
                % Tall size is preserved so copy the input adaptor with unknown small sizes
                obj = resetSmallSizes(obj);
                
                if numel(inputSmallSizes) >= (dim-1) && ~isnan(inputSmallSizes(dim-1))
                    % Small size known in dim to reduce
                    outputSmallSizes = inputSmallSizes;
                    outputSmallSizes(dim-1) = max(0, outputSmallSizes(dim-1) - N);
                    obj = resetSmallSizes(obj, outputSmallSizes);
                end
            end
        end
    end
    
    methods (Access=private)
        function obj = packDims(obj)
            % Helper to make sure we don't keep trailing ones in the small
            % sizes.
            if length(obj.SmallSizes) >= 2
                lastNonTrivialDim = find(obj.SmallSizes(2:end) ~= 1, 1, 'last');
                if isempty(lastNonTrivialDim)
                    obj.SmallSizes = obj.SmallSizes(1);
                else
                    obj.SmallSizes = obj.SmallSizes(1:(1 + lastNonTrivialDim));
                end
                % Be careful about the trailing dim being NaN, since that
                % means it might be one (and hence ndims is not what we
                % think it is).
                if length(obj.SmallSizes)>=2 && isnan(obj.SmallSizes(end))
                    % Since we can no longer guarantee the dimensionality,
                    % set ndims to nan.
                    obj.NDims = nan;
                else
                    obj.NDims = length(obj.SmallSizes)+1;
                end
            end
        end
    end
    
    methods (Abstract, Access=protected)
        % Build a sample of the underlying data.
        % This will be invoked with both a default type for the sample and
        % a default size:
        %  1. The default type will be a character row vector. This is to
        %     generate any sample data where the type is not already known.
        %  2. The default size will be a row vector of size at least 2. The
        %     adaptor must respect default size in dimension 1. In all
        %     other dimensions, it can use known small sizes.
        sample = buildSampleImpl(obj, defaultType, sz, preferSquareEmpty);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function szVec = iFixSizeVector(szVec)
% We insist on double for specifying sizes because otherwise NaN values
% get converted to zeros.
if ~isa(szVec, 'double')
    szVec = double(szVec);
end

assert(isrow(szVec) && numel(szVec) >= 2, ...
    'Specified size vector must be a row vector with at least 2 elements.');
lastNonTrivialDim = find(szVec(2:end) ~= 1, 1, 'last');
if isempty(lastNonTrivialDim)
    szVec = szVec(1:2);
else
    szVec = szVec(1:(1 + lastNonTrivialDim));
end
end
