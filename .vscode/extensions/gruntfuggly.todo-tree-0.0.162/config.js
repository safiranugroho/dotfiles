var vscode = require( 'vscode' );
var fs = require( 'fs' );
var path = require( 'path' );

var context;

function init( c )
{
    context = c;
}

function shouldGroup()
{
    return context.workspaceState.get( 'grouped', vscode.workspace.getConfiguration( 'todo-tree.tree' ).get( 'grouped', false ) );
}

function shouldExpand()
{
    return context.workspaceState.get( 'expanded', vscode.workspace.getConfiguration( 'todo-tree.tree' ).get( 'expanded', false ) );
}

function shouldFlatten()
{
    return context.workspaceState.get( 'flat', vscode.workspace.getConfiguration( 'todo-tree.tree' ).get( 'flat', false ) );
}

function shouldShowTagsOnly()
{
    return context.workspaceState.get( 'tagsOnly', vscode.workspace.getConfiguration( 'todo-tree.tree' ).get( 'tagsOnly', false ) );
}

function shouldShowCounts()
{
    return vscode.workspace.getConfiguration( 'todo-tree.tree' ).get( 'showCountsInTree', false );
}

function shouldShowLineNumbers()
{
    return vscode.workspace.getConfiguration( 'todo-tree.tree' ).get( 'showLineNumbersInTree', false );
}

function shouldHideIconsWhenGroupedByTag()
{
    return vscode.workspace.getConfiguration( 'todo-tree.tree' ).get( 'hideIconsWhenGroupedByTag', false );
}

function showFilterCaseSensitive()
{
    return vscode.workspace.getConfiguration( 'todo-tree.tree' ).get( 'filterCaseSensitive', false );
}

function isRegexCaseSensitive()
{
    return vscode.workspace.getConfiguration( 'todo-tree.regex' ).get( 'regexCaseSensitive', true );
}

function showBadges()
{
    return vscode.workspace.getConfiguration( 'todo-tree.tree' ).get( 'showBadges', false );
}

function regex()
{
    return {
        tags: tags(),
        regex: vscode.workspace.getConfiguration( 'todo-tree.regex' ).get( 'regex' ),
        caseSensitive: vscode.workspace.getConfiguration( 'todo-tree.regex' ).get( 'regexCaseSensitive' )
    };
}

function ripgrepPath()
{
    function exeName()
    {
        var isWin = /^win/.test( process.platform );
        return isWin ? "rg.exe" : "rg";
    }

    function exePathIsDefined( rgExePath )
    {
        return fs.existsSync( rgExePath ) ? rgExePath : undefined;
    }

    var rgPath = "";

    rgPath = exePathIsDefined( vscode.workspace.getConfiguration( 'todo-tree.ripgrep' ).ripgrep );
    if( rgPath ) return rgPath;

    rgPath = exePathIsDefined( path.join( path.dirname( path.dirname( require.main.filename ) ), "node_modules/vscode-ripgrep/bin/", exeName() ) );
    if( rgPath ) return rgPath;

    rgPath = exePathIsDefined( path.join( path.dirname( path.dirname( require.main.filename ) ), "node_modules.asar.unpacked/vscode-ripgrep/bin/", exeName() ) );
    if( rgPath ) return rgPath;

    return rgPath;
}

function tags()
{
    return vscode.workspace.getConfiguration( 'todo-tree.general' ).tags.sort().reverse();
}

function shouldSortTagsOnlyViewAlphabetically()
{
    return vscode.workspace.getConfiguration( 'todo-tree.tree' ).sortTagsOnlyViewAlphabetically;
}

function labelFormat()
{
    return vscode.workspace.getConfiguration( 'todo-tree.tree' ).labelFormat;
}

function clickingStatusBarShouldRevealTree()
{
    return vscode.workspace.getConfiguration( 'todo-tree.general' ).statusBarClickBehaviour === "reveal";
}

function shouldShowHighlights( scheme )
{
    var schemes = vscode.workspace.getConfiguration( 'todo-tree.highlights' ).schemes;
    return schemes && schemes.length && schemes.indexOf( scheme ) !== -1;
}

function shouldUseBuiltInExcludes()
{
    return vscode.workspace.getConfiguration( 'todo-tree.filtering' ).useBuiltInExcludes;
}

function shouldIgnoreGitSubmodules()
{
    return vscode.workspace.getConfiguration( 'todo-tree.filtering' ).ignoreGitSubmodules;
}

module.exports.init = init;
module.exports.shouldGroup = shouldGroup;
module.exports.shouldExpand = shouldExpand;
module.exports.shouldFlatten = shouldFlatten;
module.exports.shouldShowTagsOnly = shouldShowTagsOnly;
module.exports.shouldShowCounts = shouldShowCounts;
module.exports.shouldShowLineNumbers = shouldShowLineNumbers;
module.exports.shouldHideIconsWhenGroupedByTag = shouldHideIconsWhenGroupedByTag;
module.exports.showFilterCaseSensitive = showFilterCaseSensitive;
module.exports.isRegexCaseSensitive = isRegexCaseSensitive;
module.exports.showBadges = showBadges;
module.exports.regex = regex;
module.exports.ripgrepPath = ripgrepPath;
module.exports.tags = tags;
module.exports.shouldSortTagsOnlyViewAlphabetically = shouldSortTagsOnlyViewAlphabetically;
module.exports.labelFormat = labelFormat;
module.exports.clickingStatusBarShouldRevealTree = clickingStatusBarShouldRevealTree;
module.exports.shouldShowHighlights = shouldShowHighlights;
module.exports.shouldUseBuiltInExcludes = shouldUseBuiltInExcludes;
module.exports.shouldIgnoreGitSubmodules = shouldIgnoreGitSubmodules;