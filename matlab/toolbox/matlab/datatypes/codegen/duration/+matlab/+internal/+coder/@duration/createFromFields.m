function msOut = createFromFields(fields) %#codegen
%CREATEFROMFIELDS Calculate duration millisecond data from raw field data.
%   MS = CREATEFROMFIELDS(FIELDS) calculates millisecond data that can be
%   assigned directly to the 'millis' property of a duration. FIELDS must
%   be a cell array of numeric data.
%
%   MS = CREATEFROMFIELDS({H,MI,S}) returns millisecond data for a
%   duration of H hours, MI minutes, and S seconds.
%
%   MS = CREATEFROMFIELDS({H,MI,S,MS}) returns millisecond data for a
%   duration of H hours, MI minutes, S seconds, and MS milliseconds.

%   Copyright 2014-2020 The MathWorks, Inc.

nonscalarLocation = 1;

for i = 1:length(fields)
    f = fields{i};
    coder.internal.assert(isreal(f),'MATLAB:duration:InputMustBeReal');
    if isscalar(f)
        % OK
    elseif isequal(size(fields{nonscalarLocation}),[1 1])
        nonscalarLocation = i;
    else
        sizematch = isequal(size(f),size(fields{nonscalarLocation}));
        coder.internal.assert(sizematch,'MATLAB:duration:InputSizeMismatch');
    end
end

h = double(fields{1});
m = double(fields{2});
s = double(fields{3});

% Any field can be positive or negative, with any range, have a fractional
% part, or be Inf or NaN.
%ms = full(h*3600000 + m*60000 + s*1000); % s -> ms

hToMs = full(h*3600000);
mToMs = full(m*60000);
sToMs = full(s*1000);

ms1 = bsxfun(@plus,hToMs,mToMs);
ms = bsxfun(@plus,sToMs,ms1);


if length(fields) == 4
    msOut = bsxfun(@plus,ms,double(fields{4}));
else
    msOut = ms;
end
