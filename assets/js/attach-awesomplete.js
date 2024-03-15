
function makeReplaceFun(replaceFun, multipleChar, descrSearch) {
  const getText = descrSearch ? descrSearchFun : dataValueFun;
  if (multipleChar) {
    const re = new RegExp("^.+[" + multipleChar + "]\\s*|"),
      separator = multipleChar[0] + ' ';
    if ('function' === typeof replaceFun) {
      function replaceMultiFun(data) {
        let text = getText(data);
        (replaceFun)(re.match(this.input.value)[0] + text + separator);
      };
      return replaceMultiFun;
    }
    function replaceMulti(data) {
      let text = getText(data);
      this.input.value = re.match(this.input.value)[0] + text + separator
    };
    return replaceMulti;
  }
  if ('function' === typeof replaceFun) {
    function replaceWithFun(data) {
      replaceFun.call(this, getText(data));
    };
    return replaceWithFun;
  }
  function simpleReplace(data) {
    this.input.value = getText(data);
  };
  return simpleReplace;
}

const
  descrSearchFun = (data) => {
    return data.value.substring(0, data.value.lastIndexOf('|'));
  }
  , dataValueFun = (data) => {
    return data.value;
  }
  , lookupFilterFun = (filter, customCtx) => {
    let filterFun = null, filterAtStart = false;

    switch (filter) {
      case undefined:
      case null:
      case '':
      case "FILTER_CONTAINS":
      case "Awesomplete.FILTER_CONTAINS":
        break;
      case "FILTER_STARTSWITH":
      case "Awesomplete.FILTER_STARTSWITH":
        filterFun = Awesomplete.FILTER_STARTSWITH;
        filterAtStart = true;
        break;
      case "filterStartsWith":
      case "AwesompleteUtil.filterStartsWith":
        filterFun = AwesompleteUtil.filterStartsWith;
        filterAtStart = true;
        break;
      case "filterContains":
      case "AwesompleteUtil.filterContains":
        filterFun = AwesompleteUtil.filterContains;
        break;
      case "filterWords":
      case "AwesompleteUtil.filterWords":
        filterFun = AwesompleteUtil.filterWords;
        break;
      case "filterOff":
      case "AwesompleteUtil.filterOff":
        filterFun = AwesompleteUtil.filterOff;
        break;
      default:
        if ('function' === typeof customCtx[filter]) filterFun = customCtx[filter]
        else throw new Error('Unknown filter ' + filter)
    }
    return { filterFun, filterAtStart }
  }
  , lookupItemFun = (item, customCtx) => {
    let itemFun = null
    switch (item) {
      case undefined:
      case null:
      case "":
        break;
      case "item":
      case "AwesompleteUtil.item":
        itemFun = AwesompleteUtil.item;
        break;
      case "itemStartsWith":
      case "AwesompleteUtil.itemStartsWith":
        itemFun = AwesompleteUtil.itemStartsWith;
        break;
      case "itemContains":
      case "AwesompleteUtil.itemContains":
        itemFun = AwesompleteUtil.itemContains;
        break;
      case "itemMarkAll":
      case "AwesompleteUtil.itemMarkAll":
        itemFun = AwesompleteUtil.itemMarkAll;
        break;
      case "itemWords":
      case "AwesompleteUtil.itemWords":
        itemFun = AwesompleteUtil.itemWords;
        break;
      default:
        if ('function' === typeof customCtx[item]) itemFun = customCtx[item]
        else throw new Error('Unknown item ' + item)
    }
    return itemFun
  }
  , makeItemFun = (item, filterFun, filterAtStart, multipleChar, combobox, valueAttr, labelAttr, descrAttr, descrSearch, customCtx) => {
    let itemFun = lookupItemFun(item, customCtx)

    if (!multipleChar) {

      if (itemFun) return itemFun;
      if (descrSearch) return AwesompleteUtil.itemMarkAll;
      if (filterAtStart) return AwesompleteUtil.itemStartsWith;
      return null; // defaults to itemContains

    } else { // multipleChar

      const fileSep = (combobox && combobox !== 'false' ? '' : '([#{' + multipleChar + '}]\\s*)?'),
        re = new RegExp('[^' + multipleChar + ']*' + fileSep + '$')

      if (!itemFun) {
        // else blocks will fill itemFun.
      } else if (descrSearch) { //
        itemFun = AwesompleteUtil.itemMarkAll;
      } else if (filterAtStart) {
        itemFun = AwesompleteUtil.itemStartsWith;
      } else {
        itemFun = AwesompleteUtil.itemContains;
      }

      function itemMultipleFun(text, inp) {
        return (itemFun)(text, re.match(inp)[0]);
      }
      return itemMultipleFun;
    }
  }
  , makeFilterFun = (filterFun, filterAtStart, multipleChar, combobox, valueAttr, labelAttr, descrAttr) => {
    // Label/descr without value attr is not allowed.
    // When there is a label or a descr, a data function which returns value+label will be used.
    const hasOnlyData = !valueAttr || (!labelAttr && !descrAttr);

    if (!multipleChar) {

      if (!filterFun && hasOnlyData) return filterFun; // null
      if (!filterFun || filterFun === AwesompleteUtil.filterContains) return AwesompleteUtil.filterContains;
      if (hasOnlyData) return filterFun; // custom filter

      if (!labelAttr && !descrAttr && filterFun === Awesomplete.FILTER_STARTSWITH) {
        return filterFun;
      }
      if (filterAtStart) {
        if (descrSearch) {

          // description search i.c.w. start-with filter needs special threatment
          // to search at the beginning in both value and description.
          const startsWithFilterFun = function (dat, inp) {
            return AwesompleteUtil.filterStartsWith(dat, inp)
              || Awesomplete.FILTER_STARTSWITH(dat.value.substring(dat.value.lastIndexOf('|') + 1), inp);
          }
          return startsWithFilterFun
        }
        return AwesompleteUtil.filterStartsWith;
      }

      // it's not contains or startsWith.
      return function (dat, inp) { return (filterFun)(dat.value, inp); }

    } else { // multipleChar

      const fileSep = (combobox && combobox !== 'false' ? '' : '([#{' + multipleChar + '}]\\s*)?')
      const re = new RegExp('[^' + multipleChar + ']*' + fileSep + '$')
      let applyThisFilter = filterFun;
      if (filterAtStart) {

        // description search i.c.m. with start-with filter needs special threatment
        // to search at the beginning in both value and description.
        if (descrSearch) {
          const startsWithFilterFun = function (dat, inp) {
            var inputPart = re.match(inp)[0]
            return AwesompleteUtil.filterStartsWith(dat, inputPart)
              || Awesomplete.FILTER_STARTSWITH(dat.value.substring(dat.value.lastIndexOf('|') + 1), inputPart);
          }
          return startsWithFilterFun
        }

        applyThisFilter = Awesomplete.FILTER_STARTSWITH;
      } else if (!filterFun) {
        applyThisFilter = Awesomplete.FILTER_CONTAINS;
      }

      const lastPartSearchFun = function (dat, inp) {
        return (filterFun)(hasOnlyData ? dat : dat.value, re.match(inp)[0]);
      }
      return lastPartSearchFun;
    } // end multipleChar

  } // end makeFilterFun
  , makeDataFun = (customCtx, data, valueAttr, labelAttr, descrAttr, descrSearch) => {
    let data_fun = null;
    const labelOrValue = labelAttr || valueAttr
    if (descrAttr && descrSearch) {
      data_fun =
        function (rec, input) {
          return {
            label: (rec[labelOrValue] || '').replace('<p>', '<p >')
              + '<p>' + (rec[descrAttr] || ''),
            value: (rec[valueAttr] || '') + '|'
              + (rec[descrAttr] || '').replace('|', ' ')
          };
        }
    } else if (descrAttr) {
      data_fun =
        function (rec, input) {
          return {
            label: (rec[labelOrValue] || '').replace('<p>', '<p >')
              + '<p>' + (rec[descrAttr] || ''),
            value: rec[valueAttr] || ''
          };
        }
    } else if (labelAttr) {
      data_fun =
        function (rec, input) {
          return {
            label: (rec[labelAttr] || '').replace('<p>', '<p >'),
            value: rec[valueAttr] || ''
          };
        }
    } else {
      data_fun = function (rec, input) { return rec[valueAttr] || ''; }
    }
    if (!data) return data_fun;
    if ('function' !== typeof customCtx[data]) throw new Error('Unknown data function ' + data)
    let customDataFun = customCtx[data]
    return function (rec, input) { return (customDataFun)(data_fun(rec, input), input); }
  }
  , makeConvertInput = (convertInput, multipleChar, customCtx) => {
    let convertInputFun = null;
    if (convertInput) {
      if ('function' !== typeof customCtx[convertInput]) throw new Error('Unknown convertInput function ' + convertInput)
      convertInputFun = customCtx[convertInput]
    }
    if (!multipleChar) return convertInputFun;

    // select the text that will be considered to be the current input.
    const rem = new RegExp("^.+[" + multipleChar + "]\\s*|"),
      rel = new RegExp("[^" + multipleChar + "]*$");

    let convertMultipleInputFun;
    if (!convertInput) {
      convertMultipleInputFun = function (inp) { return inp.replace(rem, '').match(rel)[0].trim().toLowerCase(); }
    } else {
      convertMultipleInputFun = function (inp) { return (convertInputFun)(inp.replace(rem, '').match(rel)[0].trim().toLowerCase()); }
    }
    return convertMultipleInputFun;
  }
  , attachAwesomplete = (node, customCtx /* bindings */) => {
    const a = node.getAttribute.bind(node), fieldID = a('forField');
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
    let opts = {}, awesompleteOpts = {}, replaceFun, multipleChar = null;
    if (url) opts['url'] = url
    if (urlEnd) opts['urlEnd'] = urlEnd
    if (urlEnd && 'function' === typeof customCtx[urlEnd]) opts['urlEnd'] = customCtx[urlEnd]
    if (loadall) opts['loadall'] = (loadall === 'true' || loadall === true)
    if (prepop) opts['prepop'] = (prepop === 'true' || prepop === true)
    if (debounce) opts['debounce'] = Number(debounce)
    if (limit) opts['limit'] = Number(limit)
    if (convertResponse) {
      if ('function' !== typeof customCtx[convertResponse]) throw new Error('Unknown convertResponse function ' + convertResponse)
      opts['convertResponse'] = customCtx[convertResponse]
    }
    if (!valueAttr && descrAttr) throw new Error("'descr' without 'value' parameter.")
    if (!valueAttr && labelAttr) throw new Error("'label' without 'value' parameter.")
    if (descrSearch && !descrAttr) throw new Error('Cannot search description texts without knowing the description field. Please supply descr parameter.')
    if (multiple && multiple !== 'false') {
      multipleChar = (multiple === 'true' || multiple === true ? ' ' : multiple);
    }

    let { filterFun, filterAtStart } = lookupFilterFun(filter, customCtx)
    const madeFilterFun = makeFilterFun(filterFun, filterAtStart, multipleChar, combobox, valueAttr, labelAttr, descrAttr)
    if (madeFilterFun) awesompleteOpts['filter'] = madeFilterFun;

    const itemFun = makeItemFun(item, filterFun, filterAtStart, multipleChar, combobox, valueAttr, labelAttr, descrAttr, descrSearch, customCtx)
    if (itemFun) awesompleteOpts['item'] = itemFun;

    const convertInputFun = makeConvertInput(convertInput, multipleChar, customCtx)
    if (convertInputFun) {
      opts['convertInput'] = convertInputFun
    }

    if (minChars) awesompleteOpts['minChars'] = Number(minChars)
    if (maxItems) awesompleteOpts['maxItems'] = Number(maxItems)
    if (autoFirst) awesompleteOpts['autoFirst'] = (autoFirst === 'true' || autoFirst === true)
    if (ajax) {
      if ('function' !== typeof customCtx[ajax]) throw new Error('Unknown ajax function ' + ajax)
      awesompleteOpts['ajax'] = customCtx[ajax]
    }
    if (replace) {
      if ('function' !== typeof customCtx[replace]) throw new Error('Unknown replace function ' + replace)
      replaceFun = customCtx[replace];
    }
    if (container) {
      if ('function' !== typeof customCtx[container]) throw new Error('Unknown container function ' + container)
      awesompleteOpts['container'] = customCtx[container]
    }
    if (replace || multipleChar || descrSearch) {
      awesompleteOpts['replace'] = makeReplaceFun(replaceFun, multipleChar, descrSearch)
    }
    if (valueAttr) {
      awesompleteOpts['data'] = makeDataFun(customCtx, data, valueAttr, labelAttr, descrAttr, descrSearch)
    }
    if (list) {
      awesompleteOpts['list'] = customCtx[list] || list
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

  }


// module.exports = {
//    attachAwesomplete: attachAwesomplete
// }
export default attachAwesomplete
