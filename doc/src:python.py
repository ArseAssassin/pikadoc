import sys, inspect, json, pkgutil, importlib
from importlib.metadata import metadata, PackageNotFoundError

from pkgutil import iter_modules
from inspect import ismodule, isclass, ismethod, isfunction, isbuiltin

parsed_items = []

def gen_module(module_name):
  module = importlib.import_module(module_name)

  def getdoc(item):
    doc = inspect.getdoc(item)
    if doc:
      return inspect.cleandoc(doc)
    else:
      return doc

  def gen_symbol(name, item, parent=None):
    l = []
    kind = (
      ismodule(item) and 'module' or
      isclass(item) and 'class' or
      ismethod(item) and (not isclass(parent) and 'method' or 'function') or
      isfunction(item) and (not isclass(parent) and 'function' or 'method') or
      callable(item) and 'callable' or
      isclass(parent) and 'property' or
      'const'
    )

    defined_in = None

    if (ismodule(item) or isclass(item) or ismethod(item) or isfunction(item)) and not isbuiltin(item):
      try:
        defined_in = {
          "file": inspect.getsourcefile(item)
        }
        defined_in['line'] = inspect.getsourcelines(item)[1]
      except OSError:
        pass
      except TypeError:
        pass

    l.append({
      "name": name,
      "kind": kind,
      "ns": (item is not module and module_name) or None,
      "description": kind != 'const' and getdoc(item) or None,
      "summary": (kind != 'const' and getdoc(item) or '').split('\n')[0].split('.')[0].replace("\n", ' ').replace('  ', ' '),
      "signatures": gen_signature(item),
      "defined_in": defined_in,
      "inherits_from":
        isclass(item) and [str(x) for x in list(inspect.getmro(item))[1:-1]]
        or None
    })

    if inspect.ismodule(item) or inspect.isclass(item):
      parsed_items.append(item)

      members = []
      if hasattr(item, '__all__'):
        for memberName in item.__all__:
          try:
            members.append((memberName, getattr(item, memberName)))
          except:
            pass
      else:
        members = inspect.getmembers(item)

      for (memberName, memberItem) in members:
        if (not inspect.isbuiltin(memberItem) and
          (not ismodule(memberItem) or memberItem.__name__.startswith(module_name)) and
          (not (isclass(memberItem) or ismodule(memberItem)) or memberItem not in parsed_items) and
          not memberName.startswith('_')):

          if inspect.isclass(item):
            memberName = name + '.' + memberName
          l += gen_symbol(memberName, memberItem, item)

    return l

  def param_or_none(value):
    return value != inspect.Parameter.empty and str(value) or None

  def gen_signature(item):
    try:
      if callable(item):
        spec = inspect.getfullargspec(item)
        kwonlydefaults = spec.kwonlydefaults or {}
        defaults = spec.defaults or []
        return [{
          "kind":
            x == spec.varargs and 'rest' or
            x == spec.varkw and 'rest-kw' or
            'positional',
          "name": x,
          "default":
            idx >= (len(spec.args) - len(defaults)) and
            str(defaults[idx - (len(spec.args) - len(defaults))]) or
            None,
          "rest": spec.varargs == x
        } for idx, x in enumerate(spec.args)] + (
          [{
            "name": x,
            "default": x in kwonlydefaults and str(kwonlydefaults[x]) or None,
            "rest": False,
            "kind": "kw-only"
          } for x in spec.kwonlyargs]
        ) + (
          [{ 'type': inspect.isclass(item) and item.__name__ or '?' }]
        )
    except TypeError:
      pass

  l = gen_symbol(module_name, module)

  return (l, module)

module_name = sys.argv[1]
l, module = gen_module(module_name)

if hasattr(module, '__path__'):
  for submodule in pkgutil.walk_packages(module.__path__):
    if not submodule.name.startswith('_'):
      # print(submodule.name)
      try:
        l += gen_module(module_name + '.' + submodule.name)[0]
      except:
        pass

about = {}

meta = {}
try:
  meta = metadata(module_name)
  about = {
    "name": meta['Name'],
    "version": meta['version'],
    "description": meta['Description'],
    "homepage": meta['Home-page'],
    "license": meta['License'],
  }
except PackageNotFoundError:
  pass
# print(l)
print(json.dumps({
  "packageMetadata": meta,
  "about": about,
  "doctable": l
}))