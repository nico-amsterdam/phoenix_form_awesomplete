
const
// simple expression language evaluator
 // for example search in this for 'a.b.c'
// returns value of searchIn['a']['b']['c']
// throws error if either a, b or c is not found.
  simpleElEval = (searchIn, path) => {
    let result = searchIn, elements = path.split('.')
    for (pathElem of elements) {
        result = result[pathElem]
        if (result === undefined) {
            throw new Error('Could not find ' + pathElem + ' of ' + path)
        }
    }
    return result
  }
, checkIsFunction = (shouldBeFunction, name) => {
    if ('function' !== typeof shouldBeFunction) throw new Error(name + ' is not a function')
    return shouldBeFunction
  }
, attachAwesomplete = (node, bindings) => {
    const a = node.getAttribute.bind(node), fieldID = a('forField')
    , url = a('url'), loadall = a('loadall'), prepop = a('prepop'), minChars = a('minChars')
    , maxItems = a('maxItems'), value = a('value'), combobox = a('combobox')
    , comboSelectID = '#' + (combobox !== 'true' ? combobox : 'awe_btn_' + fieldID)
    , descr = a('descr'), descrSearch = a('descrSearch'), label = a('label')
    , filter = a('filter'), debounce = a('debounce'), list = a('list')
    let opts = {}, awesompleteOpts = {}, listConv
    if (fieldID == null) throw new Error("Missing forField attribute.")
    if (url) opts['url'] = url
    if (loadall) opts['loadall'] = (loadall === 'true')
    if (prepop) opts['prepop'] = (prepop === 'true')
    if (debounce) opts['debounce'] = Number(debounce)
    switch(filter) {
        case null:
        case '':
        break;
        case 'Awesomplete.FILTER_STARTSWITH':
        awesompleteOpts['filter'] = Awesomplete.FILTER_STARTSWITH;
        break;
        case "Awesomplete.FILTER_CONTAINS":
        awesompleteOpts['filter'] = Awesomplete.FILTER_CONTAINS;
        break;
        case "AwesompleteUtil.filterStartsWith":
        awesompleteOpts['filter'] = AwesompleteUtil.filterStartsWith;
        break;
        case "AwesompleteUtil.filterContains":
        awesompleteOpts['filter'] = AwesompleteUtil.filterContains;
        break;
        case "AwesompleteUtil.filterWords":
        awesompleteOpts['filter'] = AwesompleteUtil.filterWords;
        break;
        default:
        awesompleteOpts['filter'] = checkIsFunction(simpleElEval(bindings, filter))
    }
    if (minChars) awesompleteOpts['minChars'] = Number(minChars)
    if (maxItems) awesompleteOpts['maxItems'] = Number(maxItems)
    if (value && descr && descrSearch == 'true') {
        awesompleteOpts['data'] =
        function(rec, input) {
            return {
            label: rec[label || value]+'<p>'+(rec[descr] || ''),
            value: rec[value]+'|'+(rec[descr] || '').replace('|', ' ')
            };
        }
        awesompleteOpts['replace'] =
        function(data) {
            this.input.value = data.value.substring(0, data.value.lastIndexOf('|'));
        }
    } else if (value && descr) {
        awesompleteOpts['data'] =
        function(rec, input) {
            return {
            label: rec[label || value]+'<p>'+(rec[descr] || ''),
            value: rec[value]
            };
        }
    } else if (value && label) {
        awesompleteOpts['data'] =
        function(rec, input) {
            return {
            label: rec[label] || '',
            value: rec[value] || ''
            };
        }
    } else if (value) {
        awesompleteOpts['data'] = function(rec, input) { return rec[value] || ''; }
    }
    if (list) {
        if (/^\s*\[/.test(list)) {
            listConv = list
        } else {
            listConv = simpleElEval(bindings, list)
            if ('function' === typeof listConv) {
                listConv = listConv();
            }
        }
        if ('string' === typeof listConv && /^\s*\[/.test(listConv)) {
            try {
                listConv = JSON.parse(listConv)
            } catch (_e) {
                // convert javascript map to JSON. Works for 80%.
                // Quote all map keys
                // replace single quoted values with double quoted values
                // remove newlines
                listConv = listConv.replace(/\r?\n|\r/g, '').replace(/([{,]\s*)['"]?([a-zA-Z0-9_]+)['"]?\s*:/g, '$1"$2": ').replace(/:\s*'([^,"}\'\]\[\{]*)'/g,':"$1"')
                console.log(listConv)
                listConv = JSON.parse(listConv)
            }
        }
        awesompleteOpts['list'] = listConv
    }
    let awe = AwesompleteUtil.start('#' + fieldID,
        opts,
        awesompleteOpts
    )
    if (combobox && combobox !== 'false') AwesompleteUtil.startClick(comboSelectID, awe)
    }


// module.exports = {
//    attachAwesomplete: attachAwesomplete
// }
export default attachAwesomplete
