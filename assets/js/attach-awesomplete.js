/*eslint-env browser*/
/*global Awesomplete, AwesompleteUtil*/
/*exported attachAwesomplete*/

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
    return function(text, inp, item_id) {
      return (itemFun).call(this, text, inp.match(re)[0], item_id);
    }
  }, // end makeItemFun

  makeFilterFun = (filterFun, filterAtStart, re, labelOrDescrAttr, descrSearch) => {
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
        applyThisFilter = function(datValue, inputPart) {
          return AWE.FILTER_STARTSWITH(datValue, inputPart)
              || AWE.FILTER_STARTSWITH(datValue.substring(datValue.lastIndexOf('|') + 1), inputPart);
        }
      } else {
        if (!re) return UTIL.filterStartsWith // do not search in label, search in value
        applyThisFilter = AWE.FILTER_STARTSWITH
      }
    } else if (!filterFun
               || filterFun === UTIL.filterContains
               || filterFun === AWE.FILTER_CONTAINS) {
      if (!re) return UTIL.filterContains // do not search in label, search in value
      applyThisFilter = AWE.FILTER_CONTAINS
    }
    return function(dat, inp) {
      // For simplicity, call enclosed filter with just the text string, not a Suggestion object.
      const inputPart = re ? inp.match(re)[0] : inp;
      // In multiple mode an extra check on minChars is needed; only show suggestions when minChars is reached.
      if (re && this.minChars > 1 && inputPart.trimStart().length < this.minChars) return false;
      return (applyThisFilter).call(this, !labelOrDescrAttr ? dat : dat.value, inputPart);
    }
  }, // end makeFilterFun

  makeDataFun = (dataFun, valueAttr, labelAttr, descrAttr, descrSearch) => {
  // precondition: makeDataFun is only called when valueAttr or dataFun is not null
  let resultDataFun = null;
    if (labelAttr || descrAttr) {
      resultDataFun =
        function(rec, _input) {
          return {
            label: (rec[labelAttr || valueAttr] || '').replace('<p>', '<p >')
                 + (descrAttr ? '<p>' + (rec[descrAttr] || '') : ''),
            value: (rec[valueAttr] || '') +
                   (descrSearch ? '|' + (rec[descrAttr] || '').replace('|', ' ') : '')
          };
        }
    } else if (valueAttr) {
      resultDataFun = function(rec, _input) { return rec[valueAttr] || ''; }
    } else { // dataFun is not null, valueAttr is null
      return dataFun;
    }
    if (!dataFun) return resultDataFun;
    // combine custom function with the above resultDataFun
    return function(rec, input) { return (dataFun).call(this, resultDataFun(rec, input), input); }
  }, // end makeDataFun

  makeConvertInputFun = (convertInputFun, multipleChar) => {
    if (!multipleChar) return convertInputFun;

    // select the text that will be considered to be the current input.
    const rem = new RegExp("[" + multipleChar + "]\\s*$"),
      rel = new RegExp("[^" + multipleChar + "]*$");

    return function(inp) {
      var convInp = inp.replace(rem, '').match(rel)[0].trim().toLowerCase();
      return convertInputFun ? (convertInputFun).call(this, convInp) : convInp;
    }
  }, // end makeConvertInputFun

  attachAwesomplete = (node, customCtx, defaultSettings) => {
    defaultSettings = defaultSettings || {}
    customCtx = customCtx || {}
    const b = node.getAttribute.bind(node)
    , a = function(attr) { return b(attr) || defaultSettings[attr] }
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
    , statusNoResults = a('statusNoResults')
    , statusTypeXChar = a('statusTypeXChar')
    , statusXResults = a('statusXResults')
    , value = a('value')
    , url = a('url')
    , urlEnd = a('urlEnd')

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
    if (convertResponse) opts['convertResponse'] = getCustomFunction(customCtx, convertResponse, 'convertResponse')
    if (ajax) opts['ajax'] = getCustomFunction(customCtx, ajax, 'ajax')
    if (multiple && multiple !== 'false') {
      multipleChar = (multiple === 'true' || multiple === true ? ' ' : multiple)
      separator = (combobox && combobox !== 'false' ? '' : '([' + multipleChar + ']\\s*)?'),
      re = new RegExp('[^' + multipleChar + ']*' + separator + '$')
    }

    const madeConvertInputFun = makeConvertInputFun(convertInputFun, multipleChar)
    , madeFilterFun = makeFilterFun(filterFun, filterAtStart, re, label || descr, isDescrSearch)
    , madeItemFun = makeItemFun(itemFun, filterAtStart, re, isDescrSearch)

    if (madeConvertInputFun) opts['convertInput'] = madeConvertInputFun
    if (madeFilterFun) awesompleteOpts['filter'] = madeFilterFun
    if (madeItemFun) awesompleteOpts['item'] = madeItemFun

    if (minChars) awesompleteOpts['minChars'] = Number(minChars)
    if (maxItems) awesompleteOpts['maxItems'] = Number(maxItems)
    if (autoFirst) awesompleteOpts['autoFirst'] = (autoFirst === 'true' || autoFirst === true)
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
    if (statusNoResults) awesompleteOpts['statusNoResults'] = statusNoResults
    if (statusXResults)  awesompleteOpts['statusXResults']  = statusXResults
    if (statusTypeXChar) awesompleteOpts['statusTypeXChar'] = statusTypeXChar
    if (sort === 'false' || sort === false) {
      awesompleteOpts['sort'] = false  // turn off sorting
    } else if (sort) {
      awesompleteOpts['sort'] = customCtx[sort] || sort
    }

    const aweInstance = UTIL.start('#' + forField,
      opts,
      awesompleteOpts
    )

    if (assign && assign !== 'false') {
      customCtx[assign === 'true' || assign === true ? 'awe_' + forField : assign] = aweInstance
    }

    if (combobox && combobox !== 'false') {
      UTIL.startClick(
        '#' + (combobox === 'true' || combobox === true ? 'awe_btn_' + forField : combobox)
        , aweInstance)
    }

    return aweInstance
  } // end attachAwesomplete

export default attachAwesomplete
