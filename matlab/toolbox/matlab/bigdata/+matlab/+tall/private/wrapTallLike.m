function args = wrapTallLike(args, outputsLike)
% Wrap each argument as a tall array and apply the type information from
% the corresponding outputsLike.

%   Copyright 2018 The MathWorks, Inc.

for ii = 1:numel(args)
    adaptor = matlab.bigdata.internal.adaptors.getAdaptor(outputsLike{ii});
    adaptor = resetTallSize(adaptor);
    adaptor = resetNestedSmallSizes(adaptor);
    args{ii} = tall(args{ii}, adaptor);
end
end
