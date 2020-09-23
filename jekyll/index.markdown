---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults
layout: home
---

Introductory text here.

The following are the ModelSet(s) published during this build. Each Model set page shows the full content of a ModelSet
{% assign model_sets = site.data._ms | sort %}
{% include debug.html name="model sets"  object=model_sets on=false %}
<ul>
{% for ms in model_sets %}
{% assign model_set = ms[1] %}
{% include debug.html name="model set"  object=model_set on=false %}
<a href="{{model_set._urls.model_set_full | relative_url }}">{{model_set.name}}</a>

{% endfor %}
</ul>


