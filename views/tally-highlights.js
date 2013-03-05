var toggleState = false;

window.addEventListener('load', function () {

    var button = document.getElementById('highlight-template');

    button.addEventListener ('click', function() {
        var nodes = document.querySelectorAll ('[data-tally-repeat], [data-tally-text], [data-tally-attr], [data-tally-if^="not:"], [data-tally-repeat], [data-tally-if="false"]');
        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i];
            if (!toggleState) {
                node.classList.add('show');
            } else {
                node.classList.remove('show');
            }
        }
        toggleState = !toggleState;
        button.innerHTML = (toggleState ? 'Hide' : 'Show') + ' highlights';
    });
});
