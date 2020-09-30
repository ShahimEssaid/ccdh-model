---
layout: page
title: Model set {{page.MS.name}}
nav_exclude: true
---

# Model set: {{ page.MS.name }}

The models in this model set are:
{% assign models = page.MS._models | sort %}
{%- for model_entry in models -%}
{%- assign model = model_entry[1] -%}
{%include li/m.md  m=model%}
{%- endfor -%}

{% include debug.md object=page.MS name="model set in MS/model_set.html" on="false" hr="true"  %}

