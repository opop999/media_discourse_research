function showTree(conllu_text) {
            var trees = [];
            var tree_desc = [];
            var tree_nodes = [];
            // map goes through the whole array, while trimming leading paces
            var lines = ([...conllu_text.split(/\r?\n/)].map((c) => c.trim()));
            lines.push('');
            for (var i in lines) {
                if (lines[i].match(/^(#|\d+-)/)) continue;
                if (lines[i]) {
                    var parts = lines[i].split('\t');
                    for (var i in parts) if (parts[i] == "_") parts[i] = "";
                    if (tree_desc.length) tree_desc.push([' ', 'space']);
                    tree_desc.push([parts[1], 'w' + parts[0]]);
                    if (!tree_nodes.length) tree_nodes.push({ id: 'w0', ord: 0, parent: null, data: { id: "0", form: "<root>" }, labels: ['<root>', '', ''] });
                    tree_nodes.push({
                        id: 'w' + parts[0], ord: tree_nodes.length, parent: parts[6] !== "" ? 'w' + parts[6] : null, data: {
                            id: parts[0], form: parts[1], lemma: parts[2], upostag: parts[3], xpostag: parts[4],
                            feats: parts[5], head: parts[6], deprel: parts[7], deps: parts[8], misc: parts[9]
                        }, labels: [parts[1], '#{#00008b}' + parts[7], '#{#004048}' + parts[3]]
                    });
                } else if (tree_nodes.length) {
                    var last_child = [];
                    for (var i = 1; i < tree_nodes.length; i++) {
                        var head = tree_nodes[i].data.head !== "" ? parseInt(tree_nodes[i].data.head) : "";
                        if (head !== "") {
                            if (!last_child[head]) tree_nodes[head].firstson = 'w' + i;
                            else tree_nodes[last_child[head]].rbrother = 'w' + i;
                            last_child[head] = i;
                        }
                    }

                    trees.push({ desc: tree_desc, zones: { conllu: { trees: { "a": { layer: "a", nodes: tree_nodes } } } } });
                    tree_desc = [];
                    tree_nodes = [];
                }
            }

            jQuery('#vis').treexView(trees);
        }
