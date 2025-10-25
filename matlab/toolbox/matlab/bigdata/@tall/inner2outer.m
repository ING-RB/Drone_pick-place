function b = inner2outer(a)
%INNER2OUTER Invert a nested table-in-table hierarchy.
%   T2 = INNER2OUTER(T1)
%
%   See also TABLE, TALL.

%   Copyright 2018 The MathWorks, Inc.

% Use the in-memory version to do input checking
bProto = tall.validateSyntax(@inner2outer, {a}, 'DefaultType', 'double');

% The merge is actually slice-wise on each partition, but we need to do
% some fancy work to get the adaptors right.
b = slicefun(@inner2outer, a);

% Now fix up the adaptor. For every nested table variable in the output,
% try to find a corresponding input and copy the adaptor.
aAdap = a.Adaptor;
bAdap = copyTallSize(matlab.bigdata.internal.adaptors.getAdaptor(bProto), aAdap);
bAdaps = bAdap.getVariableAdaptors(1:width(bProto));
bOuterNames = bAdap.getVariableNames(1:width(bProto));
for ii=1:numel(bOuterNames)
    outAdap = bAdaps{ii};
        
    if ismember(outAdap.Class, ["table", "timetable"])
        % Nested table, so go through each inner variable
        bInnerNames = outAdap.getVariableNames(1:outAdap.Size(2));
        for jj=1:numel(bInnerNames)
            % Find and copy the corresponding variable in the input, with
            % opposite outer-inner order.
            inOuterAdap = aAdap.getVariableAdaptor(bInnerNames{jj});
            inInnerAdap = inOuterAdap.getVariableAdaptor(bOuterNames{ii});
            outAdap = outAdap.setVariableAdaptor(jj, inInnerAdap);
        end
    else
        % Non-table variables are just copied
        outAdap = aAdap.getVariableAdaptor(bOuterNames{ii});
    end
    bAdap = bAdap.setVariableAdaptor(ii, outAdap);
end

b.Adaptor = bAdap;