/*
 * matdiff.js
 * Javascript functions to support operations in MAT-file comparison reports
 *
 * Getting the root window is browser dependent.  On some platforms the
 * parent of root is the window, and window.window is window.
 * On other browsers, parent can be undefined.
 *
 * Copyright 2010-2021 The MathWorks, Inc.
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

function comparisons_private (args) {
    const rootWindow = getRootWindow();
    return rootWindow.MATLAB.feval('comparisons_private', args, 0);
}

function openvar (side, varname) {
    if (side === 'left') {
        comparisons_private(['matview', LEFT_FILE, varname, '_left']);
    } else {
        comparisons_private(['matview', RIGHT_FILE, varname, '_right']);
    }
}

function mergeleft (varname) {
    comparisons_private(
        ['varmerge', RIGHT_FILE, LEFT_FILE, varname, REPORT_ID]);
}

function mergeright (varname) {
    comparisons_private(
        ['varmerge', LEFT_FILE, RIGHT_FILE, varname, REPORT_ID]);
}

function comparevar (varname) {
    comparisons_private(['varcomp', LEFT_FILE, RIGHT_FILE, varname]);
}
