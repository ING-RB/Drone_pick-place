function C = convImpl(varargin)
%CONVIMPL Common implementation of convolution that can be used from CONV,
%CONV2, and CONVN. This does not include up-front error checking.
%   C = CONVIMPL(SHAPE, A, B)
%   C = CONVIMPL(SHAPE, A, H1, H2) % CONV2 only

%   Copyright 2017 The MathWorks, Inc.

narginchk(3,4);
switch nargin
    case 3
        [shape,A,B] = deal(varargin{:});
        convheight = size(B,1);
        separable = false;
    case 4
        [shape,A,H1,H2] = deal(varargin{:});
        convheight = length(H1);
        separable = true;
end

% Guard against full convolution when A is 0xN since it gets expanded in
% unexpected ways.
if strcmpi(shape, 'full')
    aAdaptor = A.Adaptor;
    A = slicefun(@iCheckNotEmpty, A, isempty(A));
    A.Adaptor = aAdaptor;
end

% The convolution stencil window is determined by the height of B (or H1)
if convheight==0
    % Empty kernel doesn't need a window
    window = [0 0];
elseif mod(convheight, 2) == 0
    % for even numbered height, center the window on the current and
    % following slices.
    nb = convheight/2;
    window = [nb-1 nb];
else
    n = (convheight-1)/2;
    window = [n n];
end

if separable
    convStencilFcn = iCreateConv2SeparableStencilFcn(shape, H1, H2);
    C = stencilfun(convStencilFcn, window, A);
    szB = [numel(H1) numel(H2)];
    isBSingle = isa(H1, 'single') || isa(H2, 'single');
else
    convStencilFcn = iCreateConvnStencilFcn(shape, B);
    C = stencilfun(convStencilFcn, window, A);
    szB = size(B);
    isBSingle = isa(B, 'single');
end
C = iSetOutputSize(A, szB, C, shape);
C = iSetOutputType(A.Adaptor.Class, isBSingle, C);

end

function convStencilFcn = iCreateConvnStencilFcn(shape, B)
% Create the function handle to use in STENCIFLUN
if strcmpi(shape, 'full')
    convStencilFcn = @(varargin) iConvnFullStencil(varargin{:}, B);
elseif strcmpi(shape, 'same')
    convStencilFcn = @(varargin) iConvnSameStencil(varargin{:}, B);
else
    % shape must be 'valid', directly use conv
    convStencilFcn = @(~,x) convn(x, B, shape);
end
end

function convStencilFcn = iCreateConv2SeparableStencilFcn(shape, H1, H2)
% Create the function handle to use in STENCIFLUN
if strcmpi(shape, 'full')
    convStencilFcn = @(varargin) iConv2SeparableFullStencil(varargin{:}, H1, H2);
elseif strcmpi(shape, 'same')
    convStencilFcn = @(varargin) iConv2SeparableSameStencil(varargin{:}, H1, H2);
else
    % shape must be 'valid', directly use conv
    convStencilFcn = @(~,x) conv2(H1, H2, x, shape);
end
end

function y = iConvnFullStencil(info, x, B)
% Call non-separable CONV2 on one chunk for 'full' shape.

% Use full convolution for all chunks
y = convn(x, B, 'full');

% Now work out how much output we should generate
y = iConvnFullStencilCommon(x, y, info);
end

function y = iConv2SeparableFullStencil(info, x, H1, H2)
% Call separable CONV2 on one chunk for 'full' shape.

% Use separable full convolution for all chunks
y = conv2(H1, H2, x, 'full');

% Now work out how much output we should generate
y = iConvnFullStencilCommon(x, y, info);
end


function y = iConvnFullStencilCommon(x, y, info)
% Common code for truncating the output of full convolution for both
% separable and non-separable cases.
if size(x,1) - sum(info.Padding) == 0
    % No data slices - only padding => empty chunk.
    % Reduce y to a zero height keeping all other dims the same.
    colons = repmat({':'}, 1, ndims(y)-1);
    y = y([],colons{:});
    return;
