function isDone = userLoggedIn(~)
% Do work after user has logged in

% Copyright 2020 The MathWorks, Inc.

    blockSearchLocation = getenv('SL_BLOCK_SEARCH_RESOURCES_PATH');
    if isempty(blockSearchLocation)
        setenv('SL_BLOCK_SEARCH_RESOURCES_PATH', [tempdir 'slonline_db_path/'])
    end

    lbCacheDir = getenv('SL_LB_CACHE_DIR');
    if isempty(lbCacheDir)
        lbCacheDir = [tempdir 'sl_lb_cache'];
        setenv('SL_LB_CACHE_DIR', lbCacheDir);
    end
    [~,~,~] = mkdir(lbCacheDir);

    isDone = true;
end
