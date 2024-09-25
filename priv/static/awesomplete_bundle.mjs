var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));

// vendor/awesomplete.js
var require_awesomplete = __commonJS({
  "vendor/awesomplete.js"(exports, module) {
    (function() {
      var _ = function(input, o) {
        var me = this;
        _.count = (_.count || 0) + 1;
        this.count = _.count;
        this.isOpened = false;
        this.input = $(input);
        this.input.setAttribute("autocomplete", "off");
        this.input.setAttribute("aria-autocomplete", "list");
        this.input.setAttribute("aria-expanded", "false");
        this.input.setAttribute("aria-controls", "awesomplete_list_" + this.count);
        this.input.setAttribute("role", "combobox");
        this.options = o = o || {};
        configure(this, {
          minChars: 2,
          maxItems: 10,
          autoFirst: false,
          data: _.DATA,
          filter: _.FILTER_CONTAINS,
          sort: o.sort === false ? false : _.SORT_BYLENGTH,
          container: _.CONTAINER,
          item: _.ITEM,
          replace: _.REPLACE,
          tabSelect: false,
          listLabel: "Results List",
          statusNoResults: "No results found",
          statusXResults: "{0} results found",
          // uses index placeholder {0}
          statusTypeXChar: "Type {0} or more characters for results"
        }, o);
        this.index = -1;
        this.container = this.container(input);
        this.ul = $.create("ul", {
          hidden: "hidden",
          role: "listbox",
          id: "awesomplete_list_" + this.count,
          inside: this.container,
          "aria-label": this.listLabel
        });
        this.status = $.create("span", {
          className: "visually-hidden",
          role: "status",
          "aria-live": "assertive",
          "aria-atomic": true,
          inside: this.container,
          textContent: ""
          // live region should start empty. Only when the text is changed it will be read by the screen reader.
        });
        this._events = {
          input: {
            "input": this.evaluate.bind(this),
            "blur": this.close.bind(this, { reason: "blur" }),
            "keydown": function(evt) {
              var c = evt.keyCode;
              if (me.opened) {
                if (c === 13 && me.selected) {
                  evt.preventDefault();
                  me.select(void 0, void 0, evt);
                } else if (c === 9 && me.selected && me.tabSelect) {
                  evt.preventDefault();
                  me.select(void 0, void 0, evt);
                } else if (c === 27) {
                  me.close({ reason: "esc" });
                } else if (c === 38 || c === 40) {
                  evt.preventDefault();
                  me[c === 38 ? "previous" : "next"]();
                }
              }
            }
          },
          form: {
            "submit": this.close.bind(this, { reason: "submit" })
          },
          ul: {
            // Prevent the default mousedowm, which ensures the input is not blurred.
            // The actual selection will happen on click. This also ensures dragging the
            // cursor away from the list item will cancel the selection
            "mousedown": function(evt) {
              evt.preventDefault();
            },
            // The click event is fired even if the corresponding mousedown event has called preventDefault
            "click": function(evt) {
              var li = evt.target;
              if (li !== this) {
                while (li && !/li/i.test(li.nodeName)) {
                  li = li.parentNode;
                }
                if (li && evt.button === 0) {
                  evt.preventDefault();
                  me.select(li, evt.target, evt);
                }
              }
            }
          }
        };
        $.bind(this.input, this._events.input);
        $.bind(this.input.form, this._events.form);
        $.bind(this.ul, this._events.ul);
        if (this.input.hasAttribute("list")) {
          this.list = "#" + this.input.getAttribute("list");
          this.input.removeAttribute("list");
        } else {
          this.list = this.input.getAttribute("data-list") || o.list || [];
        }
        _.all.push(this);
      };
      _.prototype = {
        set list(list) {
          if (Array.isArray(list)) {
            this._list = list;
          } else if (typeof list === "string" && list.indexOf(",") > -1) {
            this._list = list.split(/\s*,\s*/);
          } else {
            list = $(list);
            if (list && list.children) {
              var items = [];
              slice.apply(list.children).forEach(function(el) {
                if (!el.disabled) {
                  var text = el.textContent.trim();
                  var value = el.value || text;
                  var label = el.label || text;
                  if (value !== "") {
                    items.push({ label, value });
                  }
                }
              });
              this._list = items;
            }
          }
          if (document.activeElement === this.input) {
            this.evaluate();
          }
        },
        get selected() {
          return this.index > -1;
        },
        get opened() {
          return this.isOpened;
        },
        close: function(o) {
          if (!this.opened) {
            return;
          }
          this.input.setAttribute("aria-expanded", "false");
          this.ul.setAttribute("hidden", "");
          this.isOpened = false;
          this.index = -1;
          this.status.setAttribute("hidden", "");
          this.input.setAttribute("aria-activedescendant", "");
          $.fire(this.input, "awesomplete-close", o || {});
        },
        open: function() {
          this.input.setAttribute("aria-expanded", "true");
          this.ul.removeAttribute("hidden");
          this.isOpened = true;
          this.status.removeAttribute("hidden");
          if (this.autoFirst && this.index === -1) {
            this.goto(0);
          }
          $.fire(this.input, "awesomplete-open");
        },
        destroy: function() {
          $.unbind(this.input, this._events.input);
          $.unbind(this.input.form, this._events.form);
          if (!this.options.container) {
            var parentNode = this.container.parentNode;
            parentNode.insertBefore(this.input, this.container);
            parentNode.removeChild(this.container);
          }
          this.input.removeAttribute("autocomplete");
          this.input.removeAttribute("aria-autocomplete");
          this.input.removeAttribute("aria-expanded");
          this.input.removeAttribute("aria-controls");
          this.input.removeAttribute("role");
          var indexOfAwesomplete = _.all.indexOf(this);
          if (indexOfAwesomplete !== -1) {
            _.all.splice(indexOfAwesomplete, 1);
          }
        },
        next: function() {
          var count = this.ul.children.length;
          this.goto(this.index < count - 1 ? this.index + 1 : count ? 0 : -1);
        },
        previous: function() {
          var count = this.ul.children.length;
          var pos = this.index - 1;
          this.goto(this.selected && pos !== -1 ? pos : count - 1);
        },
        // Should not be used, highlights specific item without any checks!
        goto: function(i) {
          var lis = this.ul.children;
          if (this.selected) {
            lis[this.index].setAttribute("aria-selected", "false");
          }
          this.index = i;
          if (i > -1 && lis.length > 0) {
            lis[i].setAttribute("aria-selected", "true");
            this.input.setAttribute("aria-activedescendant", this.ul.id + "_item_" + this.index);
            this.ul.scrollTop = lis[i].offsetTop - this.ul.clientHeight + lis[i].clientHeight;
            $.fire(this.input, "awesomplete-highlight", {
              text: this.suggestions[this.index]
            });
          }
        },
        select: function(selected, origin, originalEvent) {
          if (selected) {
            this.index = $.siblingIndex(selected);
          } else {
            selected = this.ul.children[this.index];
          }
          if (selected) {
            var suggestion = this.suggestions[this.index];
            var allowed = $.fire(this.input, "awesomplete-select", {
              text: suggestion,
              origin: origin || selected,
              originalEvent
            });
            if (allowed) {
              this.replace(suggestion);
              this.close({ reason: "select" });
              $.fire(this.input, "awesomplete-selectcomplete", {
                text: suggestion,
                originalEvent
              });
            }
          }
        },
        evaluate: function() {
          var me = this;
          var value = this.input.value;
          if (value.length >= this.minChars && this._list && this._list.length > 0) {
            this.index = -1;
            this.ul.innerHTML = "";
            this.suggestions = this._list.map(function(item) {
              return new Suggestion(me.data(item, value));
            }).filter(function(item) {
              return me.filter(item, value);
            });
            if (this.sort !== false) {
              this.suggestions = this.suggestions.sort(this.sort);
            }
            this.suggestions = this.suggestions.slice(0, this.maxItems);
            this.suggestions.forEach(function(text, index) {
              me.ul.appendChild(me.item(text, value, index));
            });
            if (this.ul.children.length === 0) {
              this.status.textContent = this.statusNoResults;
              this.close({ reason: "nomatches" });
            } else {
              this.input.setAttribute("aria-activedescendant", "");
              this.open();
              this.status.textContent = this.statusXResults.replaceAll("{0}", this.ul.children.length);
            }
          } else {
            this.close({ reason: "nomatches" });
            if (this.minChar <= 1 || value.length >= this.minChars) {
              this.status.textContent = this.statusNoResults;
            } else {
              this.status.textContent = this.statusTypeXChar.replaceAll("{0}", this.minChars);
            }
          }
        }
      };
      _.all = [];
      _.FILTER_CONTAINS = function(text, input) {
        return RegExp($.regExpEscape(input.trim()), "i").test(text);
      };
      _.FILTER_STARTSWITH = function(text, input) {
        return RegExp("^" + $.regExpEscape(input.trim()), "i").test(text);
      };
      _.SORT_BYLENGTH = function(a, b) {
        if (a.length !== b.length) {
          return a.length - b.length;
        }
        return a < b ? -1 : 1;
      };
      _.CONTAINER = function(input) {
        return $.create("div", {
          className: "awesomplete",
          around: input
        });
      };
      _.ITEM = function(text, input, item_id) {
        var html = input.trim() === "" ? text : text.replace(RegExp($.regExpEscape(input.trim()), "gi"), "<mark>$&</mark>");
        return $.create("li", {
          innerHTML: html,
          "role": "option",
          "aria-selected": "false",
          "tabindex": "-1",
          // for the Talkback screen reader
          "id": "awesomplete_list_" + this.count + "_item_" + item_id
        });
      };
      _.REPLACE = function(text) {
        this.input.value = text.value;
      };
      _.DATA = function(item) {
        return item;
      };
      function Suggestion(data) {
        var o = Array.isArray(data) ? { label: data[0], value: data[1] } : typeof data === "object" && "label" in data && "value" in data ? data : { label: data, value: data };
        this.label = o.label || o.value;
        this.value = o.value;
      }
      Object.defineProperty(Suggestion.prototype = Object.create(String.prototype), "length", {
        get: function() {
          return this.label.length;
        }
      });
      Suggestion.prototype.toString = Suggestion.prototype.valueOf = function() {
        return "" + this.label;
      };
      function configure(instance, properties, o) {
        for (var i in properties) {
          var initial = properties[i], attrValue = instance.input.getAttribute("data-" + i.toLowerCase());
          if (typeof initial === "number") {
            instance[i] = parseInt(attrValue);
          } else if (initial === false) {
            instance[i] = attrValue !== null;
          } else if (initial instanceof Function) {
            instance[i] = null;
          } else {
            instance[i] = attrValue;
          }
          if (!instance[i] && instance[i] !== 0) {
            instance[i] = i in o ? o[i] : initial;
          }
        }
      }
      var slice = Array.prototype.slice;
      function $(expr, con) {
        return typeof expr === "string" ? (con || document).querySelector(expr) : expr || null;
      }
      function $$(expr, con) {
        return slice.call((con || document).querySelectorAll(expr));
      }
      $.create = function(tag, o) {
        var element = document.createElement(tag);
        for (var i in o) {
          var val = o[i];
          if (i === "inside") {
            $(val).appendChild(element);
          } else if (i === "around") {
            var ref = $(val);
            ref.parentNode.insertBefore(element, ref);
            element.appendChild(ref);
            if (ref.getAttribute("autofocus") != null) {
              ref.focus();
            }
          } else if (i in element) {
            element[i] = val;
          } else {
            element.setAttribute(i, val);
          }
        }
        return element;
      };
      $.bind = function(element, o) {
        if (element) {
          for (var event in o) {
            var callback = o[event];
            event.split(/\s+/).forEach(function(event2) {
              element.addEventListener(event2, callback);
            });
          }
        }
      };
      $.unbind = function(element, o) {
        if (element) {
          for (var event in o) {
            var callback = o[event];
            event.split(/\s+/).forEach(function(event2) {
              element.removeEventListener(event2, callback);
            });
          }
        }
      };
      $.fire = function(target, type, properties) {
        var evt = document.createEvent("HTMLEvents");
        evt.initEvent(type, true, true);
        for (var j in properties) {
          evt[j] = properties[j];
        }
        return target.dispatchEvent(evt);
      };
      $.regExpEscape = function(s) {
        return s.replace(/[-\\^$*+?.()|[\]{}]/g, "\\$&");
      };
      $.siblingIndex = function(el) {
        for (var i = 0; el = el.previousElementSibling; i++)
          ;
        return i;
      };
      function init() {
        $$("input.awesomplete").forEach(function(input) {
          new _(input);
        });
      }
      if (typeof self !== "undefined") {
        self.Awesomplete = _;
      }
      if (typeof Document !== "undefined") {
        if (document.readyState !== "loading") {
          init();
        } else {
          document.addEventListener("DOMContentLoaded", init);
        }
      }
      _.$ = $;
      _.$$ = $$;
      if (typeof module === "object" && module.exports) {
        module.exports = _;
      }
      return _;
    })();
  }
});