end

if info.IsHead && info.IsTail && sum(info.Padding) == 0
    % Scalar Case, all slices are valid so no indexing required
    return;
end

% A given data slice will contribute to length(B) output slices.  Given
% that the input is provided as:
%
%      x = [headPad; dataSlices; tailPad]
%
% We expect to process each input data slice up to 3 times (always once and
% up to two more times if provided as padding). The upshot is that a given
% output slice can be generated more than once and we need a unique
% assignment rule for determining which slices are valid outputs for the
% given input data slice.  We remove the redundancy by using a "centered
% kernel rule" which amounts to the following indexing rules:
%
% 1) First valid output slice corresponds to centering B on the first
%    data input slice.
% 2) Last valid output slice corresponds to centering B on the last data
%    input slice.
% 3) Augmentation near absolute boundaries: all leading/trailing slices of
%    the absolute head/tail chunk are always valid as these incorporate the
%    builtin zero-padding of conv.

firstDataSliceId = 1 + info.Padding(1);
lastDataSliceId = size(x,1) - info.Padding(2);
fwdWindow = info.Window(2);

if info.IsHead && info.Padding(1) == 0
    % Absolute head
    validOutputIds = 1:(lastDataSliceId+fwdWindow);
elseif info.IsTail && info.Padding(2) == 0
    % Absolute tail
    validOutputIds = (firstDataSliceId+fwdWindow) : size(y,1);
else
    % Body, partial head, or partial tail chunk
    validOutputIds = (firstDataSliceId:lastDataSliceId) + fwdWindow;
end

y = matlab.bigdata.internal.util.indexSlices(y, validOutputIds);
end

function y = iConvnSameStencil(info, x, B)
y = convn(x, B, 'same');
y = iRemovePaddingSlices(y, info.Padding);
end

function y = iConv2SeparableSameStencil(info, x, H1, H2)
y = conv2(H1, H2, x, 'same');
y = iRemovePaddingSlices(y, info.Padding);
end

function y = iRemovePaddingSlices(y, padding)
import matlab.bigdata.internal.util.indexSlices
if any(padding > 0)
    y = indexSlices(y, padding(1) + 1 : size(y,1)-padding(2));
end
end

function C = iSetOutputSize(A, szB, C, shape)
% Try to setup the size of the output based on the sizes of A and B
C.Adaptor = copySizeInformation(C.Adaptor, A.Adaptor);
if strcmpi(shape, 'same')
    % Nothing more to do.
elseif strcmpi(shape, 'full')
    % For full convolution, each dim changes as:
    %    szC == max( max( szA + (szB - 1), szA ), szB )
    % The exceptions to this are when size(A,dim) is zero, whereupon it
    % becomes size(B,dim) and when size(B,dim) is zero, whereupon it
    % becomes size(A,dim).
    for dim=1:numel(szB)
        dimAdjust = max(0, szB(dim)-1);
        C.Adaptor = reduceSizeInDimBy(C.Adaptor, dim, -dimAdjust);
    end
else
    % For valid convolution, each dim changes as:
    %    szC == max( szA - (sB - 1), 0 )
    for dim=1:numel(szB)
        dimAdjust = max(0, szB(dim)-1);
        C.Adaptor = reduceSizeInDimBy(C.Adaptor, dim, dimAdjust);
    end
end
end

function C = iSetOutputType(classA,bIsSingle,C)
% When A or B are of type single, then the output is of type single.
% Otherwise, conv converts inputs to type double and returns type double.

if ~isempty(classA) && strcmpi('single', classA) || bIsSingle
    C = setKnownType(C, 'single');
else
    C = setKnownType(C, 'double');
end
end

function A = iCheckNotEmpty(A, tallInputEmpty)
% Cannot compute full convolution when tall input size is 0x1
if tallInputEmpty
    error(message('MATLAB:bigdata:array:ConvFirstArgCannotBeEmpty'));
end
end
