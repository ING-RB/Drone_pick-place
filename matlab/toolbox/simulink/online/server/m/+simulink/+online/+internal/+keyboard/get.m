function currLayout = get()

%   Copyright 2021 The MathWorks, Inc.

xkbLayout = slonline.getXKBMapLayout();
xkbVariant = slonline.getXKBMapVariant();

currLayout = xkbLayout;
if ~isempty(xkbVariant)
    currLayout = [currLayout '.' xkbVariant];
end

end