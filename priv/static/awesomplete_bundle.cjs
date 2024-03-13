var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
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
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// vendor/awesomplete-v2020.min.js
var require_awesomplete_v2020_min = __commonJS({
  "vendor/awesomplete-v2020.min.js"(exports, module2) {
    !function() {
      function t(t2) {
        var e2 = Array.isArray(t2) ? { label: t2[0], value: t2[1] } : "object" == typeof t2 && "label" in t2 && "value" in t2 ? t2 : { label: t2, value: t2 };
        this.label = e2.label || e2.value, this.value = e2.value;
      }
      function e(t2, e2, i2) {
        for (var n2 in e2) {
          var s2 = e2[n2], r2 = t2.input.getAttribute("data-" + n2.toLowerCase());
          "number" == typeof s2 ? t2[n2] = parseInt(r2) : false === s2 ? t2[n2] = null !== r2 : s2 instanceof Function ? t2[n2] = null : t2[n2] = r2, t2[n2] || 0 === t2[n2] || (t2[n2] = n2 in i2 ? i2[n2] : s2);
        }
      }
      function i(t2, e2) {
        return "string" == typeof t2 ? (e2 || document).querySelector(t2) : t2 || null;
      }
      function n(t2, e2) {
        return o.call((e2 || document).querySelectorAll(t2));
      }
      function s() {
        n("input.awesomplete").forEach(function(t2) {
          new r(t2);
        });
      }
      var r = function(t2, n2) {
        var s2 = this;
        r.count = (r.count || 0) + 1, this.count = r.count, this.isOpened = false, this.input = i(t2), this.input.setAttribute("autocomplete", "off"), this.input.setAttribute("aria-expanded", "false"), this.input.setAttribute("aria-owns", "awesomplete_list_" + this.count), this.input.setAttribute("role", "combobox"), this.options = n2 = n2 || {}, e(this, { minChars: 2, maxItems: 10, autoFirst: false, data: r.DATA, filter: r.FILTER_CONTAINS, sort: false !== n2.sort && r.SORT_BYLENGTH, container: r.CONTAINER, item: r.ITEM, replace: r.REPLACE, tabSelect: false, listLabel: "Results List" }, n2), this.index = -1, this.container = this.container(t2), this.ul = i.create("ul", { hidden: "hidden", role: "listbox", id: "awesomplete_list_" + this.count, inside: this.container, "aria-label": this.listLabel }), this.status = i.create("span", { className: "visually-hidden", role: "status", "aria-live": "assertive", "aria-atomic": true, inside: this.container, textContent: 0 != this.minChars ? "Type " + this.minChars + " or more characters for results." : "Begin typing for results." }), this._events = { input: { input: this.evaluate.bind(this), blur: this.close.bind(this, { reason: "blur" }), keydown: function(t3) {
          var e2 = t3.keyCode;
          s2.opened && (13 === e2 && s2.selected ? (t3.preventDefault(), s2.select(void 0, void 0, t3)) : 9 === e2 && s2.selected && s2.tabSelect ? s2.select(void 0, void 0, t3) : 27 === e2 ? s2.close({ reason: "esc" }) : 38 !== e2 && 40 !== e2 || (t3.preventDefault(), s2[38 === e2 ? "previous" : "next"]()));
        } }, form: { submit: this.close.bind(this, { reason: "submit" }) }, ul: { mousedown: function(t3) {
          t3.preventDefault();
        }, click: function(t3) {
          var e2 = t3.target;
          if (e2 !== this) {
            for (; e2 && !/li/i.test(e2.nodeName); )
              e2 = e2.parentNode;
            e2 && 0 === t3.button && (t3.preventDefault(), s2.select(e2, t3.target, t3));
          }
        } } }, i.bind(this.input, this._events.input), i.bind(this.input.form, this._events.form), i.bind(this.ul, this._events.ul), this.input.hasAttribute("list") ? (this.list = "#" + this.input.getAttribute("list"), this.input.removeAttribute("list")) : this.list = this.input.getAttribute("data-list") || n2.list || [], r.all.push(this);
      };
      r.prototype = { set list(t2) {
        if (Array.isArray(t2))
          this._list = t2;
        else if ("string" == typeof t2 && t2.indexOf(",") > -1)
          this._list = t2.split(/\s*,\s*/);
        else if ((t2 = i(t2)) && t2.children) {
          var e2 = [];
          o.apply(t2.children).forEach(function(t3) {
            if (!t3.disabled) {
              var i2 = t3.textContent.trim(), n2 = t3.value || i2, s2 = t3.label || i2;
              "" !== n2 && e2.push({ label: s2, value: n2 });
            }
          }), this._list = e2;
        }
        document.activeElement === this.input && this.evaluate();
      }, get selected() {
        return this.index > -1;
      }, get opened() {
        return this.isOpened;
      }, close: function(t2) {
        this.opened && (this.input.setAttribute("aria-expanded", "false"), this.ul.setAttribute("hidden", ""), this.isOpened = false, this.index = -1, this.status.setAttribute("hidden", ""), i.fire(this.input, "awesomplete-close", t2 || {}));
      }, open: function() {
        this.input.setAttribute("aria-expanded", "true"), this.ul.removeAttribute("hidden"), this.isOpened = true, this.status.removeAttribute("hidden"), this.autoFirst && -1 === this.index && this.goto(0), i.fire(this.input, "awesomplete-open");
      }, destroy: function() {
        if (i.unbind(this.input, this._events.input), i.unbind(this.input.form, this._events.form), !this.options.container) {
          var t2 = this.container.parentNode;
          t2.insertBefore(this.input, this.container), t2.removeChild(this.container);
        }
        this.input.removeAttribute("autocomplete"), this.input.removeAttribute("aria-autocomplete");
        var e2 = r.all.indexOf(this);
        -1 !== e2 && r.all.splice(e2, 1);
      }, next: function() {
        var t2 = this.ul.children.length;
        this.goto(this.index < t2 - 1 ? this.index + 1 : t2 ? 0 : -1);
      }, previous: function() {
        var t2 = this.ul.children.length, e2 = this.index - 1;
        this.goto(this.selected && -1 !== e2 ? e2 : t2 - 1);
      }, goto: function(t2) {
        var e2 = this.ul.children;
        this.selected && e2[this.index].setAttribute("aria-selected", "false"), this.index = t2, t2 > -1 && e2.length > 0 && (e2[t2].setAttribute("aria-selected", "true"), this.status.textContent = e2[t2].textContent + ", list item " + (t2 + 1) + " of " + e2.length, this.input.setAttribute("aria-activedescendant", this.ul.id + "_item_" + this.index), this.ul.scrollTop = e2[t2].offsetTop - this.ul.clientHeight + e2[t2].clientHeight, i.fire(this.input, "awesomplete-highlight", { text: this.suggestions[this.index] }));
      }, select: function(t2, e2, n2) {
        if (t2 ? this.index = i.siblingIndex(t2) : t2 = this.ul.children[this.index], t2) {
          var s2 = this.suggestions[this.index];
          i.fire(this.input, "awesomplete-select", { text: s2, origin: e2 || t2, originalEvent: n2 }) && (this.replace(s2), this.close({ reason: "select" }), i.fire(this.input, "awesomplete-selectcomplete", { text: s2, originalEvent: n2 }));
        }
      }, evaluate: function() {
        var e2 = this, i2 = this.input.value;
        i2.length >= this.minChars && this._list && this._list.length > 0 ? (this.index = -1, this.ul.innerHTML = "", this.suggestions = this._list.map(function(n2) {
          return new t(e2.data(n2, i2));
        }).filter(function(t2) {
          return e2.filter(t2, i2);
        }), false !== this.sort && (this.suggestions = this.suggestions.sort(this.sort)), this.suggestions = this.suggestions.slice(0, this.maxItems), this.suggestions.forEach(function(t2, n2) {
          e2.ul.appendChild(e2.item(t2, i2, n2));
        }), 0 === this.ul.children.length ? (this.status.textContent = "No results found", this.close({ reason: "nomatches" })) : (this.open(), this.status.textContent = this.ul.children.length + " results found")) : (this.close({ reason: "nomatches" }), this.status.textContent = "No results found");
      } }, r.all = [], r.FILTER_CONTAINS = function(t2, e2) {
        return RegExp(i.regExpEscape(e2.trim()), "i").test(t2);
      }, r.FILTER_STARTSWITH = function(t2, e2) {
        return RegExp("^" + i.regExpEscape(e2.trim()), "i").test(t2);
      }, r.SORT_BYLENGTH = function(t2, e2) {
        return t2.length !== e2.length ? t2.length - e2.length : t2 < e2 ? -1 : 1;
      }, r.CONTAINER = function(t2) {
        return i.create("div", { className: "awesomplete", around: t2 });
      }, r.ITEM = function(t2, e2, n2) {
        return i.create("li", { innerHTML: "" === e2.trim() ? t2 : t2.replace(RegExp(i.regExpEscape(e2.trim()), "gi"), "<mark>$&</mark>"), role: "option", "aria-selected": "false", id: "awesomplete_list_" + this.count + "_item_" + n2 });
      }, r.REPLACE = function(t2) {
        this.input.value = t2.value;
      }, r.DATA = function(t2) {
        return t2;
      }, Object.defineProperty(t.prototype = Object.create(String.prototype), "length", { get: function() {
        return this.label.length;
      } }), t.prototype.toString = t.prototype.valueOf = function() {
        return "" + this.label;
      };
      var o = Array.prototype.slice;
      i.create = function(t2, e2) {
        var n2 = document.createElement(t2);
        for (var s2 in e2) {
          var r2 = e2[s2];
          if ("inside" === s2)
            i(r2).appendChild(n2);
          else if ("around" === s2) {
            var o2 = i(r2);
            o2.parentNode.insertBefore(n2, o2), n2.appendChild(o2), null != o2.getAttribute("autofocus") && o2.focus();
          } else
            s2 in n2 ? n2[s2] = r2 : n2.setAttribute(s2, r2);
        }
        return n2;
      }, i.bind = function(t2, e2) {
        if (t2)
          for (var i2 in e2) {
            var n2 = e2[i2];
            i2.split(/\s+/).forEach(function(e3) {
              t2.addEventListener(e3, n2);
            });
          }
      }, i.unbind = function(t2, e2) {
        if (t2)
          for (var i2 in e2) {
            var n2 = e2[i2];
            i2.split(/\s+/).forEach(function(e3) {
              t2.removeEventListener(e3, n2);
            });
          }
      }, i.fire = function(t2, e2, i2) {
        var n2 = document.createEvent("HTMLEvents");
        n2.initEvent(e2, true, true);
        for (var s2 in i2)
          n2[s2] = i2[s2];
        return t2.dispatchEvent(n2);
      }, i.regExpEscape = function(t2) {
        return t2.replace(/[-\\^$*+?.()|[\]{}]/g, "\\$&");
      }, i.siblingIndex = function(t2) {
        for (var e2 = 0; t2 = t2.previousElementSibling; e2++)
          ;
        return e2;
      }, "undefined" != typeof self && (self.Awesomplete = r), "undefined" != typeof Document && ("loading" !== document.readyState ? s() : document.addEventListener("DOMContentLoaded", s)), r.$ = i, r.$$ = n, "object" == typeof module2 && module2.exports && (module2.exports = r);
    }();
  }
});