// vendor/awesomplete-util.js
var require_awesomplete_util = __commonJS({
  "vendor/awesomplete-util.js"(exports, module) {
    var AwesompleteUtil3 = function() {
      var _AWE = "awesomplete-", _AWE_LOAD = _AWE + "loadcomplete", _AWE_SELECT_COMPLETE = _AWE + "selectcomplete", _AWE_MATCH = _AWE + "match", _AWE_PREPOP = _AWE + "prepop", _AWE_SELECT = _AWE + "select", _CLS_FOUND = "awe-found", _CLS_NOT_FOUND = "awe-not-found", $ = Awesomplete.$;
      function _suggestion(data) {
        var lv = Array.isArray(data) ? { label: data[0], value: data[1] } : typeof data === "object" && "label" in data && "value" in data ? data : { label: data, value: data };
        return { label: lv.label || lv.value, value: lv.value };
      }
      function _fire(target, name, detail) {
        return $.fire(target, name, { detail });
      }
      function _matchValue(awe, prepop) {
        var input = awe.input, classList = input.classList, utilprops = awe.utilprops, selected = utilprops.selected, val = utilprops.convertInput.call(awe, input.value), opened = awe.opened, result = [], list = awe._list, suggestion, fake, rec, j;
        utilprops.prepop = false;
        if (list) {
          for (j = 0; j < list.length; j++) {
            rec = list[j];
            suggestion = _suggestion(awe.data(rec, val));
            if (awe.maxItems === 0) {
              suggestion.toString = function() {
                return "" + this.label;
              };
              if (awe.filter(suggestion, val)) {
                opened = true;
              }
            }
            fake = { input: { value: "" } };
            awe.replace.call(fake, suggestion);
            if (utilprops.convertInput.call(awe, fake.input.value) === val) {
              if (selected && selected.value === suggestion.value && selected.label === suggestion.label) {
                result = [rec];
                break;
              }
              result.push(rec);
            }
          }
          if (result.length > 0) {
            if (prepop) {
              _fire(input, _AWE_PREPOP, result);
            } else if (utilprops.changed) {
              utilprops.prevSelected = result;
              classList.remove(_CLS_NOT_FOUND);
              classList.add(_CLS_FOUND);
              _fire(input, _AWE_MATCH, result);
            }
          } else if (prepop) {
            _fire(input, _AWE_PREPOP, []);
          } else if (utilprops.changed) {
            utilprops.prevSelected = [];
            classList.remove(_CLS_FOUND);
            if (!opened || input !== document.activeElement) {
              if (val !== "") {
                classList.add(_CLS_NOT_FOUND);
                _fire(input, _AWE_MATCH, []);
              }
            } else {
              classList.remove(_CLS_NOT_FOUND);
            }
          }
        }
      }
      function _match(ev) {
        var awe = this;
        if ((ev.type === _AWE_SELECT_COMPLETE || ev.type === _AWE_LOAD || ev.type === "blur") && ev.target === awe.input) {
          _matchValue(awe, awe.utilprops.prepop && ev.type === _AWE_LOAD);
        }
      }
      function _onKeydown(ev) {
        var awe = this;
        if (ev.target === awe.input && ev.keyCode === 9) {
          awe.select(void 0, void 0, ev);
        }
      }
      function _select(ev) {
        var awe = this;
        clearTimeout(awe.utilprops.timeoutID);
        awe.utilprops.changed = true;
        awe.utilprops.selected = ev.text;
      }
      function _isEmpty(val) {
        return Object.keys(val).length === 0 && val.constructor === Object;
      }
      function _ifNeedListUpdate(awe, val, queryVal) {
        var utilprops = awe.utilprops;
        return !utilprops.listQuery || !utilprops.loadall && /* with loadall, if there is a result, there is no need for new lists */
        val.lastIndexOf(queryVal, 0) === 0 && (val.lastIndexOf(utilprops.listQuery, 0) !== 0 || "number" === typeof utilprops.limit && awe._list.length >= utilprops.limit);
      }
      function _loadComplete(awe, list, queryVal) {
        awe.list = list;
        awe.utilprops.listQuery = queryVal;
        _fire(awe.input, _AWE_LOAD, queryVal);
      }
      function _updateList(awe, data, queryVal, forceUpdate) {
        var prop;
        if (forceUpdate || _ifNeedListUpdate(awe, awe.utilprops.val, queryVal)) {
          if ("string" === typeof data)
            data = JSON.parse(data);
          if (awe.utilprops.convertResponse)
            data = awe.utilprops.convertResponse.call(awe, data);
          if (!Array.isArray(data)) {
            if (awe.utilprops.limit === 0 || awe.utilprops.limit === 1) {
              data = _isEmpty(data) ? [] : [data];
            } else {
              for (prop in data) {
                if (Array.isArray(data[prop])) {
                  data = data[prop];
                  break;
                }
              }
            }
          }
          if (Array.isArray(data)) {
            _loadComplete(awe, data, queryVal || awe.utilprops.loadall);
          }
        }
        return awe;
      }
      function _onLoad() {
        var t = this, awe = t.awe, xhr = t.xhr, queryVal = t.queryVal;
        if (xhr.status === 200) {
          _updateList(awe, xhr.responseText, queryVal, false);
        }
      }
      function _ajax(awe, val) {
        var xhr = new XMLHttpRequest();
        awe.utilprops.ajax.call(
          awe,
          awe.utilprops.url,
          awe.utilprops.urlEnd,
          awe.utilprops.loadall ? "" : val,
          _onLoad.bind({ awe, xhr, queryVal: val }),
          xhr
        );
      }
      function _lookup(awe, val, debounce) {
        if (awe.utilprops.url) {
          if (_ifNeedListUpdate(awe, val, val)) {
            if ("number" === typeof debounce && debounce > 0) {
              awe.utilprops.timeoutID = setTimeout(_ajax.bind(null, awe, val), debounce);
            } else {
              _ajax(awe, val);
            }
          } else {
            _matchValue(awe, awe.utilprops.prepop);
          }
        } else {
          _matchValue(awe, awe.utilprops.prepop);
        }
      }
      function _restart(awe) {
        var elem = awe.input, classList = elem.classList;
        classList.remove(_CLS_NOT_FOUND);
        classList.remove(_CLS_FOUND);
        _fire(elem, _AWE_MATCH, []);
      }
      function _update(awe, val, prepop) {
        awe.utilprops.prepop = prepop || false;
        if (awe.utilprops.val !== val) {
          clearTimeout(awe.utilprops.timeoutID);
          awe.utilprops.selected = null;
          awe.utilprops.changed = true;
          awe.utilprops.val = val;
          if (val === "" || val.length < awe.minChars) {
            _restart(awe);
          }
          if (val.length >= awe.minChars) {
            _lookup(awe, val, awe.utilprops.debounce);
          }
        }
        return awe;
      }
      function _onInput(e) {
        var awe = this, val;
        if (e.target === awe.input) {
          val = awe.utilprops.convertInput.call(awe, awe.input.value);
          _update(awe, val);
        }
      }
      function _item(html, input, item_id) {
        return $.create("li", {
          innerHTML: html,
          "role": "option",
          "aria-selected": "false",
          "tabindex": "-1",
          // for the Talkback screen reader
          "id": "awesomplete_list_" + this.count + "_item_" + item_id
          // for aria-activedescendant on the input element
        });
      }
      function _htmlEscape(text) {
        return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
      }
      function _copyFun(e) {
        var t = this, sourceId = t.sourceId, dataField = t.dataField, targetId = t.targetId, elem, val;
        if (e.target === $(sourceId)) {
          if ("function" === typeof targetId) {
            targetId(e, dataField);
          } else {
            elem = $(targetId);
            if (elem && elem !== document.activeElement) {
              val = Array.isArray(e.detail) && e.detail.length === 1 ? e.detail[0] : null;
              val = (dataField && val ? val[dataField] : val) || "";
              if ("undefined" !== typeof elem.value) {
                elem.value = val;
                if (elem.classList && elem.classList.remove) {
                  elem.classList.remove(_CLS_NOT_FOUND);
                }
              } else if ("undefined" !== typeof elem.src) {
                elem.src = val;
              } else {
                elem.innerHTML = val;
              }
            }
          }
        }
      }
      function _clickFun(e) {
        var t = this, awe, minChars;
        if (e.target === $(t.btnId)) {
          e.preventDefault();
          awe = t.awe;
          if (awe.ul.childNodes.length === 0 || awe.ul.hasAttribute("hidden")) {
            minChars = awe.minChars;
            awe.minChars = 0;
            awe.evaluate();
            awe.minChars = minChars;
          } else {
            awe.close();
          }
        }
      }
      function _mark(text, input, startsWith) {
        var searchText = $.regExpEscape(_htmlEscape(input).trim()), regExp = searchText === "" ? null : startsWith ? RegExp("^" + searchText, "i") : RegExp("(?!<[^>]+?>)" + searchText + "(?![^<]*?>)", "gi");
        return text.replace(regExp, "<mark>$&</mark>");
      }
      function _jsonFlatten(result, cur, prop, level, opts) {
        var root = opts.root, value = opts.value, label = opts.label || opts.value, isEmpty = true, arrayResult = [], j;
        if (level === 0 && root && prop && (prop + ".").lastIndexOf(root + ".", 0) !== 0 && (root + ".").lastIndexOf(prop + ".", 0) !== 0) {
          return result;
        }
        if (Object(cur) !== cur) {
          if (prop) {
            result[prop] = cur;
          } else {
            result = cur;
          }
        } else if (Array.isArray(cur)) {
          for (j = 0; j < cur.length; j++) {
            arrayResult.push(_jsonFlatten({}, cur[j], "", level + 1, opts));
          }
          if (prop) {
            result[prop] = arrayResult;
          } else {
            result = arrayResult;
          }
        } else {
          for (j in cur) {
            isEmpty = false;
            _jsonFlatten(result, cur[j], prop ? prop + "." + j : j, level, opts);
          }
          if (isEmpty && prop)
            result[prop] = {};
        }
        if (level < 2 && prop) {
          if (value && (prop + ".").lastIndexOf(value + ".", 0) === 0) {
            result["value"] = result[prop];
          }
          if (label && (prop + ".").lastIndexOf(label + ".", 0) === 0) {
            result["label"] = result[prop];
          }
        }
        if (level === 0) {
          if (value && !("value" in result)) {
            result["value"] = null;
          }
          if (label && !("label" in result)) {
            result["label"] = null;
          }
        }
        return result;
      }
      function _detach() {
        var t = this, elem = t.awe.input, boundMatch = t.boundMatch, boundOnInput = t.boundOnInput, boundOnKeydown = t.boundOnKeydown, boundSelect = t.boundSelect;
        elem.removeEventListener(_AWE_SELECT, boundSelect);
        elem.removeEventListener(_AWE_LOAD, boundMatch);
        elem.removeEventListener(_AWE_SELECT_COMPLETE, boundMatch);
        elem.removeEventListener("blur", boundMatch);
        elem.removeEventListener("input", boundOnInput);
        elem.removeEventListener("keydown", boundOnKeydown);
      }
      return {
        // ajax call for url + val + urlEnd. fn is the callback function. xhr parameter is optional.
        ajax: function(url, urlEnd, val, fn, xhr) {
          var encodedVal = encodeURIComponent(val);
          xhr = xhr || new XMLHttpRequest();
          xhr.open("GET", url + ("function" === typeof urlEnd ? urlEnd(encodedVal) : encodedVal + (urlEnd || "")));
          xhr.onload = fn;
          xhr.send();
          return xhr;
        },
        // Convert input before comparing it with suggestion. lowercase and trim the text
        convertInput: function(text) {
          return "string" === typeof text ? text.trim().toLowerCase() : "";
        },
        // item function as defined in Awesomplete, but without mark tags.
        // item(html, input, item_id). input is ignored in this implementation
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
          if (input.trim() !== "") {
            arr = ("" + text).split(/<p>/);
            arr[0] = _mark(arr[0], input);
            text = arr.join("<p>");
          }
          return _item.call(this, text, input, item_id);
        },
        // highlight items: mark all occurrences of the input text
        itemMarkAll: function(text, input, item_id) {
          return _item.call(this, input.trim() === "" ? "" + text : _mark("" + text, input), input, item_id);
        },
        // highlight items: mark input in the begin text
        itemStartsWith: function(text, input, item_id) {
          return _item.call(this, input.trim() === "" ? "" + text : _mark("" + text, input, true), input, item_id);
        },
        // highlight items: highlight matching words
        itemWords: function(text, input, item_id) {
          var arr, words = input.split(/\s+/), j;
          if (input.trim() !== "") {
            arr = ("" + text).split("<");
            for (j = 0; j < words.length; j++) {
              arr[0] = _mark(arr[0], words[j]);
            }
            text = arr.join("<");
          }
          return _item.call(this, text, input, item_id);
        },
        // create Awesomplete object for input control elemId. opts are passed unchanged to Awesomplete.
        create: function(elemId, utilOpts, opts) {
          opts.item = opts.item || this.itemContains;
          var awe = new Awesomplete(elemId, opts);
          awe.utilprops = utilOpts || {};
          if (!awe.utilprops.url && "undefined" === typeof awe.utilprops.loadall) {
            awe.utilprops.loadall = true;
          }
          awe.utilprops.ajax = awe.utilprops.ajax || this.ajax;
          awe.utilprops.convertInput = awe.utilprops.convertInput || this.convertInput;
          return awe;
        },
        // attach Awesomplete object to event listeners
        attach: function(awe) {
          var elem = awe.input, boundMatch = _match.bind(awe), boundOnKeydown = _onKeydown.bind(awe), boundOnInput = _onInput.bind(awe), boundSelect = _select.bind(awe), boundDetach = _detach.bind({
            awe,
            boundMatch,
            boundOnInput,
            boundOnKeydown,
            boundSelect
          }), events = {
            "keydown": boundOnKeydown,
            "input": boundOnInput
          };
          events["blur"] = events[_AWE_SELECT_COMPLETE] = events[_AWE_LOAD] = boundMatch;
          events[_AWE_SELECT] = boundSelect;
          $.bind(elem, events);
          awe.utilprops.detach = boundDetach;
          if (awe.utilprops.prepop && (awe.utilprops.loadall || elem.value !== "")) {
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
          clearTimeout(awe.utilprops.timeoutID);
          if (awe.utilprops.detach) {
            awe.utilprops.detach();
            delete awe.utilprops.detach;
          }
          return awe;
        },
        // Create function to copy a field from the selected autocomplete item to another DOM element.
        // dataField can be null.
        createCopyFun: function(sourceId, dataField, targetId) {
          return _copyFun.bind({ sourceId, dataField, targetId: $(targetId) || targetId });
        },
        // attach copy function to event listeners. prepop is optional and by default true.
        // if true the copy function will also listen to awesomplete-prepop events.
        // The optional listenEl is the element that listens, defaults to document.body.
        attachCopyFun: function(fun, prepop, listenEl) {
          prepop = "boolean" === typeof prepop ? prepop : true;
          listenEl = listenEl || document.body;
          listenEl.addEventListener(_AWE_MATCH, fun);
          if (prepop)
            listenEl.addEventListener(_AWE_PREPOP, fun);
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
          return _clickFun.bind({ btnId, awe });
        },
        // Attach click function for combobox to click event.
        // The optional listenEl is the element that listens, defaults to document.body.
        attachClickFun: function(fun, listenEl) {
          listenEl = listenEl || document.body;
          listenEl.addEventListener("click", fun);
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
          listenEl.removeEventListener("click", fun);
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
        filterOff: function(_data, _input) {
          return true;
        },
        // filter on words without caring about word order.
        // To return true: all words in the input must be found.
        // A word is also a match when a longer word is found which starts with the input word.
        filterWords: function(data, input) {
          var words = input.split(/\s+/), result = true, j;
          data = " " + data;
          for (j = 0; result && j < words.length; j++) {
            result = Awesomplete.FILTER_CONTAINS(data, " " + words[j]);
          }
          return result;
        },
        // Flatten JSON.
        // { "a":{"b":{"c":[{"d":{"e":1}}]}}} becomes {"a.b.c":[{"d.e":1}]}.
        // This function can be bind to configure it with extra options;
        //   bind({root: '<root path>', value: '<value property>', label: '<label property>'})
        jsonFlatten: function(data) {
          return _jsonFlatten({}, data, "", 0, this);
        }
      };
    }();
    if (typeof module === "object" && module.exports) {
      module.exports = AwesompleteUtil3;
    }
    if (typeof self !== "undefined") {
      self.AwesompleteUtil = AwesompleteUtil3;
    }
  }
});

// js/index.js
var import_awesomplete = __toESM(require_awesomplete());
var import_awesomplete_util = __toESM(require_awesomplete_util());

// js/attach-awesomplete.js
var UTIL = AwesompleteUtil;
var getCustomFunction = (customCtx, lookupValue, name) => {
  if (lookupValue == null)
    return null;
  if ("function" !== typeof customCtx[lookupValue])
    throw new Error("Unknown " + name + " function " + lookupValue);
  return customCtx[lookupValue];
};
var makeReplaceFun = (replaceFun, multipleChar, descrSearch) => {
  var re = null, separator;
  if (multipleChar) {
    re = new RegExp("^.+[" + multipleChar + "]\\s*|");
    separator = multipleChar[0];
    if (multipleChar[0] !== " ")
      separator += " ";
  }
  return function(data) {
    var selectedValue = descrSearch ? data.value.substring(0, data.value.lastIndexOf("|")) : data.value, replaceText = re ? this.input.value.match(re)[0] + selectedValue + separator : selectedValue;
    if (replaceFun) {
      replaceFun.call(this, replaceText);
    } else {
      this.input.value = replaceText;
    }
  };
};
var makeItemFun = (itemFun, filterAtStart, re, descrSearch) => {
  if (!itemFun) {
    if (descrSearch) {
      itemFun = UTIL.itemMarkAll;
    } else if (filterAtStart) {
      itemFun = UTIL.itemStartsWith;
    } else if (re) {
      itemFun = UTIL.itemContains;
    }
  }
  if (!re)
    return itemFun;
  return function(text, inp, item_id) {
    return itemFun.call(this, text, inp.match(re)[0], item_id);
  };
};
var makeFilterFun = (filterFun, filterAtStart, re, labelOrDescrAttr, descrSearch) => {
  if (!re && !labelOrDescrAttr)
    return filterFun;
  let applyThisFilter = filterFun;
  const AWE = Awesomplete;
  if (filterAtStart) {
    if (descrSearch) {
      applyThisFilter = function(datValue, inputPart) {
        return AWE.FILTER_STARTSWITH(datValue, inputPart) || AWE.FILTER_STARTSWITH(datValue.substring(datValue.lastIndexOf("|") + 1), inputPart);
      };
    } else {
      if (!re)
        return UTIL.filterStartsWith;
      applyThisFilter = AWE.FILTER_STARTSWITH;
    }
  } else if (!filterFun || filterFun === UTIL.filterContains || filterFun === AWE.FILTER_CONTAINS) {
    if (!re)
      return UTIL.filterContains;
    applyThisFilter = AWE.FILTER_CONTAINS;
  }
  return function(dat, inp) {
    const inputPart = re ? inp.match(re)[0] : inp;
    if (re && this.minChars > 1 && inputPart.trimStart().length < this.minChars)
      return false;
    return applyThisFilter.call(this, !labelOrDescrAttr ? dat : dat.value, inputPart);
  };
};
var makeDataFun = (dataFun, valueAttr, labelAttr, descrAttr, descrSearch) => {
  let resultDataFun = null;
  if (labelAttr || descrAttr) {
    resultDataFun = function(rec, _input) {
      return {
        label: (rec[labelAttr || valueAttr] || "").replace("<p>", "<p >") + (descrAttr ? "<p>" + (rec[descrAttr] || "") : ""),
        value: (rec[valueAttr] || "") + (descrSearch ? "|" + (rec[descrAttr] || "").replace("|", " ") : "")
      };
    };
  } else if (valueAttr) {
    resultDataFun = function(rec, _input) {
      return rec[valueAttr] || "";
    };
  } else {
    return dataFun;
  }
  if (!dataFun)
    return resultDataFun;
  return function(rec, input) {
    return dataFun.call(this, resultDataFun(rec, input), input);
  };
};
var makeConvertInputFun = (convertInputFun, multipleChar) => {
  if (!multipleChar)
    return convertInputFun;
  const rem = new RegExp("[" + multipleChar + "]\\s*$"), rel = new RegExp("[^" + multipleChar + "]*$");
  return function(inp) {
    var convInp = inp.replace(rem, "").match(rel)[0].trim().toLowerCase();
    return convertInputFun ? convertInputFun.call(this, convInp) : convInp;
  };
};
var attachAwesomplete = (node, customCtx, defaultSettings) => {
  defaultSettings = defaultSettings || {};
  customCtx = customCtx || {};
  const b = node.getAttribute.bind(node), a = function(attr) {
    return b(attr) || defaultSettings[attr];
  }, ajax = a("ajax"), assign = a("assign"), autoFirst = a("autoFirst"), combobox = a("combobox"), container = a("container"), convertInput = a("convertInput"), convertResponse = a("convertResponse"), data = a("data"), debounce = a("debounce"), descr = a("descr"), descrSearch = a("descrSearch"), item = a("item"), filter = a("filter"), forField = a("forField"), label = a("label"), limit = a("limit"), list = a("list"), loadall = a("loadall"), listLabel = a("listLabel"), maxItems = a("maxItems"), minChars = a("minChars"), multiple = a("multiple"), prepop = a("prepop"), replace = a("replace"), sort = a("sort"), statusNoResults = a("statusNoResults"), statusTypeXChar = a("statusTypeXChar"), statusXResults = a("statusXResults"), value = a("value"), url = a("url"), urlEnd = a("urlEnd"), convertInputFun = getCustomFunction(customCtx, convertInput, "convertInput"), dataFun = getCustomFunction(customCtx, data, "data"), filterFun = getCustomFunction(customCtx, filter, "filter"), itemFun = getCustomFunction(customCtx, item, "item"), replaceFun = getCustomFunction(customCtx, replace, "replace"), filterAtStart = filterFun === Awesomplete.FILTER_STARTSWITH || filterFun === UTIL.filterStartsWith, isDescrSearch = descrSearch === "true" || descrSearch === true;
  if (forField === void 0)
    throw new Error("Missing forField attribute.");
  let opts = {}, awesompleteOpts = {}, multipleChar = null, separator = null, re = null;
  if (url)
    opts["url"] = url;
  if (urlEnd)
    opts["urlEnd"] = "function" === typeof customCtx[urlEnd] ? customCtx[urlEnd] : urlEnd;
  if (loadall)
    opts["loadall"] = loadall === "true" || loadall === true;
  if (prepop)
    opts["prepop"] = prepop === "true" || prepop === true;
  if (debounce)
    opts["debounce"] = Number(debounce);
  if (limit)
    opts["limit"] = Number(limit);
  if (!value && descr)
    throw new Error("'descr' without 'value' parameter.");
  if (!value && label)
    throw new Error("'label' without 'value' parameter.");
  if (isDescrSearch && !descr)
    throw new Error("Cannot search description texts without knowing the description field. Please supply descr parameter.");
  if (convertResponse)
    opts["convertResponse"] = getCustomFunction(customCtx, convertResponse, "convertResponse");
  if (ajax)
    opts["ajax"] = getCustomFunction(customCtx, ajax, "ajax");
  if (multiple && multiple !== "false") {
    multipleChar = multiple === "true" || multiple === true ? " " : multiple;
    separator = combobox && combobox !== "false" ? "" : "([" + multipleChar + "]\\s*)?", re = new RegExp("[^" + multipleChar + "]*" + separator + "$");
  }
  const madeConvertInputFun = makeConvertInputFun(convertInputFun, multipleChar), madeFilterFun = makeFilterFun(filterFun, filterAtStart, re, label || descr, isDescrSearch), madeItemFun = makeItemFun(itemFun, filterAtStart, re, isDescrSearch);
  if (madeConvertInputFun)
    opts["convertInput"] = madeConvertInputFun;
  if (madeFilterFun)
    awesompleteOpts["filter"] = madeFilterFun;
  if (madeItemFun)
    awesompleteOpts["item"] = madeItemFun;
  if (minChars)
    awesompleteOpts["minChars"] = Number(minChars);
  if (maxItems)
    awesompleteOpts["maxItems"] = Number(maxItems);
  if (autoFirst)
    awesompleteOpts["autoFirst"] = autoFirst === "true" || autoFirst === true;
  if (container)
    awesompleteOpts["container"] = getCustomFunction(customCtx, container, "container");
  if (replace || multipleChar || isDescrSearch) {
    awesompleteOpts["replace"] = makeReplaceFun(replaceFun, multipleChar, isDescrSearch);
  }
  if (value || data) {
    awesompleteOpts["data"] = makeDataFun(dataFun, value, label, descr, isDescrSearch);
  }
  if (list) {
    awesompleteOpts["list"] = ("function" === typeof customCtx[list] ? customCtx[list]() : customCtx[list]) || list;
  }
  if (listLabel)
    awesompleteOpts["listLabel"] = listLabel;
  if (statusNoResults)
    awesompleteOpts["statusNoResults"] = statusNoResults;
  if (statusXResults)
    awesompleteOpts["statusXResults"] = statusXResults;
  if (statusTypeXChar)
    awesompleteOpts["statusTypeXChar"] = statusTypeXChar;
  if (sort === "false" || sort === false) {
    awesompleteOpts["sort"] = false;
  } else if (sort) {
    awesompleteOpts["sort"] = customCtx[sort] || sort;
  }
  const aweInstance = UTIL.start(
    "#" + forField,
    opts,
    awesompleteOpts
  );
  if (assign && assign !== "false") {
    customCtx[assign === "true" || assign === true ? "awe_" + forField : assign] = aweInstance;
  }
  if (combobox && combobox !== "false") {
    UTIL.startClick(
      "#" + (combobox === "true" || combobox === true ? "awe_btn_" + forField : combobox),
      aweInstance
    );
  }
  return aweInstance;
};
var attach_awesomplete_default = attachAwesomplete;

// js/copy-value-to-id.js
var copyValueToId = (node) => {
  const a = node.getAttribute.bind(node), dataField = a("dataField"), field = a("field"), targetField = a("targetField"), target = a("target");
  if (field == null)
    throw new Error("Missing field attribute.");
  if (target == null && targetField == null)
    throw new Error("Missing target or targetField attribute.");
  AwesompleteUtil.startCopy("#" + field, dataField, targetField ? "#" + targetField : target);
};
var copy_value_to_id_default = copyValueToId;
var export_Awesomplete = import_awesomplete.default;
var export_AwesompleteUtil = import_awesomplete_util.default;
export {
  export_Awesomplete as Awesomplete,
  export_AwesompleteUtil as AwesompleteUtil,
  attach_awesomplete_default as attachAwesomplete,
  copy_value_to_id_default as copyValueToId
};
//# sourceMappingURL=awesomplete_bundle.mjs.map
