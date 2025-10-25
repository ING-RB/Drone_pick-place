function values=duplicate_enum_inp_values(varargin)
values=strings(0,0);
for i=1:length(varargin)
values(end+1) = varargin(i);
end