// vendor/awesomplete-util.min.js
var require_awesomplete_util_min = __commonJS({
  "vendor/awesomplete-util.min.js"(exports, module2) {
    var AwesompleteUtil3 = function() {
      var t = "awesomplete-", n = t + "loadcomplete", e = t + "close", r = t + "match", u = t + "prepop", i = t + "select", o = "awe-found", a = "awe-not-found", c = Awesomplete.$;
      function f(t2, n2, e2) {
        return c.fire(t2, n2, { detail: e2 });
      }
      function l(t2, n2) {
        var e2, i2, c2, l2, s2, d2, p2 = t2.input, m2 = p2.classList, v2 = t2.utilprops, h2 = v2.selected, y2 = v2.convertInput.call(t2, p2.value), b2 = t2.opened, w2 = [], A2 = t2._list;
        if (v2.prepop = false, A2) {
          for (l2 = 0; l2 < A2.length; l2++)
            if (c2 = A2[l2], s2 = t2.data(c2, y2), d2 = void 0, e2 = { label: (d2 = Array.isArray(s2) ? { label: s2[0], value: s2[1] } : "object" == typeof s2 && "label" in s2 && "value" in s2 ? s2 : { label: s2, value: s2 }).label || d2.value, value: d2.value }, 0 === t2.maxItems && (e2.toString = function() {
              return "" + this.label;
            }, t2.filter(e2, y2) && (b2 = true)), i2 = { input: { value: "" } }, t2.replace.call(i2, e2), v2.convertInput.call(t2, i2.input.value) === y2) {
              if (h2 && h2.value === e2.value && h2.label === e2.label) {
                w2 = [c2];
                break;
              }
              w2.push(c2);
            }
          v2.prevSelected !== w2 && (w2.length > 0 ? n2 ? f(p2, u, w2) : v2.changed && (v2.prevSelected = w2, m2.remove(a), m2.add(o), f(p2, r, w2)) : n2 ? f(p2, u, []) : v2.changed && (v2.prevSelected = [], m2.remove(o), b2 && p2 === document.activeElement ? m2.remove(a) : "" !== y2 && (m2.add(a), f(p2, r, []))));
        }
      }
      function s(t2) {
        var r2 = this;
        t2.type !== e && t2.type !== n && "blur" !== t2.type || t2.target !== r2.input || l(r2, r2.utilprops.prepop && t2.type === n);
      }
      function d(t2) {
        t2.target === this.input && 9 === t2.keyCode && this.select();
      }
      function p(t2) {
        var n2 = this;
        clearTimeout(n2.utilprops.timeoutID), n2.utilprops.changed = true, n2.utilprops.selected = t2.text;
      }
      function m(t2, n2, e2) {
        var r2 = t2.utilprops;
        return !r2.t || !r2.loadall && 0 === n2.lastIndexOf(e2, 0) && (0 !== n2.lastIndexOf(r2.t, 0) || "number" == typeof r2.limit && t2._list.length >= r2.limit);
      }
      function v(t2, e2, r2) {
        t2.list = e2, t2.utilprops.t = r2, f(t2.input, n, r2);
      }
      function h() {
        var t2, n2, e2 = this, r2 = e2.u, u2 = e2.i, i2 = e2.queryVal, o2 = r2.utilprops.val;
        if (200 === u2.status) {
          if (t2 = JSON.parse(u2.responseText), r2.utilprops.convertResponse && (t2 = r2.utilprops.convertResponse(t2)), !Array.isArray(t2)) {
            if (0 === r2.utilprops.limit || 1 === r2.utilprops.limit)
              t2 = function(t3) {
                return 0 === Object.keys(t3).length && t3.constructor === Object;
              }(t2) ? [] : [t2];
            else
              for (n2 in t2)
                if (Array.isArray(t2[n2])) {
                  t2 = t2[n2];
                  break;
                }
          }
          Array.isArray(t2) && m(r2, o2, i2) && v(r2, t2, i2 || r2.utilprops.loadall);
        }
      }
      function y(t2, n2) {
        var e2 = new XMLHttpRequest();
        t2.utilprops.ajax.call(t2, t2.utilprops.url, t2.utilprops.urlEnd, t2.utilprops.loadall ? "" : n2, h.bind({ u: t2, i: e2, queryVal: n2 }), e2);
      }
      function b(t2, n2, e2) {
        t2.utilprops.url && m(t2, n2, n2) ? "number" == typeof e2 && e2 > 0 ? t2.utilprops.timeoutID = setTimeout(y.bind(null, t2, n2), e2) : y(t2, n2) : l(t2, t2.utilprops.prepop);
      }
      function w(t2, n2, e2) {
        return t2.utilprops.prepop = e2 || false, t2.utilprops.val !== n2 && (clearTimeout(t2.utilprops.timeoutID), t2.utilprops.selected = null, t2.utilprops.changed = true, t2.utilprops.val = n2, ("" === n2 || n2.length < t2.minChars) && function(t3) {
          var n3 = t3.input, e3 = n3.classList;
          e3.remove(a), e3.remove(o), f(n3, r, []);
        }(t2), n2.length >= t2.minChars && b(t2, n2, t2.utilprops.debounce)), t2;
      }
      function A(t2) {
        var n2, e2 = this;
        t2.target === e2.input && (n2 = e2.utilprops.convertInput.call(e2, e2.input.value), w(e2, n2));
      }
      function k(t2) {
        return c.create("li", { innerHTML: t2, role: "option", "aria-selected": "false" });
      }
      function C(t2) {
        var n2, e2, r2 = this, u2 = r2.o, i2 = r2.l, o2 = r2.p;
        t2.target === c(u2) && ("function" == typeof o2 ? o2(t2, i2) : (n2 = c(o2)) && n2 !== document.activeElement && (e2 = Array.isArray(t2.detail) && 1 === t2.detail.length ? t2.detail[0] : null, e2 = (i2 && e2 ? e2[i2] : e2) || "", void 0 !== n2.value ? (n2.value = e2, n2.classList && n2.classList.remove && n2.classList.remove(a)) : void 0 !== n2.src ? n2.src = e2 : n2.innerHTML = e2));
      }
      function F(t2) {
        var n2, e2;
        t2.target === c(this.btnId) && (t2.preventDefault(), 0 === (n2 = this.u).ul.childNodes.length || n2.ul.hasAttribute("hidden") ? (e2 = n2.minChars, n2.minChars = 0, n2.evaluate(), n2.minChars = e2) : n2.close());
      }
      function j(t2, n2, e2) {
        var r2 = c.regExpEscape(function(t3) {
          return t3.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
        }(n2).trim()), u2 = "" === r2 ? null : e2 ? RegExp("^" + r2, "i") : RegExp("(?!<[^>]+?>)" + r2 + "(?![^<]*?>)", "gi");
        return t2.replace(u2, "<mark>$&</mark>");
      }
      function O(t2, n2, e2, r2, u2) {
        var i2, o2 = u2.root, a2 = u2.value, c2 = u2.label || u2.value, f2 = true, l2 = [];
        if (0 === r2 && o2 && e2 && 0 !== (e2 + ".").lastIndexOf(o2 + ".", 0) && 0 !== (o2 + ".").lastIndexOf(e2 + ".", 0))
          return t2;
        if (Object(n2) !== n2)
          e2 ? t2[e2] = n2 : t2 = n2;
        else if (Array.isArray(n2)) {
          for (i2 = 0; i2 < n2.length; i2++)
            l2.push(O({}, n2[i2], "", r2 + 1, u2));
          e2 ? t2[e2] = l2 : t2 = l2;
        } else {
          for (i2 in n2)
            f2 = false, O(t2, n2[i2], e2 ? e2 + "." + i2 : i2, r2, u2);
          f2 && e2 && (t2[e2] = {});
        }
        return r2 < 2 && e2 && (a2 && 0 === (e2 + ".").lastIndexOf(a2 + ".", 0) && (t2.value = t2[e2]), c2 && 0 === (e2 + ".").lastIndexOf(c2 + ".", 0) && (t2.label = t2[e2])), 0 === r2 && (a2 && !("value" in t2) && (t2.value = null), c2 && !("label" in t2) && (t2.label = null)), t2;
      }
      function g() {
        var t2 = this, r2 = t2.u.input, u2 = t2.m, o2 = t2.v, a2 = t2.h, c2 = t2.A;
        r2.removeEventListener(i, c2), r2.removeEventListener(n, u2), r2.removeEventListener(e, u2), r2.removeEventListener("blur", u2), r2.removeEventListener("input", o2), r2.removeEventListener("keydown", a2);
      }
      return { ajax: function(t2, n2, e2, r2, u2) {
        var i2 = encodeURIComponent(e2);
        return (u2 = u2 || new XMLHttpRequest()).open("GET", t2 + ("function" == typeof n2 ? n2(i2) : i2 + (n2 || ""))), u2.onload = r2, u2.send(), u2;
      }, convertInput: function(t2) {
        return "string" == typeof t2 ? t2.trim().toLowerCase() : "";
      }, item: k, load: v, mark: j, itemContains: function(t2, n2, e2) {
        var r2;
        return "" !== n2.trim() && ((r2 = ("" + t2).split(/<p>/))[0] = j(r2[0], n2), t2 = r2.join("<p>")), k(t2);
      }, itemMarkAll: function(t2, n2, e2) {
        return k("" === n2.trim() ? "" + t2 : j("" + t2, n2));
      }, itemStartsWith: function(t2, n2, e2) {
        return k("" === n2.trim() ? "" + t2 : j("" + t2, n2, true));
      }, itemWords: function(t2, n2, e2) {
        var r2, u2, i2 = n2.split(/\s+/);
        if ("" !== n2.trim()) {
          for (r2 = ("" + t2).split("<"), u2 = 0; u2 < i2.length; u2++)
            r2[0] = j(r2[0], i2[u2]);
          t2 = r2.join("<");
        }
        return k(t2);
      }, create: function(t2, n2, e2) {
        e2.item = e2.item || this.itemContains;
        var r2 = new Awesomplete(t2, e2);
        return r2.utilprops = n2 || {}, r2.utilprops.url || void 0 !== r2.utilprops.loadall || (r2.utilprops.loadall = true), r2.utilprops.ajax = r2.utilprops.ajax || this.ajax, r2.utilprops.convertInput = r2.utilprops.convertInput || this.convertInput, r2;
      }, attach: function(t2) {
        var r2 = t2.input, u2 = s.bind(t2), o2 = d.bind(t2), a2 = A.bind(t2), f2 = p.bind(t2), l2 = g.bind({ u: t2, m: u2, v: a2, h: o2, A: f2 }), m2 = { keydown: o2, input: a2 };
        return m2.blur = m2[e] = m2[n] = u2, m2[i] = f2, c.bind(r2, m2), t2.utilprops.detach = l2, t2.utilprops.prepop && (t2.utilprops.loadall || "" !== r2.value) && (t2.utilprops.val = t2.utilprops.convertInput.call(t2, r2.value), b(t2, t2.utilprops.val)), t2;
      }, update: function(t2, n2, e2) {
        return t2.input.value = n2, w(t2, n2, e2);
      }, start: function(t2, n2, e2) {
        return this.attach(this.create(t2, n2, e2));
      }, detach: function(t2) {
        return clearTimeout(t2.utilprops.timeoutID), t2.utilprops.detach && (t2.utilprops.detach(), delete t2.utilprops.detach), t2;
      }, createCopyFun: function(t2, n2, e2) {
        return C.bind({ o: t2, l: n2, p: c(e2) || e2 });
      }, attachCopyFun: function(t2, n2, e2) {
        return n2 = "boolean" != typeof n2 || n2, (e2 = e2 || document.body).addEventListener(r, t2), n2 && e2.addEventListener(u, t2), t2;
      }, startCopy: function(t2, n2, e2, r2) {
        var u2 = c(t2);
        return this.attachCopyFun(this.createCopyFun(u2 || t2, n2, e2), r2, u2);
      }, detachCopyFun: function(t2, n2) {
        return (n2 = n2 || document.body).removeEventListener(u, t2), n2.removeEventListener(r, t2), t2;
      }, createClickFun: function(t2, n2) {
        return F.bind({ btnId: t2, u: n2 });
      }, attachClickFun: function(t2, n2) {
        return (n2 = n2 || document.body).addEventListener("click", t2), t2;
      }, startClick: function(t2, n2) {
        var e2 = c(t2);
        return this.attachClickFun(this.createClickFun(e2 || t2, n2), e2);
      }, detachClickFun: function(t2, n2) {
        return (n2 = n2 || document.body).removeEventListener("click", t2), t2;
      }, filterContains: function(t2, n2) {
        return Awesomplete.FILTER_CONTAINS(t2.value, n2);
      }, filterStartsWith: function(t2, n2) {
        return Awesomplete.FILTER_STARTSWITH(t2.value, n2);
      }, filterOff: function(t2, n2) {
        return true;
      }, filterWords: function(t2, n2) {
        var e2, r2 = n2.split(/\s+/), u2 = true;
        for (t2 = " " + t2, e2 = 0; u2 && e2 < r2.length; e2++)
          u2 = Awesomplete.FILTER_CONTAINS(t2, " " + r2[e2]);
        return u2;
      }, jsonFlatten: function(t2) {
        return O({}, t2, "", 0, this);
      } };
    }();
    "object" == typeof module2 && module2.exports && (module2.exports = AwesompleteUtil3), "undefined" != typeof self && (self.AwesompleteUtil = AwesompleteUtil3);
  }
});

