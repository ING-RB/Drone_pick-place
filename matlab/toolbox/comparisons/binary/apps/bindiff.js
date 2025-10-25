/*
 * bindiff.js
 * Javascript functions to support operations in binary comparison reports
 *
 * Getting the root window is browser dependent.  On some platforms the
 * parent of root is the window, and window.window is window.
 * On other browsers, parent can be undefined.
 *
 * Copyright 2021 The MathWorks, Inc.
 */

/* eslint-disable no-undef */
/* eslint-disable camelcase */
/* eslint-disable no-unused-vars */

function getRootWindow () {
    if (parent) {
        return parent.window;
    } else {
        return window;
    }
}

function showDetailsCallback () {
    getRootWindow().showDetails();
}
