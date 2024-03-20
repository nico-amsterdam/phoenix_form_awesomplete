const
  UTIL = AwesompleteUtil,
  getCustomFunction = (customCtx, lookupValue, name) => {
    if (lookupValue == null) return null // null or undefined
    if ('function' !== typeof customCtx[lookupValue]) throw new Error('Unknown ' + name + ' function ' + lookupValue)
    return customCtx[lookupValue]
  }, // end getCustomFuncion

  makeReplaceFun = (replaceFun, multipleChar, descrSearch) => {
    var re = null, separator
    if (multipleChar) {
      re = new RegExp("^.+[" + multipleChar + "]\\s*|")
      separator = multipleChar[0]
      if (multipleChar[0] !== ' ') separator += ' '
    }
    return function(data) {
      var selectedValue = descrSearch ? data.value.substring(0, data.value.lastIndexOf('|')) : data.value,
          replaceText = re ? this.input.value.match(re)[0] + selectedValue + separator : selectedValue
      if (replaceFun) {
        (replaceFun).call(this, replaceText)
      } else {
        this.input.value = replaceText
      }
    }
  }, // end makeReplaceFun

  // would be a lot easier if custom itemFun is not combined with multiple
  makeItemFun = (itemFun, filterAtStart, re, descrSearch) => {
    if (!itemFun) {
      if (descrSearch) { //
        itemFun = UTIL.itemMarkAll;
      } else if (filterAtStart) {
        itemFun = UTIL.itemStartsWith;
      } else if (re) { // itemContains is the default. No need to specify it when re is null.
        itemFun = UTIL.itemContains;
      }
    }
    if (!re) return itemFun;
    return function(text, inp) {
      return (itemFun)(text, inp.match(re)[0]);
    }
  }, // end makeItemFun

  makeFilterFun = (filterFun, filterAtStart, re, labelOrDescrAttr) => {
    // Label/descr without value attr is not allowed.
    // When there is a labelAttr or a descrAttr, a data function
    // which returns value + label will be used. This label might contain HTML, so search in value.
    // Filters are called with a Suggestion, which always has a value and label property,
    // The suggestion toString is used for string conversion. The toString returns: label || value.
    if (!re && !labelOrDescrAttr) return filterFun; // Suggestion label == value
    let applyThisFilter = filterFun; 
    const AWE = Awesomplete;
    if (filterAtStart) {
      if (descrSearch) {
        // description search i.c.w. start-with filter needs special threatment
        // to search at the beginning in both value and description.
        return function(dat, inp) {
          var inputPart = re ? inp.match(re)[0] : inp;
          return UTIL.filterStartsWith(dat, inputPart)
            || AWE.FILTER_STARTSWITH(dat.value.substring(dat.value.lastIndexOf('|') + 1), inputPart);
        }
      }
      if (!re) return UTIL.filterStartsWith // do not search in label, search in value
      applyThisFilter = AWE.FILTER_STARTSWITH
    } else if (!filterFun
               || filterFun === UTIL.filterContains
               || filterFun === AWE.FILTER_CONTAINS) {
      if (!re) return UTIL.filterContains // do not search in label, search in value
      applyThisFilter = AWE.FILTER_CONTAINS
    }
    return function(dat, inp) {
      // For simplicity, call enclosed filter with just the text string, not a Suggestion object.
      return (applyThisFilter)(!labelOrDescrAttr ? dat : dat.value, re ? inp.match(re)[0] : inp);
    }
  }, // end makeFilterFun

  // makeDataFun is only called when valueAttr or dataFun is not null
  makeDataFun = (dataFun, valueAttr, labelAttr, descrAttr, descrSearch) => {
    let resultDataFun = null;
    if (labelAttr || descrAttr) {
      resultDataFun =
        function(rec, input) {
          return {
            label: (rec[labelAttr || valueAttr] || '').replace('<p>', '<p >')
                 + (descrAttr ? '<p>' + (rec[descrAttr] || '') : ''),
            value: (rec[valueAttr] || '') +
                   (descrSearch ? '|' + (rec[descrAttr] || '').replace('|', ' ') : '')
          };
        }
    } else if (valueAttr) {
      resultDataFun = function(rec, input) { return rec[valueAttr] || ''; }
    } else { // dataFun is not null, valueAttr is null
      return dataFun;
    }
    if (!dataFun) return resultDataFun;
    // combine custom function with the above resultDataFun
    return function(rec, input) { return (dataFun)(resultDataFun(rec, input), input); }
  }, // end makeDataFun

  makeConvertInputFun = (convertInputFun, multipleChar) => {
    if (!multipleChar) return convertInputFun;

    // select the text that will be considered to be the current input.
    const rem = new RegExp("[" + multipleChar + "]*\\s$"),
      rel = new RegExp("[^" + multipleChar + "]*$");

    return function(inp) {
      var convInp = inp.replace(rem, '').match(rel)[0].trim().toLowerCase();
      return convertInputFun ? (convertInputFun)(convInp) : convInp;
    }
  }, // end makeConvertInputFun

  attachAwesomplete = (node, defaultValues, customCtx) => {
/*
   // somehow this commented out solution is 150 bytes more when minified and gzipped

    const namedNodeMap = node.attributes, settings = {...defaultValues} // make a copy
    // iterate the NamedNodeMap and put everything in settings object, overriding defaultValues.
    for (let i = 0; i < namedNodeMap.length; i++) {
      let nodeItem = namedNodeMap.item(i)
      settings[nodeItem.name] = nodeItem.value // name is always lowercase
    }
    if (settings.forfield === undefined) throw new Error('Missing forField attribute.')
    const { ajax, assign, combobox, container, data, debounce, descr, filter, item, label, limit, list, loadall, multiple, prepop, replace, sort, value, url } = settings
      , autoFirst = settings.autofirst || defaultValues.autoFirst 
      , convertInput = settings.convertinput || defaultValues.convertInput
      , convertResponse = settings.convertresponse || defaultValues.convertResponse
      , descrSearch = settings.descrsearch || defaultValues.descrSearch 
      , forField = settings.forfield || defaultValues.forField
      , listLabel = settings.listlabel || defaultValues.listLabel
      , maxItems = settings.maxitems || defaultValues.maxItems
      , minChars = settings.minchars || defaultValues.minChars
      , urlEnd = settings.urlend || defaultValues.urlEnd
  */
    const b = node.getAttribute.bind(node)
    , a = function(attr) { return b(attr) || defaultValues[attr] }
    , ajax = a('ajax')
    , assign = a('assign')
    , autoFirst = a('autoFirst')
    , combobox = a('combobox')
    , container = a('container')
    , convertInput = a('convertInput')
    , convertResponse = a('convertResponse')
    , data = a('data')
    , debounce = a('debounce')
    , descr = a('descr')
    , descrSearch = a('descrSearch')
    , item = a('item')
    , filter = a('filter')
    , forField = a('forField')
    , label = a('label')
    , limit = a('limit')
    , list = a('list')
    , loadall = a('loadall')
    , listLabel = a('listLabel')
    , maxItems = a('maxItems')
    , minChars = a('minChars')
    , multiple = a('multiple')
    , prepop = a('prepop')
    , replace = a('replace')
    , sort = a('sort')
    , value = a('value')
    , url = a('url')
    , urlEnd = a('urlEnd')

    , comboSelectID = '#' + (combobox !== 'true' && combobox !== true ? combobox : 'awe_btn_' +   forField)
    , convertInputFun = getCustomFunction(customCtx, convertInput, 'convertInput')
    , dataFun = getCustomFunction(customCtx, data, 'data')
    , filterFun = getCustomFunction(customCtx, filter, 'filter')
    , itemFun = getCustomFunction(customCtx, item, 'item')
    , replaceFun = getCustomFunction(customCtx, replace, 'replace')
    , filterAtStart = (filterFun === Awesomplete.FILTER_STARTSWITH || filterFun === UTIL.filterStartsWith)
    , isDescrSearch = (descrSearch === 'true' || descrSearch === true)

    if (forField === undefined) throw new Error('Missing forField attribute.')

    let opts = {}, awesompleteOpts = {}, multipleChar = null, separator = null, re = null;

    if (url) opts['url'] = url
    if (urlEnd) opts['urlEnd'] = 'function' === typeof customCtx[urlEnd] ? customCtx[urlEnd] : urlEnd
    if (loadall) opts['loadall'] = (loadall === 'true' || loadall === true)
    if (prepop) opts['prepop'] = (prepop === 'true' || prepop === true)
    if (debounce) opts['debounce'] = Number(debounce)
    if (limit) opts['limit'] = Number(limit)
    if (!value && descr) throw new Error("'descr' without 'value' parameter.")
    if (!value && label) throw new Error("'label' without 'value' parameter.")
    if (isDescrSearch && !descr) throw new Error('Cannot search description texts without knowing the description field. Please supply descr parameter.')
    if (multiple && multiple !== 'false') {
      multipleChar = (multiple === 'true' || multiple === true ? ' ' : multiple)
      separator = (combobox && combobox !== 'false' ? '' : '([' + multipleChar + ']\\s*)?'),
      re = new RegExp('[^' + multipleChar + ']*' + separator + '$')
    }

    if (convertResponse) opts['convertResponse'] = getCustomFunction(customCtx, convertResponse, 'convertResponse')

    const madeConvertInputFun = makeConvertInputFun(convertInputFun, multipleChar)
    if (madeConvertInputFun) opts['convertInput'] = madeConvertInputFun

    const madeFilterFun = makeFilterFun(filterFun, filterAtStart, re, label || descr)
    if (madeFilterFun) awesompleteOpts['filter'] = madeFilterFun;

    const madeItemFun = makeItemFun(itemFun, filterAtStart, re, isDescrSearch)
    if (madeItemFun) awesompleteOpts['item'] = madeItemFun;
    if (minChars) awesompleteOpts['minChars'] = Number(minChars)
    if (maxItems) awesompleteOpts['maxItems'] = Number(maxItems)
    if (autoFirst) awesompleteOpts['autoFirst'] = (autoFirst === 'true' || autoFirst === true)
    if (ajax) awesompleteOpts['ajax'] = getCustomFunction(customCtx, ajax, 'ajax')
    if (container) awesompleteOpts['container'] = getCustomFunction(customCtx, container, 'container')
    if (replace || multipleChar || isDescrSearch) {
      awesompleteOpts['replace'] = makeReplaceFun(replaceFun, multipleChar, isDescrSearch)
    }
    if (value || data) {
      awesompleteOpts['data'] = makeDataFun(dataFun, value, label, descr, isDescrSearch)
    }
    if (list) {
      // if list is a function, it will be called (when mounted) and the result will be used.
      // but it can also be an object, array or string array in the customCtx
      // or just a string array
      awesompleteOpts['list'] = ('function' === typeof customCtx[list] ? customCtx[list]() : customCtx[list]) || list
    }
    if (listLabel) awesompleteOpts['listLabel'] = listLabel
    if (sort === 'false' || sort === false) {
      awesompleteOpts['sort'] = false  // turn off sorting
    } else if (sort) {
      awesompleteOpts['sort'] = customCtx[sort] || sort
    }

    let awe = UTIL.start('#' + forField,
      opts,
      awesompleteOpts
    )
    if (assign) {
      if (assign === 'true' || assign === true) {
        customCtx['awe_' + forField] = awe
      } else {
        customCtx[assign] = awe
      }
    }

    if (combobox && combobox !== 'false') UTIL.startClick(comboSelectID, awe)

  } // end attachAwesomplete


// module.exports = {
//    attachAwesomplete: attachAwesomplete
// }
export default attachAwesomplete
