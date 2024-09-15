/*eslint-env browser*/
/*global Awesomplete*/
/*exported AwesompleteUtil*/

/*
 * Library endorsing Lea Verou's Awesomplete widget, providing:
 * - dynamic remote data loading
 * - labels with HTML markup
 * - events and styling for exact matches
 * - events and styling for mismatches
 * - select item when TAB key is used
 *
 * (c) Nico Hoogervorst
 * License: MIT
 *
 */
var AwesompleteUtil = function() {

    //
    // event names and css classes
    //
    var _AWE = 'awesomplete-',
        _AWE_LOAD = _AWE + 'loadcomplete',
        _AWE_SELECT_COMPLETE = _AWE + 'selectcomplete',
        _AWE_MATCH = _AWE + 'match',
        _AWE_PREPOP = _AWE + 'prepop',
        _AWE_SELECT = _AWE + 'select',
        _CLS_FOUND = 'awe-found',
        _CLS_NOT_FOUND = 'awe-not-found',
        $ = Awesomplete.$; /* shortcut for document.querySelector */

    //
    // private functions
    //

        // Some parts are shamelessly copied from Awesomplete.js like the logic inside this _suggestion function.
        // Returns an object with label and value properties. Data parameter is plain text or Object/Array with label and value.
        function _suggestion(data) {
          var lv = Array.isArray(data)
              ? { label: data[0], value: data[1] }
              : typeof data === "object" && "label" in data && "value" in data ? data : { label: data, value: data };
            return {label: lv.label || lv.value, value: lv.value};
        }

        // Helper to send events with detail property.
        function _fire(target, name, detail) {
          // $.fire uses deprecated methods but other methods don't work in IE11.
          return $.fire(target, name, {detail: detail});
        }

        // Look if there is an exact match or a mismatch, set awe-found, awe-not-found css class and send match events.
        function _matchValue(awe, prepop) {
          var input = awe.input,            /* the input field */
              classList = input.classList,
              utilprops = awe.utilprops,    /* extra properties piggybacked on Awesomplete object */
              selected = utilprops.selected,  /* the exact selected Suggestion with label and value */
              val = utilprops.convertInput.call(awe, input.value),  /* trimmed lowercased value */
              opened = awe.opened,          /* is the suggestion list opened? */
              result = [],                  /* matches with value */
              list = awe._list,             /* current list of suggestions */
              suggestion, fake, rec, j;     /* function scoped variables */
          utilprops.prepop = false;         /* after the first call it's not a prepopulation phase anymore */
          if (list) {                       /* if there is a suggestion list */
            for (j = 0; j < list.length; j++) {  /* loop all suggestions */
              rec = list[j];
              suggestion = _suggestion(awe.data(rec, val));  /* call data convert function */
              // with maxItems = 0 cannot look if suggestion list is opened to determine if there are still matches,
              // instead call the filter method to see if there are still some options.
              if (awe.maxItems === 0) {
                // Awesomplete.FILTER_CONTAINS and Awesomplete.FILTER_STARTSWITH use the toString method.
                suggestion.toString = function() { return '' + this.label; };
                if (awe.filter(suggestion, val)) {
                  // filter returns true, so there is at least one partial match.
                  opened = true;
                }
              }
              // Don't want to change the real input field, emulate a fake one.
              fake = {input: {value: ''}};
              // Determine how this suggestion would look like if it is replaced in the input field,
              // it is an exact match if somebody types exactly that.
              // Use the fake input here. fake.input.value will contain the result of the replace function.
              awe.replace.call(fake, suggestion);
              // Trim and lowercase also the fake input and compare that with the currently typed-in value.
              if (utilprops.convertInput.call(awe, fake.input.value) === val) {
                // This is an exact match. However there might more suggestions with the same value.
                // If the user selected a suggestion from the list, check if this one matches, assuming that
                // value + label is unique (if not it will be difficult for the user to make an informed decision).
                if (selected && selected.value === suggestion.value && selected.label === suggestion.label) {
                  // this surely is the selected one
                  result = [rec];
                  break;
                }
                // add the matching record to the result set.
                result.push(rec);
              } // end if
            } // end loop

            // if the result differs from the previous result
            // if (utilprops.prevSelected !== result) { // is always true
              // if there is an exact match
              if (result.length > 0) {
                // if prepopulation phase (initial/autofill value); not triggered by user input
                if (prepop) {
                  _fire(input, _AWE_PREPOP, result);
                } else if (utilprops.changed) {  /* if input is changed */
                  utilprops.prevSelected = result;  /* new result      */
                  classList.remove(_CLS_NOT_FOUND); /* remove class   */
                  classList.add(_CLS_FOUND);        /* add css class */
                  _fire(input, _AWE_MATCH, result); /* fire event   */
                }
              } else if (prepop) {            /* no exact match, if in prepopulation phase */
                _fire(input, _AWE_PREPOP, []);
              } else if (utilprops.changed) { /* no exact match, if input is changed */
                utilprops.prevSelected = [];
                classList.remove(_CLS_FOUND);
                // Mark as not-found if there are no suggestions anymore or if another field is now active
                if (!opened || (input !== document.activeElement)) {
                   if (val !== '') {
                     classList.add(_CLS_NOT_FOUND);
                     _fire(input, _AWE_MATCH, []);
                   }
                } else {
                  classList.remove(_CLS_NOT_FOUND);
                }
              }
            // }
          }
        }

        // Listen to certain events of THIS awesomplete object to trigger input validation.
        function _match(ev) {
          var awe = this;
          if ((ev.type === _AWE_SELECT_COMPLETE || ev.type === _AWE_LOAD || ev.type === 'blur') && ev.target === awe.input) {
            _matchValue(awe, awe.utilprops.prepop && ev.type === _AWE_LOAD);
          }
        }

        // Select currently selected item if tab or shift-tab key is used.
        function _onKeydown(ev) {
          var awe = this;
          if (ev.target === awe.input && ev.keyCode === 9) { // TAB key
            awe.select(undefined, undefined, ev);       // take current selected item
          }
        }

        // Handle selection event. State changes when an item is selected.
        function _select(ev) {
          var awe = this;
          // cancel previous ajax call if it hasn't started yet.
          clearTimeout(awe.utilprops.timeoutID)
          awe.utilprops.changed = true;      // yes, user made a change
          awe.utilprops.selected = ev.text;  // Suggestion object
        }

        // check if the object is empty {} object
        function _isEmpty(val) {
          return Object.keys(val).length === 0 && val.constructor === Object
        }

        // Need an updated suggestion list if:
        // - There is no result yet, or there is a result but not for the characters we entered
        // - or there might be more specific results because the limit was reached.
        function _ifNeedListUpdate(awe, val, queryVal) {
          var utilprops = awe.utilprops;
          return (!utilprops.listQuery
                   ||
                  (!utilprops.loadall && /* with loadall, if there is a result, there is no need for new lists */
                   val.lastIndexOf(queryVal, 0) === 0 &&
                   (val.lastIndexOf(utilprops.listQuery, 0) !== 0 ||
                     ('number' === typeof utilprops.limit && awe._list.length >= utilprops.limit))));
        }

        // Set a new suggestion list. Trigger loadcomplete event.
        function _loadComplete(awe, list, queryVal) {
          awe.list = list;
          awe.utilprops.listQuery = queryVal;
          _fire(awe.input, _AWE_LOAD, queryVal);
        }

        function _updateList(awe, data, queryVal, forceUpdate) {
          var prop;
          // are we still interested in this response?
          if (forceUpdate || _ifNeedListUpdate(awe, awe.utilprops.val, queryVal)) {
            if ('string' === typeof data) data = JSON.parse(data)
            if (awe.utilprops.convertResponse) data = awe.utilprops.convertResponse.call(awe, data);
            if (!Array.isArray(data)) {
              if (awe.utilprops.limit === 0 || awe.utilprops.limit === 1) {
                // if there is max 1 result expected, the array is not needed.
                // Fur further processing, take the whole result and put it as one element in an array.
                data = _isEmpty(data) ? [] : [data]
              } else {
                // search for the first property that contains an array
                for (prop in data) {
                  if (Array.isArray(data[prop])) {
                    data = data[prop];
                    break;
                  }
                }
              }
            }
            // can only handle arrays
            if (Array.isArray(data)) {
              // accept the new suggestion list
              _loadComplete(awe, data, queryVal || awe.utilprops.loadall);
            }
          }
          return awe;
        }

        // Handle ajax response. Expects HTTP OK (200) response with JSON object with suggestion(s) (array).
        function _onLoad() {
          var t = this,
              awe = t.awe,
              xhr = t.xhr,
              queryVal = t.queryVal;
          if (xhr.status === 200) {
            _updateList(awe, xhr.responseText, queryVal, false);
          }
        }

        function _ajax(awe, val) {
          var xhr = new XMLHttpRequest();
          awe.utilprops.ajax.call(awe,
                              awe.utilprops.url,
                              awe.utilprops.urlEnd,
                              awe.utilprops.loadall ? '' : val,
                              _onLoad.bind({awe: awe, xhr: xhr, queryVal: val}),
                              xhr
                            );
        }

        // Perform suggestion list lookup for the current value and validate. Use ajax when there is an url specified.
        // Optional debounce parameter in milliseconds.
        function _lookup(awe, val, debounce) {
          if (awe.utilprops.url) {
            // are we still interested in this response?
            if (_ifNeedListUpdate(awe, val, val)) {
              if ('number' === typeof debounce && debounce > 0) {
                // start ajax call after debounce value in milleseconds
                awe.utilprops.timeoutID = setTimeout(_ajax.bind(null, awe, val), debounce)
              } else {
                // call ajax instantly
               _ajax(awe, val)
              }
            } else {
              _matchValue(awe, awe.utilprops.prepop);
            }
          } else {
            _matchValue(awe, awe.utilprops.prepop);
          }
        }

        // Restart autocomplete search: clear css classes and send match-event with empty list.
        function _restart(awe) {
          var elem = awe.input, classList = elem.classList;
          // IE11 only handles the first parameter of the remove method.
          classList.remove(_CLS_NOT_FOUND);
          classList.remove(_CLS_FOUND);
          _fire(elem, _AWE_MATCH, []);
        }

        // handle new input value
        function _update(awe, val, prepop) {
          // prepop parameter is optional. Default value is false.
          awe.utilprops.prepop = prepop || false;
          // if value changed
          if (awe.utilprops.val !== val) {
            // cancel previous ajax call if it hasn't started yet.
            clearTimeout(awe.utilprops.timeoutID)
            // new value, clear previous selection
            awe.utilprops.selected = null;
            // yes, user made a change
            awe.utilprops.changed = true;
            awe.utilprops.val = val;
            // value is empty or smaller than minChars
            if (val === '' || val.length < awe.minChars) {
              // restart autocomplete search
              _restart(awe);
            }
            if (val.length >= awe.minChars) {
              // lookup suggestions and validate input
              _lookup(awe, val, awe.utilprops.debounce);
            }
          }
          return awe;
        }

        // handle input changed event for THIS awesomplete object
        function _onInput(e) {
          var awe = this,
              val;
          if (e.target === awe.input) {
            // lowercase and trim input value
            val = awe.utilprops.convertInput.call(awe, awe.input.value);
            _update(awe, val);
          }
        }

        // item function (as specified in Awesomplete) which just creates the 'li' HTML tag.
        function _item(html, input, item_id) {
          return $.create('li', {
            innerHTML: html,
            'role': 'option',
            'aria-selected': 'false',
            'tabindex': '-1', // for the Talkback screen reader
            'id': 'awesomplete_list_' + this.count + '_item_' + item_id // for aria-activedescendant on the input element
          });
        }

        // Escape HTML characters in text.
        function _htmlEscape(text) {
          return text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;');
        }

        // Function to copy a field from the selected autocomplete item to another DOM element.
        function _copyFun(e) {
          var t = this,
              sourceId  = t.sourceId,
              dataField = t.dataField,
              targetId  = t.targetId,
              elem,
              val;
          if (e.target === $(sourceId)) {
            if ('function' === typeof targetId) {
              targetId(e, dataField);
            } else {
              // lookup target element if it isn't resolved yet
              elem = $(targetId);
              // don't override target inputs if user is currently editing it.
              if (elem && elem !== document.activeElement) {
                // event must contain 1 item from suggestion list
                val = Array.isArray(e.detail) && e.detail.length === 1 ? e.detail[0] : null;
                // if a datafield is specified, take that value
                val = (dataField && val ? val[dataField] : val) || '';
                // if it is an input control
                if ('undefined' !== typeof elem.value) {
                  // set new value
                  elem.value = val;
                  // not really sure if it is an input control, check if it has a classList
                  if (elem.classList && elem.classList.remove) {
                    // it might be another awesomplete control, if so the input is not wrong anymore because it's changed now
                    elem.classList.remove(_CLS_NOT_FOUND);
                  }
                } else if ('undefined' !== typeof elem.src) {  /* is it an image tag? */
                  elem.src = val;
                } else {
                  // use innerHTML to set the new value, because value might intentionally contain HTML markup
                  elem.innerHTML = val;
                }
              }
            }
          }
        }

        // click function for the combobox button
        function _clickFun(e) {
          var t = this,
              awe,
              minChars;
          if (e.target === $(t.btnId)) {
            e.preventDefault();
            awe = t.awe;
            // toggle open/close
            if (awe.ul.childNodes.length === 0 || awe.ul.hasAttribute('hidden')) {
              minChars = awe.minChars;
              // ignore that the input value is empty
              awe.minChars = 0;
              // show the suggestion list
              awe.evaluate();
              awe.minChars = minChars;
            } else {
              awe.close();
            }
          }
        }

        // Return text with mark tags arround matching input. Don't replace inside <HTML> tags.
        // When startsWith is true, mark only the matching begin text.
        function _mark(text, input, startsWith) {
          var searchText = $.regExpEscape(_htmlEscape(input).trim()),
              regExp = searchText === '' ? null : startsWith ? RegExp('^' + searchText, 'i') : RegExp('(?!<[^>]+?>)' + searchText + '(?![^<]*?>)', 'gi');
          return text.replace(regExp, '<mark>$&</mark>');
        }

        // Recursive jsonFlatten function
        function _jsonFlatten(result, cur, prop, level, opts) {
          var root = opts.root,  /* filter resulting json tree on root property (optional) */
              value = opts.value, /* search for this property and copy it's value to a new 'value' property
                                     (optional, do not specify it if the json array contains plain strings) */
              label = opts.label || opts.value, /* search this property and copy it's value to a new 'label' property.
                                     If there is a 'opts.value' field but no 'opts.label', assume label is the same. */
              isEmpty = true, arrayResult = [], j;
          // at top level, look if there is a property which starts with root (if specified)
          if (level === 0 && root && prop && (prop + '.').lastIndexOf(root + '.', 0) !== 0 && (root + '.').lastIndexOf(prop + '.', 0) !== 0) {
            return result;
          }
          // handle current part of the json tree
          if (Object(cur) !== cur) {
            if (prop) {
              result[prop] = cur;
            } else {
              result = cur;
            }
          } else if (Array.isArray(cur)) {
            for (j = 0; j < cur.length; j++) {
              arrayResult.push(_jsonFlatten({}, cur[j], '', level + 1, opts));
            }
            if (prop) {
              result[prop] = arrayResult;
            } else {
              result = arrayResult;
            }
          } else {
            for (j in cur) {
              isEmpty = false;
              _jsonFlatten(result, cur[j], prop ? prop + '.' + j : j, level, opts);
            }
            if (isEmpty && prop) result[prop] = {};
          }
          // for arrays at top and subtop level
          if (level < 2 && prop) {
            // if a 'value' is specified and found a mathing property, create extra 'value' property.
            if (value && (prop + '.').lastIndexOf(value + '.', 0) === 0) { result['value'] = result[prop]; }
            // if a 'label' is specified and found a mathing property, create extra 'label' property.
            if (label && (prop + '.').lastIndexOf(label + '.', 0) === 0) { result['label'] = result[prop]; }
          }
          if (level === 0) {
            // Make sure that both value and label properties exist, even if they are nil.
            // This is handy with limit 0 or 1 when the result doesn't have to contain an array.
            if (value && !('value' in result)) { result['value'] = null; }
            if (label && !('label' in result)) { result['label'] = null; }
          }
          return result;
        }

        // Stop AwesompleteUtil; detach event handlers from the Awesomplete object.
        function _detach() {
          var t = this,
              elem = t.awe.input,
              boundMatch = t.boundMatch,
              boundOnInput   = t.boundOnInput,
              boundOnKeydown = t.boundOnKeydown,
              boundSelect    = t.boundSelect;

          elem.removeEventListener(_AWE_SELECT, boundSelect);
          elem.removeEventListener(_AWE_LOAD,   boundMatch);
          elem.removeEventListener(_AWE_SELECT_COMPLETE,  boundMatch);
          elem.removeEventListener('blur',      boundMatch);
          elem.removeEventListener('input',     boundOnInput);
          elem.removeEventListener('keydown',   boundOnKeydown);
        }

    //
    // public methods
    //

    return {

        // ajax call for url + val + urlEnd. fn is the callback function. xhr parameter is optional.
        ajax: function(url, urlEnd, val, fn, xhr) {
          var encodedVal = encodeURIComponent(val);
          xhr = xhr || new XMLHttpRequest();
          xhr.open('GET', url + ('function' === typeof urlEnd ? urlEnd(encodedVal) : encodedVal + (urlEnd || '')));
          xhr.onload = fn;
          xhr.send();
          return xhr;
        },

        // Convert input before comparing it with suggestion. lowercase and trim the text
        convertInput: function(text) {
          return 'string' === typeof text ? text.trim().toLowerCase() : '';
        },

        // item function as defined in Awesomplete.
        // item(html, input). input is optional and ignored in this implementation
        item: _item,

        // Set a new suggestion list. Trigger loadcomplete event.
        // load(awesomplete, list, queryValue)
        load: _loadComplete,

        // Return text with mark tags arround matching input. Don't replace inside <HTML> tags.
        // When startsWith is true, mark only the matching begin text.
        // mark(text, input, startsWith)
        mark: _mark,

        // highlight items: Marks input in the first line, not in the optional description
        itemContains: function(text, input, item_id) {
          var arr;
          if (input.trim() !== '') {
            arr = ('' + text).split(/<p>/);
            arr[0] = _mark(arr[0], input);
            text = arr.join('<p>');
          }
          return _item.call(this, text, input, item_id);
        },

        // highlight items: mark all occurrences of the input text
        itemMarkAll: function(text, input, item_id) {
          return _item.call(this, input.trim() === '' ? '' + text : _mark('' + text, input), input, item_id);
        },

        // highlight items: mark input in the begin text
        itemStartsWith: function(text, input, item_id) {
          return _item.call(this, input.trim() === '' ? '' + text : _mark('' + text, input, true), input, item_id);
        },

        // highlight items: highlight matching words
        itemWords: function(text, input, item_id) {
          var arr, words = input.split(/\s+/), j;
          if (input.trim() !== '') {
            /* Label contains value and optional extra HTML markup.
               Do not mark text after the first < character */
            arr = ('' + text).split('<');
            /* iterate words */
            for (j = 0; j < words.length; j++) {
              /* highlight word with <mark> </mark> tags */
              arr[0] = _mark(arr[0], words[j]);
            }
            text = arr.join('<');
          }
          return _item.call(this, text, input, item_id);
        },

        // create Awesomplete object for input control elemId. opts are passed unchanged to Awesomplete.
        create: function(elemId, utilOpts, opts) {
          opts.item = opts.item || this.itemContains; /* by default uses itemContains, can be overridden */
          var awe = new Awesomplete(elemId, opts);
          awe.utilprops = utilOpts || {};
          // loadall is true if there is no url (there is a static data-list)
          if (!awe.utilprops.url && 'undefined' === typeof awe.utilprops.loadall) {
            awe.utilprops.loadall = true;
          }
          awe.utilprops.ajax = awe.utilprops.ajax || this.ajax; /* default ajax function can be overridden */
          awe.utilprops.convertInput = awe.utilprops.convertInput || this.convertInput; /* the same applies for convertInput */
          return awe;
        },

        // attach Awesomplete object to event listeners
        attach: function(awe) {
          var elem = awe.input,
              boundMatch = _match.bind(awe),
              boundOnKeydown = _onKeydown.bind(awe),
              boundOnInput   = _onInput.bind(awe),
              boundSelect    = _select.bind(awe),
              boundDetach    = _detach.bind({awe: awe,
                                             boundMatch:     boundMatch,
                                             boundOnInput:   boundOnInput,
                                             boundOnKeydown: boundOnKeydown,
                                             boundSelect:    boundSelect
                                            }),
              events = {
                'keydown': boundOnKeydown,
                'input':   boundOnInput
              };
          events['blur'] = events[_AWE_SELECT_COMPLETE] = events[_AWE_LOAD] = boundMatch;
          events[_AWE_SELECT] = boundSelect;
          $.bind(elem, events);

          awe.utilprops.detach = boundDetach;
          // Perform ajax call if prepop is true and there is an initial input value, or when all values must be loaded (loadall)
          if (awe.utilprops.prepop && (awe.utilprops.loadall || elem.value !== '')) {
            awe.utilprops.val = awe.utilprops.convertInput.call(awe, elem.value);
            _lookup(awe, awe.utilprops.val);
          }
          return awe;
        },

        // update input value via javascript. Use prepop=true when this is an initial/prepopulation value.
        update: function(awe, value, prepop) {
          awe.input.value = value;
          return _update(awe, value, prepop);
        },

        // replace the current list with suggestions with a new list.
        // queryResult should contain an array or an object with an array or a json string.
        // By default forceUpdate is false and it only replaces the list if the queryValue matches the current input value.
        updateList: function(awe, queryResult, queryValue, forceUpdate) {
          return _updateList(awe, queryResult, queryValue, forceUpdate);
        },

        // create and attach Awesomplete object for input control elemId. opts are passed unchanged to Awesomplete.
        start: function(elemId, utilOpts, opts) {
          return this.attach(this.create(elemId, utilOpts, opts));
        },

        // Stop AwesompleteUtil; detach event handlers from the Awesomplete object.
        detach: function(awe) {
          // cancel ajax call if it hasn't started yet.
          clearTimeout(awe.utilprops.timeoutID)
          if (awe.utilprops.detach) {
            awe.utilprops.detach();
            delete awe.utilprops.detach
          }
          return awe;
        },

        // Create function to copy a field from the selected autocomplete item to another DOM element.
        // dataField can be null.
        createCopyFun: function(sourceId, dataField, targetId) {
          return _copyFun.bind({sourceId: sourceId, dataField: dataField, targetId: $(targetId) || targetId});
        },

        // attach copy function to event listeners. prepop is optional and by default true.
        // if true the copy function will also listen to awesomplete-prepop events.
        // The optional listenEl is the element that listens, defaults to document.body.
        attachCopyFun: function(fun, prepop, listenEl) {
          // prepop parameter defaults to true
          prepop = 'boolean' === typeof prepop ? prepop : true;
          listenEl = listenEl || document.body;
          listenEl.addEventListener(_AWE_MATCH, fun);
          if (prepop) listenEl.addEventListener(_AWE_PREPOP, fun);
          return fun;
        },

        // Create and attach copy function.
        startCopy: function(sourceId, dataField, targetId, prepop) {
          var sourceEl = $(sourceId);
          return this.attachCopyFun(this.createCopyFun(sourceEl || sourceId, dataField, targetId), prepop, sourceEl);
        },

        // Stop copy function. Detach it from event listeners.
        // The optional listenEl must be the same element that was used during startCopy/attachCopyFun;
        // in general: Awesomplete.$(sourceId). listenEl defaults to document.body.
        detachCopyFun: function(fun, listenEl) {
          listenEl = listenEl || document.body;
          listenEl.removeEventListener(_AWE_PREPOP, fun);
          listenEl.removeEventListener(_AWE_MATCH, fun);
          return fun;
        },

        // Create function for combobox button (btnId) to toggle dropdown list.
        createClickFun: function(btnId, awe) {
          return _clickFun.bind({btnId: btnId, awe : awe});
        },

        // Attach click function for combobox to click event.
        // The optional listenEl is the element that listens, defaults to document.body.
        attachClickFun: function(fun, listenEl) {
          listenEl = listenEl || document.body;
          listenEl.addEventListener('click', fun);
          return fun;
        },

        // Create and attach click function for combobox button. Toggles open/close of suggestion list.
        startClick: function(btnId, awe) {
          var btnEl = $(btnId);
          return this.attachClickFun(this.createClickFun(btnEl || btnId, awe), btnEl);
        },

        // Stop click function. Detach it from event listeners.
        // The optional listenEl must be the same element that was used during startClick/attachClickFun;
        // in general: Awesomplete.$(btnId). listenEl defaults to document.body.
        detachClickFun: function(fun, listenEl) {
          listenEl = listenEl || document.body;
          listenEl.removeEventListener('click', fun);
          return fun;
        },

        // filter function as specified in Awesomplete. Filters suggestion list on items containing input value.
        // Awesomplete.FILTER_CONTAINS filters on data.label, however
        // this function filters on value and not on the shown label which may contain markup.
        filterContains: function(data, input) {
          return Awesomplete.FILTER_CONTAINS(data.value, input);
        },

        // filter function as specified in Awesomplete. Filters suggestion list on matching begin text.
        // Awesomplete.FILTER_STARTSWITH filters on data.label, however
        // this function filters on value and not on the shown label which may contain markup.
        filterStartsWith: function(data, input) {
          return Awesomplete.FILTER_STARTSWITH(data.value, input);
        },

        // Do not filter; rely on server responses to filter the results.
        filterOff: function(data, input) {
          return true;
        },

        // filter on words without caring about word order.
        // To return true: all words in the input must be found.
        // A word is also a match when a longer word is found which starts with the input word.
        filterWords: function(data, input) {
          var words = input.split(/\s+/), result = true, j;
          data = ' ' + data;
          /* iterate words */
          for (j = 0; result && j < words.length; j++) {
            /* all entered words must be found */
            result = Awesomplete.FILTER_CONTAINS(data, ' ' + words[j]);
          }
          return result;
        },

        // Flatten JSON.
        // { "a":{"b":{"c":[{"d":{"e":1}}]}}} becomes {"a.b.c":[{"d.e":1}]}.
        // This function can be bind to configure it with extra options;
        //   bind({root: '<root path>', value: '<value property>', label: '<label property>'})
        jsonFlatten: function(data) {
          // start json tree recursion
          return _jsonFlatten({}, data, '', 0, this);
        }
    };
}();

// Expose AwesompleteUtil as a CommonJS module
if (typeof module === "object" && module.exports) {
    module.exports = AwesompleteUtil;
}

// Make sure to export AwesompleteUtil on self when in a browser
if (typeof self !== "undefined") {
    self.AwesompleteUtil = AwesompleteUtil;
}
