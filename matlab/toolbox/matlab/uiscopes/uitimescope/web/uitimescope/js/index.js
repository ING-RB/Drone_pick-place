define([
    'uitimescope/TimeScope'
], function (
    TimeScope
) {
    return {
        initialize: function (imports) {
            return new Promise((resolve, reject) => {
                resolve({
                    exports: {
                        uitimescope: TimeScope
                    }
                });
            });
        }
    };
});
