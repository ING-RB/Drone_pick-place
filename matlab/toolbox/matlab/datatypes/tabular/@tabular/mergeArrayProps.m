function a_arrayProps = mergeArrayProps(a_arrayProps,b_arrayProps)
%

% Use b's per-array property values where a's were empty.

%   Copyright 2012-2024 The MathWorks, Inc.

if isempty(a_arrayProps.Description) && ~isempty(b_arrayProps.Description)
    a_arrayProps.Description = b_arrayProps.Description;
end
if isempty(a_arrayProps.UserData) && ~isempty(b_arrayProps.UserData)
    a_arrayProps.UserData = b_arrayProps.UserData;
end
if isempty(a_arrayProps.TableCustomProperties) && ~isempty(b_arrayProps.TableCustomProperties)
    a_arrayProps.TableCustomProperties = b_arrayProps.TableCustomProperties;
else % Merge custom properties structs
    a_arrayProps.TableCustomProperties = mergeNonemptyScalarStructs(a_arrayProps.TableCustomProperties,b_arrayProps.TableCustomProperties);
end
end

function top = mergeNonemptyScalarStructs(top,bot)
% To select the topmost non-empty field from two structs
assert(isscalar(top));
assert(isscalar(bot));
fi = fieldnames(bot);
for j = 1:length(fi)
    fn = fi{j};
    if ~isfield(top,fn) || isempty(top.(fn))
        top.(fn) = bot.(fn);
    end
end
end
