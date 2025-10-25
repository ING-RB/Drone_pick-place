// Copyright 2019-2022 The MathWorks, Inc.

/* eslint-disable no-undef */
(function () {
/*
 * Prevent backspace from navigating to previous page
 */
    function handleEvent (e) {
        if (e.which === 8) { // 8 == backspace
            e.preventDefault();
        }
    }
    document.addEventListener('keydown', handleEvent, false);
    document.addEventListener('keypress', handleEvent, false);
}());
