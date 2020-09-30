---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults
layout: home
title: Home
nav_order: 1
---
{% assign model_sets = site.data._ms | sort %}

# Home page

Introductory text here.

The following are the ModelSet(s) published during this build. Each Model set page shows the full content of a ModelSet

## Simple model set pages

<ol>
    {% for ms in model_sets %}
    {% assign model_set = ms[1] %}
    <li><a href="{{model_set._urls.base_html | relative_url }}">{{model_set.name}}</a>
        {% include debug.md name="model in index.html"  object=model_set on="false" %}
    </li>
    {% endfor %}
</ol>

## Full model set pages
<ol>
{% for ms in model_sets %}
{% assign model_set = ms[1] %}
<li><a href="{{model_set._urls.base_full_html | relative_url }}">{{model_set.name}}</a>
{% include debug.md name="model in index.html"  object=model_set on="false" %}
</li>
{% endfor %}
</ol>
