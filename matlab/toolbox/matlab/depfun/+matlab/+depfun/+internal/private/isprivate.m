function tf = isprivate(files)
%

%   Copyright 2015-2020 The MathWorks, Inc.

persistent privatePat

if isempty(privatePat)
    privatePat = [ '.+\' filesep 'private\' filesep '.*' ];
end

if ischar(files)
    files = { files };
end

tf = ~cellfun('isempty', regexp(files, privatePat, 'ONCE'));

end
