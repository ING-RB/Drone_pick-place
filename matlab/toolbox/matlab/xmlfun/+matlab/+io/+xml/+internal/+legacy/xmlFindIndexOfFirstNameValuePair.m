function index = xmlFindIndexOfFirstNameValuePair(args)
%

% Copyright 2022-2024 The MathWorks, Inc.
index = -1;
for ii = 1:length(args)
    if ischar(args{ii}) && ~strcmp(args{ii}, '-validating')
        index = ii;
        break;
    end
end

end