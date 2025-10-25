function tline = fgetl(fid)
narginchk(1,1)

[tline,lt] = fgets(fid);
tline = tline(1:end-length(lt));
if isempty(tline)
    tline = '';
end

end

% Copyright 1984-2023 The MathWorks, Inc.