// js/index.js
var js_exports = {};
__export(js_exports, {
  Awesomplete: () => import_awesomplete_v2020_min.default,
  AwesompleteUtil: () => import_awesomplete_util_min.default,
  attachAwesomplete: () => attach_awesomplete_default
});
module.exports = __toCommonJS(js_exports);
var import_awesomplete_v2020_min = __toESM(require_awesomplete_v2020_min());
var import_awesomplete_util_min = __toESM(require_awesomplete_util_min());

// js/attach-awesomplete.js
var simpleElEval = (searchIn, path) => {
  let result = searchIn, elements = path.split(".");
  for (pathElem of elements) {
    result = result[pathElem];
    if (result === void 0) {
      throw new Error("Could not find " + pathElem + " of " + path);
    }
  }
  return result;
};
var checkIsFunction = (shouldBeFunction, name) => {
  if ("function" !== typeof shouldBeFunction)
    throw new Error(name + " is not a function");
  return shouldBeFunction;
};
var attachAwesomplete = (node, bindings) => {
  const a = node.getAttribute.bind(node), fieldID = a("forField"), url = a("url"), loadall = a("loadall"), prepop = a("prepop"), minChars = a("minChars"), maxItems = a("maxItems"), value = a("value"), combobox = a("combobox"), comboSelectID = "#" + (combobox !== "true" ? combobox : "awe_btn_" + fieldID), descr = a("descr"), descrSearch = a("descrSearch"), label = a("label"), filter = a("filter"), debounce = a("debounce"), list = a("list");
  let opts = {}, awesompleteOpts = {}, listConv;
  if (fieldID == null)
    throw new Error("Missing forField attribute.");
  if (url)
    opts["url"] = url;
  if (loadall)
    opts["loadall"] = loadall === "true";
  if (prepop)
    opts["prepop"] = prepop === "true";
  if (debounce)
    opts["debounce"] = Number(debounce);
  switch (filter) {
    case null:
    case "":
      break;
    case "Awesomplete.FILTER_STARTSWITH":
      awesompleteOpts["filter"] = Awesomplete.FILTER_STARTSWITH;
      break;
    case "Awesomplete.FILTER_CONTAINS":
      awesompleteOpts["filter"] = Awesomplete.FILTER_CONTAINS;
      break;
    case "AwesompleteUtil.filterStartsWith":
      awesompleteOpts["filter"] = AwesompleteUtil.filterStartsWith;
      break;
    case "AwesompleteUtil.filterContains":
      awesompleteOpts["filter"] = AwesompleteUtil.filterContains;
      break;
    case "AwesompleteUtil.filterWords":
      awesompleteOpts["filter"] = AwesompleteUtil.filterWords;
      break;
    default:
      awesompleteOpts["filter"] = checkIsFunction(simpleElEval(bindings, filter));
  }
  if (minChars)
    awesompleteOpts["minChars"] = Number(minChars);
  if (maxItems)
    awesompleteOpts["maxItems"] = Number(maxItems);
  if (value && descr && descrSearch == "true") {
    awesompleteOpts["data"] = function(rec, input) {
      return {
        label: rec[label || value] + "<p>" + (rec[descr] || ""),
        value: rec[value] + "|" + (rec[descr] || "").replace("|", " ")
      };
    };
    awesompleteOpts["replace"] = function(data) {
      this.input.value = data.value.substring(0, data.value.lastIndexOf("|"));
    };
  } else if (value && descr) {
    awesompleteOpts["data"] = function(rec, input) {
      return {
        label: rec[label || value] + "<p>" + (rec[descr] || ""),
        value: rec[value]
      };
    };
  } else if (value && label) {
    awesompleteOpts["data"] = function(rec, input) {
      return {
        label: rec[label] || "",
        value: rec[value] || ""
      };
    };
  } else if (value) {
    awesompleteOpts["data"] = function(rec, input) {
      return rec[value] || "";
    };
  }
  if (list) {
    if (/^\s*\[/.test(list)) {
      listConv = list;
    } else {
      listConv = simpleElEval(bindings, list);
      if ("function" === typeof listConv) {
        listConv = listConv();
      }
    }
    if ("string" === typeof listConv && /^\s*\[/.test(listConv)) {
      try {
        listConv = JSON.parse(listConv);
      } catch (_e) {
        listConv = listConv.replace(/\r?\n|\r/g, "").replace(/([{,]\s*)['"]?([a-zA-Z0-9_]+)['"]?\s*:/g, '$1"$2": ').replace(/:\s*'([^,"}\'\]\[\{]*)'/g, ':"$1"');
        console.log(listConv);
        listConv = JSON.parse(listConv);
      }
    }
    awesompleteOpts["list"] = listConv;
  }
  let awe = AwesompleteUtil.start(
    "#" + fieldID,
    opts,
    awesompleteOpts
  );
  if (combobox && combobox !== "false")
    AwesompleteUtil.startClick(comboSelectID, awe);
};
var attach_awesomplete_default = attachAwesomplete;
//# sourceMappingURL=awesomplete_bundle.cjs.map
