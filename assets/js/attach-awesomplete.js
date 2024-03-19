const
  getCustomFunction = (customCtx, lookupValue, name) => {
    if (lookupValue === null) return null
    if ('function' !== typeof customCtx[lookupValue]) throw new Error('Unknown ' + name + ' function ' + lookupValue)
    return customCtx[lookupValue]
  }, // end getCustomFuncion

  makeReplaceFun = (replaceFun, multipleChar, descrSearch) => {
    var re = null, separator
    if (multipleChar) {
      re = new RegExp("^.+[" + multipleChar + "]\\s*|")
      separator = multipleChar[0] + ' '
    }
    return function(data) {
      var selectedValue = descrSearch ? data.value.substring(0, data.value.lastIndexOf('|')) : data.value,
          replaceText = re ? re.match(this.input.value)[0] + selectedValue + separator : selectedValue
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
        itemFun = AwesompleteUtil.itemMarkAll;
      } else if (filterAtStart) {
        itemFun = AwesompleteUtil.itemStartsWith;
      } else if (re) { // itemContains is the default. No need to specify it when re is null.
        itemFun = AwesompleteUtil.itemContains;
      }
    }
    if (!re) return itemFun;
    return function(text, inp) {
      return (itemFun)(text, re.match(inp)[0]);
    }
  }, // end makeItemFun

  makeFilterFun = (filterFun, filterAtStart, re, valueAttr, labelOrDescrAttr) => {
    // Label/descr without value attr is not allowed.
    // When there is a labelAttr or a descrAttr, a data function
    // which returns value + label will be used. This label might contain HTML, so search in value.
    // Filters are called with a Suggestion, which always has a value and label property,
    // The suggestion toString is used for string conversion. The toString returns: label || value.
    if (!re && !labelOrDescrAttr) return filterFun; // Suggestion label == value
    let applyThisFilter = filterFun;
    if (filterAtStart) {
      if (descrSearch) {
        // description search i.c.w. start-with filter needs special threatment
        // to search at the beginning in both value and description.
        return function(dat, inp) {
          var inputPart = re ? re.match(inp)[0] : inp;
          return AwesompleteUtil.filterStartsWith(dat, inputPart)
            || Awesomplete.FILTER_STARTSWITH(dat.value.substring(dat.value.lastIndexOf('|') + 1), inputPart);
        }
      }
      if (!re) return AwesompleteUtil.filterStartsWith // do not search in label, search in value
      applyThisFilter = Awesomplete.FILTER_STARTSWITH
    } else if (!filterFun
               || filterFun === AwesompleteUtil.filterContains
               || filterFun === Awesomplete.FILTER_CONTAINS) {
      if (!re) return AwesompleteUtil.filterContains // do not search in label, search in value
      applyThisFilter = Awesomplete.FILTER_CONTAINS
    }
    return function(dat, inp) {
      // For simplicity, call enclosed filter with just the text string, not a Suggestion object.
      return (applyThisFilter)(!labelOrDescrAttr ? dat : dat.value, re ? re.match(inp)[0] : inp);
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
    const b = node.getAttribute.bind(node), a = function(attr) { return b(attr) || defaultValues[attr] }, fieldID = a('forField');
    if (fieldID === undefined) throw new Error('Missing forField attribute.')
    const url = a('url'), loadall = a('loadall'), prepop = a('prepop'), minChars = a('minChars')
      , maxItems = a('maxItems'), valueAttr = a('value'), combobox = a('combobox')
      , comboSelectID = '#' + (combobox !== 'true' && combobox !== true ? combobox : 'awe_btn_' + fieldID)
      , descrAttr = a('descr'), descrSearchStr = a('descrSearch'), labelAttr = a('label')
      , filter = a('filter'), debounce = a('debounce')
      , urlEnd = a('urlEnd'), limit = a('limit'), ajax = a('ajax')
      , autoFirst = a('autoFirst'), convertInput = a('convertInput')
      , convertResponse = a('convertResponse'), data = a('data')
      , item = a('item'), assign = a('assign')
      , multiple = a('multiple'), replace = a('replace')
      , descrSearch = (descrSearchStr === 'true' || descrSearchStr === true)
      , list = a('list'), sort = a('sort'), container = a('container')
      , listLabel = a('listLabel')
      , filterFun = getCustomFunction(customCtx, filter, 'filter')
      , replaceFun = getCustomFunction(customCtx, replace, 'replace')
      , dataFun = getCustomFunction(customCtx, data, 'data')
      , itemFun = getCustomFunction(customCtx, item, 'item')
      , convertInputFun = getCustomFunction(customCtx, convertInput, 'convertInput')
      , filterAtStart = (filterFun === Awesomplete.FILTER_STARTSWITH || filterfun === AwesompleteUtil.filterStartsWith)

    let opts = {}, awesompleteOpts = {}, multipleChar = null, separator = null;
    if (url) opts['url'] = url
    if (urlEnd) opts['urlEnd'] = 'function' === typeof customCtx[urlEnd] ? customCtx[urlEnd] : urlEnd
    if (loadall) opts['loadall'] = (loadall === 'true' || loadall === true)
    if (prepop) opts['prepop'] = (prepop === 'true' || prepop === true)
    if (debounce) opts['debounce'] = Number(debounce)
    if (limit) opts['limit'] = Number(limit)
    if (!valueAttr && descrAttr) throw new Error("'descr' without 'value' parameter.")
    if (!valueAttr && labelAttr) throw new Error("'label' without 'value' parameter.")
    if (descrSearch && !descrAttr) throw new Error('Cannot search description texts without knowing the description field. Please supply descr parameter.')
    if (multiple && multiple !== 'false') {
      multipleChar = (multiple === 'true' || multiple === true ? ' ' : multiple)
      separator = (combobox && combobox !== 'false' ? '' : '([' + multipleChar + ']\\s*)?'),
      re = new RegExp('[^' + multipleChar + ']*' + separator + '$')
    }

    if (convertResponse) {
      opts['convertResponse'] = getCustomFunction(customCtx, convertResponse, 'convertResponse')
    }

    const madeFilterFun = makeFilterFun(filterFun, filterAtStart, re, valueAttr, labelAttr || descrAttr)
    if (madeFilterFun) awesompleteOpts['filter'] = madeFilterFun;

    const madeItemFun = makeItemFun(itemFun, filterAtStart, re, descrSearch)
    if (madeItemFun) awesompleteOpts['item'] = madeItemFun;

    const madeConvertInputFun = makeConvertInputFun(convertInputFun, multipleChar)
    if (madeConvertInputFun) opts['convertInput'] = madeConvertInputFun

    if (minChars) awesompleteOpts['minChars'] = Number(minChars)
    if (maxItems) awesompleteOpts['maxItems'] = Number(maxItems)
    if (autoFirst) awesompleteOpts['autoFirst'] = (autoFirst === 'true' || autoFirst === true)
    if (ajax) {
      awesompleteOpts['ajax'] = getCustomFunction(customCtx, ajax, 'ajax')
    }
    if (container) {
      awesompleteOpts['container'] = getCustomFunction(customCtx, container, 'container')
    }
    if (replace || multipleChar || descrSearch) {
      awesompleteOpts['replace'] = makeReplaceFun(replaceFun, multipleChar, descrSearch)
    }
    if (valueAttr || data) {
      awesompleteOpts['data'] = makeDataFun(dataFun, valueAttr, labelAttr, descrAttr, descrSearch)
    }
    if (list) {
      // if list is a function, it will be called (when mounted) and the result will be used.
      // but it can also be an object, array or string array in the customCtx
      // or just a string array
      awesompleteOpts['list'] = ('function' === typeof customCtx[list] ? customCtx[list]() : customCtx[list]) || list
    }
    if (listLabel) {
      awesompleteOpts['listLabel'] = listLabel
    }
    if (sort === 'false' || sort === false) {
      awesompleteOpts['sort'] = false  // turn off sorting
    } else if (sort) {
      awesompleteOpts['sort'] = customCtx[sort] || sort
    }

    let awe = AwesompleteUtil.start('#' + fieldID,
      opts,
      awesompleteOpts
    )
    if (assign) {
      if (assign === 'true' || assign === true) {
        customCtx['awe_' + fieldID] = awe
      } else {
        customCtx[assign] = awe
      }
    }

    if (combobox && combobox !== 'false') AwesompleteUtil.startClick(comboSelectID, awe)

  } // end attachAwesomplete


// module.exports = {
//    attachAwesomplete: attachAwesomplete
// }
export default attachAwesomplete
