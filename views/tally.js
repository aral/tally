var toggleState = false

window.addEventListener('load', function () {

    var button = document.getElementById('highlight-template');

    button.addEventListener ('click', function() {
        var nodes = document.querySelectorAll ('[data-qrepeat], [data-qtext], [data-qattr], [data-qif^="not:"], [data-qrepeat], [data-qif="false"]');
        for (var i = 0; i < nodes.length; i++) {
            node = nodes[i];
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
